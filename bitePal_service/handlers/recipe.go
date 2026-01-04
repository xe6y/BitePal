package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"bitePal_service/utils"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// RecipeHandler 菜谱处理器
type RecipeHandler struct{}

// NewRecipeHandler 创建菜谱处理器实例
// 返回: 菜谱处理器
func NewRecipeHandler() *RecipeHandler {
	return &RecipeHandler{}
}

// CreateRecipeRequest 创建菜谱请求结构
type CreateRecipeRequest struct {
	Name        string                    `json:"name" binding:"required"` // 菜谱名称
	Image       string                    `json:"image"`                   // 图片URL
	Time        string                    `json:"time"`                    // 制作时间
	Difficulty  string                    `json:"difficulty"`              // 难度
	Tags        []string                  `json:"tags"`                    // 标签
	TagColors   []string                  `json:"tagColors"`               // 标签颜色
	Categories  []string                  `json:"categories"`              // 分类
	Ingredients []models.RecipeIngredient `json:"ingredients"`             // 食材
	Steps       []string                  `json:"steps"`                   // 步骤
	IsPublic    bool                      `json:"isPublic"`                // 是否公开
}

// GetMyRecipes 获取我的菜谱列表
// @Summary 获取我的菜谱列表
// @Description 获取当前用户创建的菜谱列表
// @Tags 菜谱
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param keyword query string false "搜索关键词"
// @Param tastes query string false "口味筛选"
// @Param difficulty query string false "难度筛选"
// @Param cuisines query string false "菜系筛选"
// @Param favorite query bool false "是否只显示收藏"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/recipes/my [get]
func (h *RecipeHandler) GetMyRecipes(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	pagination := utils.GetPagination(c)

	// 构建查询
	query := config.DB.Model(&models.Recipe{}).Where("user_id = ?", userID)

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

	// 难度筛选
	if difficulty := c.Query("difficulty"); difficulty != "" {
		difficulties := strings.Split(difficulty, ",")
		query = query.Where("difficulty IN ?", difficulties)
	}

	// 菜系筛选
	if cuisines := c.Query("cuisines"); cuisines != "" {
		cuisineList := strings.Split(cuisines, ",")
		for _, cuisine := range cuisineList {
			query = query.Where("categories LIKE ?", "%"+cuisine+"%")
		}
	}

	// 收藏筛选
	if favorite := c.Query("favorite"); favorite == "true" {
		query = query.Where("favorite = ?", true)
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

// GetPublicRecipes 获取网络菜谱列表
// @Summary 获取网络菜谱列表
// @Description 获取公开的菜谱列表
// @Tags 菜谱
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param keyword query string false "搜索关键词"
// @Success 200 {object} models.Response{data=models.PagedResponse}
// @Router /api/recipes/public [get]
func (h *RecipeHandler) GetPublicRecipes(c *gin.Context) {
	pagination := utils.GetPagination(c)

	// 构建查询 - 只查询公开的菜谱
	query := config.DB.Model(&models.Recipe{}).Where("is_public = ?", true)

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

	// 难度筛选
	if difficulty := c.Query("difficulty"); difficulty != "" {
		difficulties := strings.Split(difficulty, ",")
		query = query.Where("difficulty IN ?", difficulties)
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

// GetRecipeDetail 获取菜谱详情
// @Summary 获取菜谱详情
// @Description 获取指定菜谱的详细信息
// @Tags 菜谱
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recipeId path string true "菜谱ID"
// @Success 200 {object} models.Response{data=models.Recipe}
// @Failure 404 {object} models.Response
// @Router /api/recipes/{recipeId} [get]
func (h *RecipeHandler) GetRecipeDetail(c *gin.Context) {
	recipeID := c.Param("recipeId")

	var recipe models.Recipe
	if result := config.DB.First(&recipe, "id = ?", recipeID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"菜谱不存在",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", recipe))
}

// CreateRecipe 创建菜谱
// @Summary 创建菜谱
// @Description 创建新的菜谱
// @Tags 菜谱
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateRecipeRequest true "菜谱信息"
// @Success 200 {object} models.Response{data=models.Recipe}
// @Failure 400 {object} models.Response
// @Router /api/recipes [post]
func (h *RecipeHandler) CreateRecipe(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req CreateRecipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：菜谱名称不能为空",
		))
		return
	}

	recipe := &models.Recipe{
		Name:        req.Name,
		Image:       req.Image,
		Time:        req.Time,
		Difficulty:  req.Difficulty,
		Tags:        req.Tags,
		TagColors:   req.TagColors,
		Categories:  req.Categories,
		Ingredients: req.Ingredients,
		Steps:       req.Steps,
		IsPublic:    req.IsPublic,
		UserID:      userID,
		Favorite:    false,
	}

	if result := config.DB.Create(recipe); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"菜谱创建失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", recipe))
}

