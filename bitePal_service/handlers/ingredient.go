package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// IngredientHandler 食材处理器
type IngredientHandler struct{}

// NewIngredientHandler 创建食材处理器实例
// 返回: 食材处理器
func NewIngredientHandler() *IngredientHandler {
	return &IngredientHandler{}
}

// CreateIngredientRequest 创建食材请求结构
type CreateIngredientRequest struct {
	Name       string `json:"name" binding:"required"` // 食材名称
	Amount     string `json:"amount"`                  // 数量
	Category   string `json:"category"`                // 存储分类
	Icon       string `json:"icon"`                    // 图标
	ExpiryDate string `json:"expiryDate"`              // 过期日期
}

// GetIngredients 获取食材列表
// @Summary 获取食材列表
// @Description 获取用户的食材库存列表
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param category query string false "分类筛选（room/fridge/freezer）"
// @Param urgent query bool false "是否只显示紧急"
// @Param expiringDays query int false "过期天数筛选"
// @Success 200 {object} models.Response{data=object}
// @Router /api/ingredients [get]
func (h *IngredientHandler) GetIngredients(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 构建查询
	query := config.DB.Model(&models.IngredientItem{}).Where("user_id = ?", userID)

	// 分类筛选
	if category := c.Query("category"); category != "" {
		query = query.Where("category = ?", category)
	}

	// 紧急筛选
	if urgent := c.Query("urgent"); urgent == "true" {
		today := time.Now().Format("2006-01-02")
		query = query.Where("expiry_date <= ?", today)
	}

	// 过期天数筛选
	if expiringDaysStr := c.Query("expiringDays"); expiringDaysStr != "" {
		days, _ := strconv.Atoi(expiringDaysStr)
		targetDate := time.Now().AddDate(0, 0, days).Format("2006-01-02")
		query = query.Where("expiry_date <= ?", targetDate)
	}

	// 获取列表
	var ingredients []models.IngredientItem
	query.Order("expiry_date ASC").Find(&ingredients)

	// 转换为响应结构
	list := make([]*models.IngredientResponse, len(ingredients))
	for i, item := range ingredients {
		list[i] = item.ToResponse()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list":  list,
		"total": len(list),
	}))
}

// GetExpiringIngredients 获取即将过期食材
// @Summary 获取即将过期食材
// @Description 获取指定天数内即将过期的食材
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param days query int false "天数（默认3）"
// @Success 200 {object} models.Response{data=object}
// @Router /api/ingredients/expiring [get]
func (h *IngredientHandler) GetExpiringIngredients(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 获取天数参数，默认3天
	days, _ := strconv.Atoi(c.DefaultQuery("days", "3"))

	// 计算目标日期
	targetDate := time.Now().AddDate(0, 0, days)

	// 查询即将过期的食材
	var ingredients []models.IngredientItem
	config.DB.Where("user_id = ? AND expiry_date <= ?", userID, targetDate).
		Order("expiry_date ASC").
		Find(&ingredients)

	// 转换为响应结构
	list := make([]*models.IngredientResponse, len(ingredients))
	for i, item := range ingredients {
		list[i] = item.ToResponse()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list":  list,
		"total": len(list),
	}))
}

// GetIngredientDetail 获取食材详情
// @Summary 获取食材详情
// @Description 获取指定食材的详细信息
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param ingredientId path string true "食材ID"
// @Success 200 {object} models.Response{data=models.IngredientResponse}
// @Failure 404 {object} models.Response
// @Router /api/ingredients/{ingredientId} [get]
func (h *IngredientHandler) GetIngredientDetail(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	ingredientID := c.Param("ingredientId")

	var ingredient models.IngredientItem
	if result := config.DB.Where("id = ? AND user_id = ?", ingredientID, userID).First(&ingredient); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"食材不存在",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", ingredient.ToResponse()))
}

// CreateIngredient 添加食材
// @Summary 添加食材
// @Description 添加新的食材到库存
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateIngredientRequest true "食材信息"
// @Success 200 {object} models.Response{data=models.IngredientResponse}
// @Failure 400 {object} models.Response
// @Router /api/ingredients [post]
func (h *IngredientHandler) CreateIngredient(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req CreateIngredientRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：食材名称不能为空",
		))
		return
	}

	// 解析过期日期
	var expiryDate time.Time
	if req.ExpiryDate != "" {
		var err error
		expiryDate, err = time.Parse("2006-01-02", req.ExpiryDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.NewErrorResponse(
				models.CodeBadRequest,
				"过期日期格式错误，应为：YYYY-MM-DD",
			))
			return
		}
	} else {
		// 默认7天后过期
		expiryDate = time.Now().AddDate(0, 0, 7)
	}

	// 默认分类
	if req.Category == "" {
		req.Category = models.CategoryFridge
	}

	ingredient := &models.IngredientItem{
		Name:       req.Name,
		Amount:     req.Amount,
		Category:   req.Category,
		Icon:       req.Icon,
		ExpiryDate: expiryDate,
		UserID:     userID,
	}

	if result := config.DB.Create(ingredient); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"添加食材失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("添加成功", ingredient.ToResponse()))
}

// UpdateIngredient 更新食材
// @Summary 更新食材
// @Description 更新指定的食材信息
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param ingredientId path string true "食材ID"
// @Param request body CreateIngredientRequest true "食材信息"
// @Success 200 {object} models.Response{data=models.IngredientResponse}
// @Failure 404 {object} models.Response
// @Router /api/ingredients/{ingredientId} [put]
func (h *IngredientHandler) UpdateIngredient(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	ingredientID := c.Param("ingredientId")

	var ingredient models.IngredientItem
	if result := config.DB.Where("id = ? AND user_id = ?", ingredientID, userID).First(&ingredient); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"食材不存在",
		))
		return
	}

	var req CreateIngredientRequest
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
	if req.Amount != "" {
		updates["amount"] = req.Amount
	}
	if req.Category != "" {
		updates["category"] = req.Category
	}
	if req.Icon != "" {
		updates["icon"] = req.Icon
	}
	if req.ExpiryDate != "" {
		expiryDate, err := time.Parse("2006-01-02", req.ExpiryDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.NewErrorResponse(
				models.CodeBadRequest,
				"过期日期格式错误，应为：YYYY-MM-DD",
			))
			return
		}
		updates["expiry_date"] = expiryDate
	}

	if len(updates) > 0 {
		if result := config.DB.Model(&ingredient).Updates(updates); result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
				models.CodeServerError,
				"更新失败",
			))
			return
		}
	}

	// 重新获取食材信息
	config.DB.First(&ingredient, "id = ?", ingredientID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", ingredient.ToResponse()))
}

// DeleteIngredient 删除食材
// @Summary 删除食材
// @Description 删除指定的食材
// @Tags 食材管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param ingredientId path string true "食材ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/ingredients/{ingredientId} [delete]
func (h *IngredientHandler) DeleteIngredient(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	ingredientID := c.Param("ingredientId")

	var ingredient models.IngredientItem
	if result := config.DB.Where("id = ? AND user_id = ?", ingredientID, userID).First(&ingredient); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"食材不存在",
		))
		return
	}

	if result := config.DB.Delete(&ingredient); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"删除失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("删除成功", nil))
}

