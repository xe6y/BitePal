package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// MenuHandler 今日菜单处理器
type MenuHandler struct{}

// NewMenuHandler 创建今日菜单处理器实例
// 返回: 今日菜单处理器
func NewMenuHandler() *MenuHandler {
	return &MenuHandler{}
}

// AddRecipeToMenuRequest 添加菜谱到菜单请求结构
type AddRecipeToMenuRequest struct {
	RecipeID string `json:"recipeId" binding:"required"` // 菜谱ID
	MealType string `json:"mealType"`                    // 餐点类型（可选，默认晚餐）
	Date     string `json:"date"`                        // 日期（可选，默认今天）
}

// GetTodayMenu 获取今日菜单
// @Summary 获取今日菜单
// @Description 获取指定日期的菜单
// @Tags 今日菜单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param date query string false "日期（YYYY-MM-DD，默认今天）"
// @Success 200 {object} models.Response{data=models.TodayMenu}
// @Router /api/today-menu [get]
func (h *MenuHandler) GetTodayMenu(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 获取日期参数，默认今天
	date := c.DefaultQuery("date", time.Now().Format("2006-01-02"))

	var menu models.TodayMenu
	result := config.DB.Where("user_id = ? AND date = ?", userID, date).First(&menu)

	if result.Error != nil {
		// 如果不存在，返回空菜单
		menu = models.TodayMenu{
			Date:    date,
			Recipes: models.MenuRecipes{},
			UserID:  userID,
		}
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", menu))
}

// AddRecipeToMenu 添加菜谱到今日菜单
// @Summary 添加菜谱到今日菜单
// @Description 将菜谱添加到指定日期的菜单
// @Tags 今日菜单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body AddRecipeToMenuRequest true "添加请求"
// @Success 200 {object} models.Response{data=models.TodayMenu}
// @Failure 404 {object} models.Response
// @Router /api/today-menu/recipes [post]
func (h *MenuHandler) AddRecipeToMenu(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req AddRecipeToMenuRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：菜谱ID不能为空",
		))
		return
	}

	// 默认值
	if req.MealType == "" {
		req.MealType = models.MealTypeDinner
	}
	if req.Date == "" {
		req.Date = time.Now().Format("2006-01-02")
	}

	// 获取菜谱信息
	var recipe models.Recipe
	if result := config.DB.First(&recipe, "id = ?", req.RecipeID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"菜谱不存在",
		))
		return
	}

	// 查找或创建今日菜单
	var menu models.TodayMenu
	result := config.DB.Where("user_id = ? AND date = ?", userID, req.Date).First(&menu)

	if result.Error != nil {
		// 创建新菜单
		menu = models.TodayMenu{
			Date:    req.Date,
			Recipes: models.MenuRecipes{},
			UserID:  userID,
		}
	}

	// 添加菜谱
	menu.AddRecipe(models.MenuRecipe{
		RecipeID:   recipe.ID,
		RecipeName: recipe.Name,
		MealType:   req.MealType,
	})

	// 保存或更新
	if result.Error != nil {
		config.DB.Create(&menu)
	} else {
		config.DB.Model(&menu).Update("recipes", menu.Recipes)
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("添加成功", menu))
}

// RemoveRecipeFromMenu 从今日菜单移除菜谱
// @Summary 从今日菜单移除菜谱
// @Description 从指定日期的菜单中移除菜谱
// @Tags 今日菜单
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recipeId path string true "菜谱ID"
// @Param date query string false "日期（默认今天）"
// @Success 200 {object} models.Response
// @Router /api/today-menu/recipes/{recipeId} [delete]
func (h *MenuHandler) RemoveRecipeFromMenu(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	recipeID := c.Param("recipeId")
	date := c.DefaultQuery("date", time.Now().Format("2006-01-02"))

	var menu models.TodayMenu
	if result := config.DB.Where("user_id = ? AND date = ?", userID, date).First(&menu); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"菜单不存在",
		))
		return
	}

	// 移除菜谱
	if !menu.RemoveRecipe(recipeID) {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"菜谱不在菜单中",
		))
		return
	}

	// 更新菜单
	config.DB.Model(&menu).Update("recipes", menu.Recipes)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("移除成功", nil))
}