// UpdateRecipe 更新菜谱
// @Summary 更新菜谱
// @Description 更新指定的菜谱
// @Tags 菜谱
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recipeId path string true "菜谱ID"
// @Param request body CreateRecipeRequest true "菜谱信息"
// @Success 200 {object} models.Response{data=models.Recipe}
// @Failure 403 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/recipes/{recipeId} [put]
func (h *RecipeHandler) UpdateRecipe(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	recipeID := c.Param("recipeId")

	var recipe models.Recipe
	if result := config.DB.First(&recipe, "id = ?", recipeID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"菜谱不存在",
		))
		return
	}

	// 检查权限
	if recipe.UserID != userID {
		c.JSON(http.StatusForbidden, models.NewErrorResponse(
			models.CodeForbidden,
			"无权限修改此菜谱",
		))
		return
	}

	var req CreateRecipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 更新字段
	updates := map[string]interface{}{
		"name":        req.Name,
		"image":       req.Image,
		"time":        req.Time,
		"difficulty":  req.Difficulty,
		"tags":        models.StringArray(req.Tags),
		"tag_colors":  models.StringArray(req.TagColors),
		"categories":  models.StringArray(req.Categories),
		"ingredients": models.RecipeIngredients(req.Ingredients),
		"steps":       models.StringArray(req.Steps),
		"is_public":   req.IsPublic,
	}

	if result := config.DB.Model(&recipe).Updates(updates); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"更新失败",
		))
		return
	}

	// 重新获取菜谱
	config.DB.First(&recipe, "id = ?", recipeID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", recipe))
}

// DeleteRecipe 删除菜谱
// @Summary 删除菜谱
// @Description 删除指定的菜谱
// @Tags 菜谱
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recipeId path string true "菜谱ID"
// @Success 200 {object} models.Response
// @Failure 403 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/recipes/{recipeId} [delete]
func (h *RecipeHandler) DeleteRecipe(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	recipeID := c.Param("recipeId")

	var recipe models.Recipe
	if result := config.DB.First(&recipe, "id = ?", recipeID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"菜谱不存在",
		))
		return
	}

	// 检查权限
	if recipe.UserID != userID {
		c.JSON(http.StatusForbidden, models.NewErrorResponse(
			models.CodeForbidden,
			"无权限删除此菜谱",
		))
		return
	}

	if result := config.DB.Delete(&recipe); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"删除失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("删除成功", nil))
}

// FavoriteRequest 收藏请求结构
type FavoriteRequest struct {
	Favorite bool `json:"favorite"` // 是否收藏
}

// ToggleFavorite 收藏/取消收藏菜谱
// @Summary 收藏/取消收藏菜谱
// @Description 收藏或取消收藏指定的菜谱
// @Tags 菜谱
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recipeId path string true "菜谱ID"
// @Param request body FavoriteRequest true "收藏请求"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/recipes/{recipeId}/favorite [post]
func (h *RecipeHandler) ToggleFavorite(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	recipeID := c.Param("recipeId")

	var req FavoriteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	var recipe models.Recipe
	if result := config.DB.First(&recipe, "id = ?", recipeID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"菜谱不存在",
		))
		return
	}

	// 如果是用户自己的菜谱，直接更新favorite字段
	if recipe.UserID == userID {
		config.DB.Model(&recipe).Update("favorite", req.Favorite)
	} else {
		// 如果是网络菜谱，操作收藏关联表
		if req.Favorite {
			// 添加收藏
			favorite := &models.UserFavorite{
				UserID:   userID,
				RecipeID: recipeID,
			}
			config.DB.Create(favorite)
		} else {
			// 取消收藏
			config.DB.Where("user_id = ? AND recipe_id = ?", userID, recipeID).Delete(&models.UserFavorite{})
		}
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("操作成功", gin.H{
		"favorite": req.Favorite,
	}))
}

// AddToMyRecipes 加入我的菜单（从网络菜谱）
// @Summary 加入我的菜单
// @Description 将网络菜谱添加到我的菜单
// @Tags 菜谱
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recipeId path string true "菜谱ID"
// @Success 200 {object} models.Response{data=models.Recipe}
// @Failure 404 {object} models.Response
// @Router /api/recipes/{recipeId}/add-to-my [post]
func (h *RecipeHandler) AddToMyRecipes(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	recipeID := c.Param("recipeId")

	var recipe models.Recipe
	if result := config.DB.First(&recipe, "id = ?", recipeID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"菜谱不存在",
		))
		return
	}

	// 复制菜谱到用户的菜谱
	newRecipe := &models.Recipe{
		ID:          uuid.New().String(),
		Name:        recipe.Name,
		Image:       recipe.Image,
		Time:        recipe.Time,
		Difficulty:  recipe.Difficulty,
		Tags:        recipe.Tags,
		TagColors:   recipe.TagColors,
		Categories:  recipe.Categories,
		Ingredients: recipe.Ingredients,
		Steps:       recipe.Steps,
		UserID:      userID,
		IsPublic:    false, // 复制的菜谱默认为私有
		Favorite:    false,
	}

	if result := config.DB.Create(newRecipe); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"添加失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("添加成功", newRecipe))
}

