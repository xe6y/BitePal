package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// StatsHandler 统计处理器
type StatsHandler struct{}

// NewStatsHandler 创建统计处理器实例
// 返回: 统计处理器
func NewStatsHandler() *StatsHandler {
	return &StatsHandler{}
}

// GetUserStats 获取用户统计数据
// @Summary 获取用户统计数据
// @Description 获取用户的统计数据（本月做饭次数、食材浪费减少率等）
// @Tags 用户统计
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param month query string false "月份（YYYY-MM，默认当前月）"
// @Success 200 {object} models.Response{data=models.UserStatsResponse}
// @Router /api/user/stats [get]
func (h *StatsHandler) GetUserStats(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 获取月份参数，默认当前月
	month := c.DefaultQuery("month", time.Now().Format("2006-01"))

	// 查找或计算统计数据
	var stats models.UserStats
	result := config.DB.Where("user_id = ? AND month = ?", userID, month).First(&stats)

	if result.Error != nil {
		// 如果不存在，计算统计数据
		stats = calculateUserStats(userID, month)
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", stats.ToResponse()))
}

// calculateUserStats 计算用户统计数据
// userID: 用户ID
// month: 月份
// 返回: 用户统计数据
func calculateUserStats(userID, month string) models.UserStats {
	// 计算本月做饭次数（已确认的点餐数量）
	var cookingCount int64
	startDate := month + "-01"
	endDate := month + "-31"
	config.DB.Model(&models.MealOrder{}).
		Where("user_id = ? AND status = ? AND created_at BETWEEN ? AND ?",
			userID, models.OrderStatusConfirmed, startDate, endDate+" 23:59:59").
		Count(&cookingCount)

	// 计算总菜谱数
	var totalRecipes int64
	config.DB.Model(&models.Recipe{}).Where("user_id = ?", userID).Count(&totalRecipes)

	// 计算收藏菜谱数
	var favoriteRecipes int64
	config.DB.Model(&models.Recipe{}).Where("user_id = ? AND favorite = ?", userID, true).Count(&favoriteRecipes)
	// 加上用户收藏的网络菜谱
	var publicFavorites int64
	config.DB.Model(&models.UserFavorite{}).Where("user_id = ?", userID).Count(&publicFavorites)
	favoriteRecipes += publicFavorites

	// 计算食材浪费减少率（模拟数据）
	// 实际应用中应该根据过期食材的使用情况计算
	wasteReductionRate := calculateWasteReductionRate(userID)

	stats := models.UserStats{
		UserID:              userID,
		MonthlyCookingCount: int(cookingCount),
		WasteReductionRate:  wasteReductionRate,
		TotalRecipes:        int(totalRecipes),
		FavoriteRecipes:     int(favoriteRecipes),
		Month:               month,
	}

	// 保存统计数据
	config.DB.Create(&stats)

	return stats
}

// calculateWasteReductionRate 计算食材浪费减少率
// userID: 用户ID
// 返回: 浪费减少率百分比
func calculateWasteReductionRate(userID string) float64 {
	// 获取过期前3天内的食材数量
	threeDaysLater := time.Now().AddDate(0, 0, 3)
	var expiringCount int64
	config.DB.Model(&models.IngredientItem{}).
		Where("user_id = ? AND expiry_date <= ?", userID, threeDaysLater).
		Count(&expiringCount)

	// 获取总食材数量
	var totalCount int64
	config.DB.Model(&models.IngredientItem{}).
		Where("user_id = ?", userID).
		Count(&totalCount)

	if totalCount == 0 {
		return 0
	}

	// 计算已使用的比例（简化计算）
	usedRate := float64(totalCount-expiringCount) / float64(totalCount) * 100

	// 返回减少率（假设基准是50%的浪费率）
	if usedRate > 50 {
		return usedRate - 50
	}
	return 0
}

