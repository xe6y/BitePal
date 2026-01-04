package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// RandomHandler 随机推荐处理器
type RandomHandler struct{}

// NewRandomHandler 创建随机推荐处理器实例
// 返回: 随机推荐处理器
func NewRandomHandler() *RandomHandler {
	return &RandomHandler{}
}

// 推荐模式常量
const (
	ModeInventory = "inventory" // 使用库存优先
	ModeRandom    = "random"    // 完全随机
	ModeQuick     = "quick"     // 快手菜
)

// RandomRecipeRequest 随机推荐请求结构
type RandomRecipeRequest struct {
	Mode    string `json:"mode"`    // 推荐模式
	MaxTime int    `json:"maxTime"` // 最大制作时间（分钟）
}

// RandomRecipeResponse 随机推荐响应结构
type RandomRecipeResponse struct {
	Recipe *models.RecipeListItem `json:"recipe"` // 推荐的菜谱
	Reason string                 `json:"reason"` // 推荐理由
}

// RandomRecipe 随机推荐菜品
// @Summary 随机推荐菜品
// @Description 根据模式随机推荐一道菜品
// @Tags 随机推荐
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body RandomRecipeRequest true "推荐请求"
// @Success 200 {object} models.Response{data=RandomRecipeResponse}
// @Router /api/recipes/random [post]
func (h *RandomHandler) RandomRecipe(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req RandomRecipeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// 默认使用完全随机模式
		req.Mode = ModeRandom
	}

	// 构建查询 - 用户的菜谱和公开的菜谱
	query := config.DB.Model(&models.Recipe{}).Where("user_id = ? OR is_public = ?", userID, true)

	var reason string

	switch req.Mode {
	case ModeInventory:
		// 使用库存优先模式
		// 获取用户的食材列表
		var ingredients []models.IngredientItem
		config.DB.Where("user_id = ?", userID).Find(&ingredients)

		if len(ingredients) > 0 {
			// 构建食材名称列表
			ingredientNames := make([]string, len(ingredients))
			for i, ing := range ingredients {
				ingredientNames[i] = ing.Name
			}

			// 尝试匹配有这些食材的菜谱
			for _, name := range ingredientNames {
				query = query.Or("ingredients LIKE ?", "%"+name+"%")
			}
			reason = "根据您的食材库存智能推荐"
		} else {
			reason = "随机推荐（暂无库存食材）"
		}

	case ModeQuick:
		// 快手菜模式（≤20分钟）
		maxTime := 20
		if req.MaxTime > 0 {
			maxTime = req.MaxTime
		}

		// 筛选制作时间短的菜谱
		// 注意：time字段是字符串，需要特殊处理
		// 简单处理：假设time字段格式为"XX分钟"
		query = query.Where("time LIKE ? OR time LIKE ? OR time LIKE ?",
			strconv.Itoa(maxTime)+"%",
			"1%分钟",
			"5分钟",
		)
		reason = "快手菜推荐，" + strconv.Itoa(maxTime) + "分钟内完成"

	default:
		// 完全随机模式
		reason = "为您随机推荐"
	}

	// 获取符合条件的菜谱
	var recipes []models.Recipe
	query.Find(&recipes)

	if len(recipes) == 0 {
		c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("暂无推荐", &RandomRecipeResponse{
			Recipe: nil,
			Reason: "暂无符合条件的菜谱",
		}))
		return
	}

	// 随机选择一个
	rand.Seed(time.Now().UnixNano())
	randomIndex := rand.Intn(len(recipes))
	selectedRecipe := recipes[randomIndex]

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("推荐成功", &RandomRecipeResponse{
		Recipe: selectedRecipe.ToListItem(),
		Reason: reason,
	}))
}

