package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// UserStats 用户统计数据模型
type UserStats struct {
	ID                  string         `json:"id" gorm:"primaryKey"`         // ID
	UserID              string         `json:"userId" gorm:"uniqueIndex"`    // 用户ID
	MonthlyCookingCount int            `json:"monthlyCookingCount"`          // 本月做饭次数
	WasteReductionRate  float64        `json:"wasteReductionRate"`           // 食材浪费减少率
	TotalRecipes        int            `json:"totalRecipes"`                 // 总菜谱数
	FavoriteRecipes     int            `json:"favoriteRecipes"`              // 收藏菜谱数
	Month               string         `json:"month" gorm:"index"`           // 统计月份（YYYY-MM）
	CreatedAt           time.Time      `json:"createdAt"`                    // 创建时间
	UpdatedAt           time.Time      `json:"updatedAt"`                    // 更新时间
	DeletedAt           gorm.DeletedAt `json:"-" gorm:"index"`               // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (u *UserStats) BeforeCreate(tx *gorm.DB) error {
	if u.ID == "" {
		u.ID = uuid.New().String()
	}
	return nil
}

// UserStatsResponse 用户统计响应结构
type UserStatsResponse struct {
	UserID              string    `json:"userId"`              // 用户ID
	MonthlyCookingCount int       `json:"monthlyCookingCount"` // 本月做饭次数
	WasteReductionRate  float64   `json:"wasteReductionRate"`  // 食材浪费减少率
	TotalRecipes        int       `json:"totalRecipes"`        // 总菜谱数
	FavoriteRecipes     int       `json:"favoriteRecipes"`     // 收藏菜谱数
	UpdatedAt           time.Time `json:"updatedAt"`           // 更新时间
}

// ToResponse 转换为响应结构
// 返回: 用户统计响应结构
func (u *UserStats) ToResponse() *UserStatsResponse {
	return &UserStatsResponse{
		UserID:              u.UserID,
		MonthlyCookingCount: u.MonthlyCookingCount,
		WasteReductionRate:  u.WasteReductionRate,
		TotalRecipes:        u.TotalRecipes,
		FavoriteRecipes:     u.FavoriteRecipes,
		UpdatedAt:           u.UpdatedAt,
	}
}

