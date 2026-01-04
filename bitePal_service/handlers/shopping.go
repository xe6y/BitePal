package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"bitePal_service/utils"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ShoppingHandler 购物清单处理器
type ShoppingHandler struct{}

// NewShoppingHandler 创建购物清单处理器实例
// 返回: 购物清单处理器
func NewShoppingHandler() *ShoppingHandler {
	return &ShoppingHandler{}
}

// CreateShoppingListRequest 创建购物清单请求结构
type CreateShoppingListRequest struct {
	Name  string                `json:"name"`  // 清单名称
	Items []models.ShoppingItem `json:"items"` // 购物项列表
}

// AddShoppingItemRequest 添加购物项请求结构
type AddShoppingItemRequest struct {
	Name   string  `json:"name" binding:"required"` // 商品名称
	Amount string  `json:"amount"`                  // 数量
	Price  float64 `json:"price"`                   // 价格
}

// UpdateShoppingItemRequest 更新购物项请求结构
type UpdateShoppingItemRequest struct {
	Name    string   `json:"name"`    // 商品名称
	Amount  string   `json:"amount"`  // 数量
	Price   *float64 `json:"price"`   // 价格
	Checked *bool    `json:"checked"` // 是否已购买
}

// GetShoppingLists 获取购物清单列表
// @Summary 获取购物清单列表
// @Description 获取用户的购物清单列表
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param completed query bool false "是否只显示已完成"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/shopping-lists [get]
func (h *ShoppingHandler) GetShoppingLists(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

	// 构建查询
	query := config.DB.Model(&models.ShoppingList{}).Where("user_id = ?", userID)

	// 完成状态筛选
	if completed := c.Query("completed"); completed == "true" {
		query = query.Where("completed_at IS NOT NULL")
	} else if completed == "false" {
		query = query.Where("completed_at IS NULL")
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取列表
	var lists []models.ShoppingList
	query.Offset(pagination.Offset).Limit(pagination.PageSize).Order("created_at DESC").Find(&lists)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(lists, total, pagination.Page, pagination.PageSize)))
}

// GetCurrentShoppingList 获取当前购物清单
// @Summary 获取当前购物清单
// @Description 获取用户当前未完成的购物清单
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response{data=models.ShoppingList}
// @Router /api/shopping-lists/current [get]
func (h *ShoppingHandler) GetCurrentShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var list models.ShoppingList
	result := config.DB.Where("user_id = ? AND completed_at IS NULL", userID).
		Order("created_at DESC").
		First(&list)

	if result.Error != nil {
		// 如果没有当前清单，返回空清单
		list = models.ShoppingList{
			Name:       "购物清单",
			Items:      models.ShoppingItems{},
			TotalPrice: 0,
			UserID:     userID,
		}
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", list))
}

// CreateShoppingList 创建购物清单
// @Summary 创建购物清单
// @Description 创建新的购物清单
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateShoppingListRequest true "清单信息"
// @Success 200 {object} models.Response{data=models.ShoppingList}
// @Router /api/shopping-lists [post]
func (h *ShoppingHandler) CreateShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req CreateShoppingListRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 为每个购物项生成ID
	for i := range req.Items {
		if req.Items[i].ID == "" {
			req.Items[i].ID = uuid.New().String()
		}
	}

	// 默认名称
	if req.Name == "" {
		req.Name = "购物清单"
	}

	list := &models.ShoppingList{
		Name:   req.Name,
		Items:  req.Items,
		UserID: userID,
	}

	// 计算总价
	list.CalculateTotalPrice()

	if result := config.DB.Create(list); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建购物清单失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", list))
}

// UpdateShoppingList 更新购物清单
// @Summary 更新购物清单
// @Description 更新指定的购物清单
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Param request body CreateShoppingListRequest true "清单信息"
// @Success 200 {object} models.Response{data=models.ShoppingList}
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId} [put]
func (h *ShoppingHandler) UpdateShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	var list models.ShoppingList
	if result := config.DB.Where("id = ? AND user_id = ?", listID, userID).First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	var req CreateShoppingListRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 构建更新数据
	updates := make(map[string]interface{})
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Items != nil {
		// 为每个购物项生成ID
		for i := range req.Items {
			if req.Items[i].ID == "" {
				req.Items[i].ID = uuid.New().String()
			}
		}
		list.Items = req.Items
		list.CalculateTotalPrice()
		updates["items"] = list.Items
		updates["total_price"] = list.TotalPrice
	}

	if len(updates) > 0 {
		if result := config.DB.Model(&list).Updates(updates); result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
				models.CodeServerError,
				"更新失败",
			))
			return
		}
	}

	// 重新获取清单
	config.DB.First(&list, "id = ?", listID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", list))
}

// AddShoppingItem 添加购物项
// @Summary 添加购物项
// @Description 向购物清单添加购物项
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Param request body AddShoppingItemRequest true "购物项信息"
// @Success 200 {object} models.Response{data=models.ShoppingItem}
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/items [post]
func (h *ShoppingHandler) AddShoppingItem(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	var list models.ShoppingList
	if result := config.DB.Where("id = ? AND user_id = ?", listID, userID).First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	var req AddShoppingItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：商品名称不能为空",
		))
		return
	}

	item := models.ShoppingItem{
		ID:      uuid.New().String(),
		Name:    req.Name,
		Amount:  req.Amount,
		Price:   req.Price,
		Checked: false,
	}

	list.AddItem(item)

	// 更新清单
	config.DB.Model(&list).Updates(map[string]interface{}{
		"items":       list.Items,
		"total_price": list.TotalPrice,
	})

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("添加成功", item))
}

