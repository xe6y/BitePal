package models

import (
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// 食材存储分类常量
const (
	CategoryRoom    = "room"    // 常温
	CategoryFridge  = "fridge"  // 冷藏
	CategoryFreezer = "freezer" // 冷冻
)

// IngredientItem 食材库存模型
type IngredientItem struct {
	ID         string         `json:"id" gorm:"primaryKey"`       // 食材ID
	Name       string         `json:"name" gorm:"not null"`       // 食材名称
	Amount     string         `json:"amount"`                     // 数量（如：2个）
	Category   string         `json:"category"`                   // 存储分类（room/fridge/freezer）
	Icon       string         `json:"icon"`                       // 图标（emoji）
	ExpiryDate time.Time      `json:"expiryDate"`                 // 过期日期
	UserID     string         `json:"userId" gorm:"index"`        // 用户ID
	CreatedAt  time.Time      `json:"createdAt"`                  // 创建时间
	UpdatedAt  time.Time      `json:"updatedAt"`                  // 更新时间
	DeletedAt  gorm.DeletedAt `json:"-" gorm:"index"`             // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (i *IngredientItem) BeforeCreate(tx *gorm.DB) error {
	if i.ID == "" {
		i.ID = uuid.New().String()
	}
	return nil
}

// IngredientResponse 食材响应结构（包含计算字段）
type IngredientResponse struct {
	ID         string    `json:"id"`         // 食材ID
	Name       string    `json:"name"`       // 食材名称
	Amount     string    `json:"amount"`     // 数量
	Category   string    `json:"category"`   // 存储分类
	Icon       string    `json:"icon"`       // 图标
	ExpiryDate string    `json:"expiryDate"` // 过期日期
	ExpiryDays int       `json:"expiryDays"` // 距离过期的天数
	ExpiryText string    `json:"expiryText"` // 过期文本
	Urgent     bool      `json:"urgent"`     // 是否紧急
	CreatedAt  time.Time `json:"createdAt"`  // 创建时间
	UpdatedAt  time.Time `json:"updatedAt"`  // 更新时间
}

// ToResponse 转换为响应结构（计算过期相关字段）
// 返回: 食材响应结构
func (i *IngredientItem) ToResponse() *IngredientResponse {
	// 计算距离过期的天数
	now := time.Now().Truncate(24 * time.Hour)
	expiryDate := i.ExpiryDate.Truncate(24 * time.Hour)
	expiryDays := int(math.Ceil(expiryDate.Sub(now).Hours() / 24))

	// 生成过期文本
	var expiryText string
	switch {
	case expiryDays < 0:
		expiryText = "已过期"
	case expiryDays == 0:
		expiryText = "今天"
	case expiryDays == 1:
		expiryText = "明天"
	case expiryDays == 2:
		expiryText = "后天"
	default:
		expiryText = formatDays(expiryDays)
	}

	return &IngredientResponse{
		ID:         i.ID,
		Name:       i.Name,
		Amount:     i.Amount,
		Category:   i.Category,
		Icon:       i.Icon,
		ExpiryDate: i.ExpiryDate.Format("2006-01-02"),
		ExpiryDays: expiryDays,
		ExpiryText: expiryText,
		Urgent:     expiryDays <= 0,
		CreatedAt:  i.CreatedAt,
		UpdatedAt:  i.UpdatedAt,
	}
}

// formatDays 格式化天数文本
// days: 天数
// 返回: 格式化后的文本
func formatDays(days int) string {
	if days <= 0 {
		return "已过期"
	}
	return fmt.Sprintf("%d天后", days)
}

