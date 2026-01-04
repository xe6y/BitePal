package handlers

import (
	"bitePal_service/config"
	"bitePal_service/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// CategoryHandler 分类处理器
type CategoryHandler struct{}

// NewCategoryHandler 创建分类处理器实例
// 返回: 分类处理器
func NewCategoryHandler() *CategoryHandler {
	return &CategoryHandler{}
}

// GetRecipeCategories 获取菜谱分类列表
// @Summary 获取菜谱分类列表
// @Description 获取指定类型的菜谱分类列表，用于筛选
// @Tags 分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param type query string false "分类类型（taste/cuisine/difficulty/meal_type）"
// @Success 200 {object} models.Response{data=[]models.RecipeCategory}
// @Router /api/categories [get]
func (h *CategoryHandler) GetRecipeCategories(c *gin.Context) {
	categoryType := c.Query("type")

	query := config.DB.Model(&models.RecipeCategory{}).Where("is_active = ?", true)

	// 如果指定了类型，按类型筛选
	if categoryType != "" {
		query = query.Where("type = ?", categoryType)
	}

	var categories []models.RecipeCategory
	query.Order("type ASC, sort_order ASC").Find(&categories)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", categories))
}

// GetRecipeCategoriesByType 按类型获取菜谱分类
// @Summary 按类型获取菜谱分类
// @Description 获取指定类型的菜谱分类列表
// @Tags 分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param type path string true "分类类型（taste/cuisine/difficulty/meal_type）"
// @Success 200 {object} models.Response{data=[]models.RecipeCategory}
// @Router /api/categories/{type} [get]
func (h *CategoryHandler) GetRecipeCategoriesByType(c *gin.Context) {
	categoryType := c.Param("type")

	var categories []models.RecipeCategory
	config.DB.Where("type = ? AND is_active = ?", categoryType, true).
		Order("sort_order ASC").
		Find(&categories)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", categories))
}

// CreateRecipeCategoryRequest 创建菜谱分类请求结构
type CreateRecipeCategoryRequest struct {
	Type      string `json:"type" binding:"required"`     // 分类类型
	Name      string `json:"name" binding:"required"`     // 分类名称
	Color     string `json:"color"`                       // 显示颜色
	Icon      string `json:"icon"`                        // 图标
	SortOrder int    `json:"sortOrder"`                   // 排序顺序
	IsActive  bool   `json:"isActive" binding:"required"` // 是否启用
}

// CreateRecipeCategory 创建菜谱分类
// @Summary 创建菜谱分类
// @Description 创建新的菜谱分类
// @Tags 分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateRecipeCategoryRequest true "分类信息"
// @Success 200 {object} models.Response{data=models.RecipeCategory}
// @Failure 400 {object} models.Response
// @Router /api/categories [post]
func (h *CategoryHandler) CreateRecipeCategory(c *gin.Context) {
	var req CreateRecipeCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误："+err.Error(),
		))
		return
	}

	category := &models.RecipeCategory{
		Type:      models.CategoryType(req.Type),
		Name:      req.Name,
		Color:     req.Color,
		Icon:      req.Icon,
		SortOrder: req.SortOrder,
		IsActive:  req.IsActive,
	}

	if result := config.DB.Create(category); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"分类创建失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", category))
}

// UpdateRecipeCategory 更新菜谱分类
// @Summary 更新菜谱分类
// @Description 更新指定的菜谱分类
// @Tags 分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param categoryId path string true "分类ID"
// @Param request body CreateRecipeCategoryRequest true "分类信息"
// @Success 200 {object} models.Response{data=models.RecipeCategory}
// @Failure 404 {object} models.Response
// @Router /api/categories/{categoryId} [put]
func (h *CategoryHandler) UpdateRecipeCategory(c *gin.Context) {
	categoryID := c.Param("categoryId")

	var category models.RecipeCategory
	if result := config.DB.First(&category, "id = ?", categoryID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"分类不存在",
		))
		return
	}

	var req CreateRecipeCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 更新字段
	updates := map[string]interface{}{
		"type":       req.Type,
		"name":       req.Name,
		"color":      req.Color,
		"icon":       req.Icon,
		"sort_order": req.SortOrder,
		"is_active":  req.IsActive,
	}

	if result := config.DB.Model(&category).Updates(updates); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"更新失败",
		))
		return
	}

	// 重新获取分类
	config.DB.First(&category, "id = ?", categoryID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", category))
}

// DeleteRecipeCategory 删除菜谱分类
// @Summary 删除菜谱分类
// @Description 删除指定的菜谱分类
// @Tags 分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param categoryId path string true "分类ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/categories/{categoryId} [delete]
func (h *CategoryHandler) DeleteRecipeCategory(c *gin.Context) {
	categoryID := c.Param("categoryId")

	var category models.RecipeCategory
	if result := config.DB.First(&category, "id = ?", categoryID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"分类不存在",
		))
		return
	}

	if result := config.DB.Delete(&category); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"删除失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("删除成功", nil))
}