// UpdateShoppingItem 更新购物项
// @Summary 更新购物项
// @Description 更新购物清单中的购物项
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Param itemId path string true "购物项ID"
// @Param request body UpdateShoppingItemRequest true "购物项信息"
// @Success 200 {object} models.Response{data=models.ShoppingItem}
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/items/{itemId} [put]
func (h *ShoppingHandler) UpdateShoppingItem(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")
	itemID := c.Param("itemId")

	var list models.ShoppingList
	if result := config.DB.Where("id = ? AND user_id = ?", listID, userID).First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	var req UpdateShoppingItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 查找并更新购物项
	var foundItem *models.ShoppingItem
	for i, item := range list.Items {
		if item.ID == itemID {
			if req.Name != "" {
				list.Items[i].Name = req.Name
			}
			if req.Amount != "" {
				list.Items[i].Amount = req.Amount
			}
			if req.Price != nil {
				list.Items[i].Price = *req.Price
			}
			if req.Checked != nil {
				list.Items[i].Checked = *req.Checked
			}
			foundItem = &list.Items[i]
			break
		}
	}

	if foundItem == nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物项不存在",
		))
		return
	}

	// 重新计算总价
	list.CalculateTotalPrice()

	// 更新清单
	config.DB.Model(&list).Updates(map[string]interface{}{
		"items":       list.Items,
		"total_price": list.TotalPrice,
	})

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", foundItem))
}

// DeleteShoppingItem 删除购物项
// @Summary 删除购物项
// @Description 从购物清单删除购物项
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Param itemId path string true "购物项ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/items/{itemId} [delete]
func (h *ShoppingHandler) DeleteShoppingItem(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")
	itemID := c.Param("itemId")

	var list models.ShoppingList
	if result := config.DB.Where("id = ? AND user_id = ?", listID, userID).First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	if !list.RemoveItem(itemID) {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物项不存在",
		))
		return
	}

	// 更新清单
	config.DB.Model(&list).Updates(map[string]interface{}{
		"items":       list.Items,
		"total_price": list.TotalPrice,
	})

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("删除成功", nil))
}

// CompleteShoppingList 完成购物清单
// @Summary 完成购物清单
// @Description 标记购物清单为已完成
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/complete [post]
func (h *ShoppingHandler) CompleteShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	var list models.ShoppingList
	if result := config.DB.Where("id = ? AND user_id = ?", listID, userID).First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	completedAt := time.Now()
	config.DB.Model(&list).Update("completed_at", completedAt)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("完成成功", gin.H{
		"id":          list.ID,
		"completedAt": completedAt,
	}))
}

// ShareShoppingList 分享购物清单
// @Summary 分享购物清单
// @Description 生成购物清单的分享链接
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId}/share [post]
func (h *ShoppingHandler) ShareShoppingList(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	var list models.ShoppingList
	if result := config.DB.Where("id = ? AND user_id = ?", listID, userID).First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	// 生成分享码
	shareCode := uuid.New().String()[:8]

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("分享成功", gin.H{
		"shareUrl":  "https://bitepal.com/share/" + shareCode,
		"shareCode": shareCode,
	}))
}

// GetShoppingListDetail 获取购物清单详情
// @Summary 获取购物清单详情
// @Description 获取指定购物清单的完整详情
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param listId path string true "清单ID"
// @Success 200 {object} models.Response{data=models.ShoppingList}
// @Failure 404 {object} models.Response
// @Router /api/shopping-lists/{listId} [get]
func (h *ShoppingHandler) GetShoppingListDetail(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	listID := c.Param("listId")

	var list models.ShoppingList
	if result := config.DB.Where("id = ? AND user_id = ?", listID, userID).First(&list); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"购物清单不存在",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", list))
}

// GetShoppingHistory 获取购物订单历史
// @Summary 获取购物订单历史
// @Description 获取已完成的购物清单历史
// @Tags 购物清单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param startDate query string false "开始日期"
// @Param endDate query string false "结束日期"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/shopping-lists/history [get]
func (h *ShoppingHandler) GetShoppingHistory(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

	// 构建查询 - 只查询已完成的清单
	query := config.DB.Model(&models.ShoppingList{}).
		Where("user_id = ? AND completed_at IS NOT NULL", userID)

	// 日期筛选
	if startDate := c.Query("startDate"); startDate != "" {
		query = query.Where("completed_at >= ?", startDate)
	}
	if endDate := c.Query("endDate"); endDate != "" {
		query = query.Where("completed_at <= ?", endDate+" 23:59:59")
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取列表
	var lists []models.ShoppingList
	query.Offset(pagination.Offset).Limit(pagination.PageSize).Order("completed_at DESC").Find(&lists)

	// 转换为历史项
	historyList := make([]*models.ShoppingListHistoryItem, len(lists))
	for i, list := range lists {
		historyList[i] = list.ToHistoryItem()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(historyList, total, pagination.Page, pagination.PageSize)))
}

