package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"bitePal_service/utils"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// MealHandler 点餐处理器
type MealHandler struct{}

// NewMealHandler 创建点餐处理器实例
// 返回: 点餐处理器
func NewMealHandler() *MealHandler {
	return &MealHandler{}
}

// CreateOrderRequest 创建点餐请求结构
type CreateOrderRequest struct {
	Recipes []models.OrderRecipe `json:"recipes" binding:"required"` // 菜谱列表
}

// GetMealRecipes 获取点餐菜品列表
// @Summary 获取点餐菜品列表
// @Description 获取可点餐的菜品列表（用户的菜谱）
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param keyword query string false "搜索关键词"
// @Param tastes query string false "口味筛选"
// @Param status query string false "食材状态筛选"
// @Param mealTypes query string false "餐点类型筛选"
// @Param cuisines query string false "菜系筛选"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/meals/recipes [get]
func (h *MealHandler) GetMealRecipes(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

	// 构建查询 - 用户自己的菜谱和公开的菜谱
	query := config.DB.Model(&models.Recipe{}).Where("user_id = ? OR is_public = ?", userID, true)

	// 关键词搜索
	if keyword := c.Query("keyword"); keyword != "" {
		query = query.Where("name LIKE ?", "%"+keyword+"%")
	}

	// 口味筛选
	if tastes := c.Query("tastes"); tastes != "" {
		tasteList := strings.Split(tastes, ",")
		for _, taste := range tasteList {
			query = query.Where("categories LIKE ?", "%"+taste+"%")
		}
	}

	// 菜系筛选
	if cuisines := c.Query("cuisines"); cuisines != "" {
		cuisineList := strings.Split(cuisines, ",")
		for _, cuisine := range cuisineList {
			query = query.Where("categories LIKE ?", "%"+cuisine+"%")
		}
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取列表
	var recipes []models.Recipe
	query.Offset(pagination.Offset).Limit(pagination.PageSize).Order("created_at DESC").Find(&recipes)

	// 转换为列表项
	list := make([]*models.RecipeListItem, len(recipes))
	for i, recipe := range recipes {
		list[i] = recipe.ToListItem()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(list, total, pagination.Page, pagination.PageSize)))
}

// CreateMealOrder 创建点餐清单
// @Summary 创建点餐清单
// @Description 创建新的点餐清单
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateOrderRequest true "点餐信息"
// @Success 200 {object} models.Response{data=models.MealOrder}
// @Failure 400 {object} models.Response
// @Router /api/meals/orders [post]
func (h *MealHandler) CreateMealOrder(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：菜谱列表不能为空",
		))
		return
	}

	if len(req.Recipes) == 0 {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请选择至少一道菜品",
		))
		return
	}

	order := &models.MealOrder{
		Recipes: req.Recipes,
		Status:  models.OrderStatusPending,
		UserID:  userID,
	}

	if result := config.DB.Create(order); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建点餐失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", order))
}

// ConfirmMealOrder 确认点餐
// @Summary 确认点餐
// @Description 确认指定的点餐清单
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param orderId path string true "点餐ID"
// @Success 200 {object} models.Response{data=models.MealOrder}
// @Failure 404 {object} models.Response
// @Router /api/meals/orders/{orderId}/confirm [post]
func (h *MealHandler) ConfirmMealOrder(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	orderID := c.Param("orderId")

	var order models.MealOrder
	if result := config.DB.Where("id = ? AND user_id = ?", orderID, userID).First(&order); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"点餐清单不存在",
		))
		return
	}

	// 确认点餐
	order.Confirm()

	if result := config.DB.Model(&order).Update("status", order.Status); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"确认失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("确认成功", gin.H{
		"id":        order.ID,
		"status":    order.Status,
		"updatedAt": order.UpdatedAt,
	}))
}

// GetMealOrders 获取点餐历史
// @Summary 获取点餐历史
// @Description 获取用户的点餐历史记录
// @Tags 家庭点餐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param status query string false "状态筛选"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/meals/orders [get]
func (h *MealHandler) GetMealOrders(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

	// 构建查询
	query := config.DB.Model(&models.MealOrder{}).Where("user_id = ?", userID)

	// 状态筛选
	if status := c.Query("status"); status != "" {
		statusList := strings.Split(status, ",")
		query = query.Where("status IN ?", statusList)
	}

	// 获取总数
	var total int64
	query.Count(&total)

	// 获取列表
	var orders []models.MealOrder
	query.Offset(pagination.Offset).Limit(pagination.PageSize).Order("created_at DESC").Find(&orders)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功",
		models.NewPagedResponse(orders, total, pagination.Page, pagination.PageSize)))
}

