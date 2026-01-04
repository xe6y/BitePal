package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// 点餐状态常量
const (
	OrderStatusPending   = "pending"   // 待确认
	OrderStatusConfirmed = "confirmed" // 已确认
	OrderStatusCompleted = "completed" // 已完成
)

// OrderRecipe 点餐菜谱结构
type OrderRecipe struct {
	RecipeID   string `json:"recipeId"`   // 菜谱ID
	RecipeName string `json:"recipeName"` // 菜谱名称
}

// OrderRecipes 点餐菜谱数组类型
type OrderRecipes []OrderRecipe

// Scan 从数据库读取值
func (o *OrderRecipes) Scan(value interface{}) error {
	if value == nil {
		*o = OrderRecipes{}
		return nil
	}
	return json.Unmarshal(value.([]byte), o)
}

// Value 写入数据库的值
func (o OrderRecipes) Value() (driver.Value, error) {
	return json.Marshal(o)
}

// MealOrder 点餐清单模型
type MealOrder struct {
	ID        string         `json:"id" gorm:"primaryKey"`      // 点餐ID
	Recipes   OrderRecipes   `json:"recipes" gorm:"type:json"`  // 菜谱列表
	Status    string         `json:"status" gorm:"index"`       // 状态
	UserID    string         `json:"userId" gorm:"index"`       // 用户ID
	CreatedAt time.Time      `json:"createdAt"`                 // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                 // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`            // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID和默认状态
func (m *MealOrder) BeforeCreate(tx *gorm.DB) error {
	if m.ID == "" {
		m.ID = uuid.New().String()
	}
	if m.Status == "" {
		m.Status = OrderStatusPending
	}
	return nil
}

// Confirm 确认点餐
func (m *MealOrder) Confirm() {
	m.Status = OrderStatusConfirmed
}

// Complete 完成点餐
func (m *MealOrder) Complete() {
	m.Status = OrderStatusCompleted
}

