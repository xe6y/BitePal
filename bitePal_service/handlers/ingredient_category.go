package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// IngredientCategoryHandler 食材分类处理器
type IngredientCategoryHandler struct{}

// NewIngredientCategoryHandler 创建食材分类处理器实例
// 返回: 食材分类处理器
func NewIngredientCategoryHandler() *IngredientCategoryHandler {
	return &IngredientCategoryHandler{}
}

// CreateCategoryRequest 创建分类请求结构
type CreateCategoryRequest struct {
	Name      string `json:"name" binding:"required"` // 分类名称
	Icon      string `json:"icon"`                    // 分类图标（emoji）
	Color     string `json:"color"`                   // 分类颜色
	SortOrder int    `json:"sortOrder"`               // 排序顺序
}

// GetCategories 获取食材分类列表
// @Summary 获取食材分类列表
// @Description 获取用户的食材分类列表（包含系统预设和自定义分类）
// @Tags 食材分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response{data=object}
// @Router /api/ingredient-categories [get]
func (h *IngredientCategoryHandler) GetCategories(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 查询系统分类和用户自定义分类
	var categories []models.IngredientCategory
	config.DB.Where("is_system = ? OR user_id = ?", true, userID).
		Order("sort_order ASC, created_at ASC").
		Find(&categories)

	// 转换为响应结构
	list := make([]*models.IngredientCategoryResp, len(categories))
	for i, cat := range categories {
		list[i] = cat.ToCategoryResp()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"list":  list,
		"total": len(list),
	}))
}

// GetCategoryDetail 获取食材分类详情
// @Summary 获取食材分类详情
// @Description 获取指定分类的详细信息
// @Tags 食材分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param categoryId path string true "分类ID"
// @Success 200 {object} models.Response{data=models.IngredientCategoryResp}
// @Failure 404 {object} models.Response
// @Router /api/ingredient-categories/{categoryId} [get]
func (h *IngredientCategoryHandler) GetCategoryDetail(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	categoryID := c.Param("categoryId")

	var category models.IngredientCategory
	// 可以查看系统分类或自己的自定义分类
	if result := config.DB.Where("id = ? AND (is_system = ? OR user_id = ?)", categoryID, true, userID).First(&category); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"分类不存在",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", category.ToCategoryResp()))
}

// CreateCategory 创建食材分类
// @Summary 创建食材分类
// @Description 创建自定义食材分类
// @Tags 食材分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateCategoryRequest true "分类信息"
// @Success 200 {object} models.Response{data=models.IngredientCategoryResp}
// @Failure 400 {object} models.Response
// @Router /api/ingredient-categories [post]
func (h *IngredientCategoryHandler) CreateCategory(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req CreateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：分类名称不能为空",
		))
		return
	}

	// 检查是否已存在同名分类
	var existing models.IngredientCategory
	if result := config.DB.Where("name = ? AND (is_system = ? OR user_id = ?)", req.Name, true, userID).First(&existing); result.Error == nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"分类名称已存在",
		))
		return
	}

	// 默认图标和颜色
	if req.Icon == "" {
		req.Icon = "📦"
	}
	if req.Color == "" {
		req.Color = "#9E9E9E"
	}

	category := &models.IngredientCategory{
		Name:      req.Name,
		Icon:      req.Icon,
		Color:     req.Color,
		SortOrder: req.SortOrder,
		IsSystem:  false,
		UserID:    userID,
	}

	if result := config.DB.Create(category); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建分类失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", category.ToCategoryResp()))
}

// UpdateCategory 更新食材分类
// @Summary 更新食材分类
// @Description 更新自定义食材分类（系统预设分类不可修改）
// @Tags 食材分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param categoryId path string true "分类ID"
// @Param request body CreateCategoryRequest true "分类信息"
// @Success 200 {object} models.Response{data=models.IngredientCategoryResp}
// @Failure 400 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/ingredient-categories/{categoryId} [put]
func (h *IngredientCategoryHandler) UpdateCategory(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	categoryID := c.Param("categoryId")

	var category models.IngredientCategory
	if result := config.DB.Where("id = ? AND user_id = ?", categoryID, userID).First(&category); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"分类不存在或无权限修改",
		))
		return
	}

	// 系统分类不可修改
	if category.IsSystem {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"系统预设分类不可修改",
		))
		return
	}

	var req CreateCategoryRequest
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
	if req.Icon != "" {
		updates["icon"] = req.Icon
	}
	if req.Color != "" {
		updates["color"] = req.Color
	}
	if req.SortOrder > 0 {
		updates["sort_order"] = req.SortOrder
	}

	if len(updates) > 0 {
		if result := config.DB.Model(&category).Updates(updates); result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
				models.CodeServerError,
				"更新失败",
			))
			return
		}
	}

	// 重新获取分类信息
	config.DB.First(&category, "id = ?", categoryID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", category.ToCategoryResp()))
}

// DeleteCategory 删除食材分类
// @Summary 删除食材分类
// @Description 删除自定义食材分类（系统预设分类不可删除）
// @Tags 食材分类
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param categoryId path string true "分类ID"
// @Success 200 {object} models.Response
// @Failure 400 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/ingredient-categories/{categoryId} [delete]
func (h *IngredientCategoryHandler) DeleteCategory(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	categoryID := c.Param("categoryId")

	var category models.IngredientCategory
	if result := config.DB.Where("id = ? AND user_id = ?", categoryID, userID).First(&category); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"分类不存在或无权限删除",
		))
		return
	}

	// 系统分类不可删除
	if category.IsSystem {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"系统预设分类不可删除",
		))
		return
	}

	// 检查是否有食材使用该分类
	var count int64
	config.DB.Model(&models.IngredientItem{}).Where("category_id = ? AND user_id = ?", categoryID, userID).Count(&count)
	if count > 0 {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"该分类下还有食材，无法删除",
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

