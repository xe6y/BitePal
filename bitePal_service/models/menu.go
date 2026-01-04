package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// 餐点类型常量
const (
	MealTypeBreakfast = "早餐" // 早餐
	MealTypeLunch     = "午餐" // 午餐
	MealTypeDinner    = "晚餐" // 晚餐
	MealTypeSnack     = "夜宵" // 夜宵
)

// MenuRecipe 菜单菜谱结构
type MenuRecipe struct {
	RecipeID   string `json:"recipeId"`   // 菜谱ID
	RecipeName string `json:"recipeName"` // 菜谱名称
	MealType   string `json:"mealType"`   // 餐点类型
}

// MenuRecipes 菜单菜谱数组类型
type MenuRecipes []MenuRecipe

// Scan 从数据库读取值
func (m *MenuRecipes) Scan(value interface{}) error {
	if value == nil {
		*m = MenuRecipes{}
		return nil
	}
	return json.Unmarshal(value.([]byte), m)
}

// Value 写入数据库的值
func (m MenuRecipes) Value() (driver.Value, error) {
	return json.Marshal(m)
}

// TodayMenu 今日菜单模型
type TodayMenu struct {
	ID        string         `json:"id" gorm:"primaryKey"`      // 菜单ID
	Date      string         `json:"date" gorm:"index"`         // 日期（YYYY-MM-DD）
	Recipes   MenuRecipes    `json:"recipes" gorm:"type:json"`  // 菜谱列表
	UserID    string         `json:"userId" gorm:"index"`       // 用户ID
	CreatedAt time.Time      `json:"createdAt"`                 // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                 // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`            // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (t *TodayMenu) BeforeCreate(tx *gorm.DB) error {
	if t.ID == "" {
		t.ID = uuid.New().String()
	}
	return nil
}

// AddRecipe 添加菜谱到菜单
// recipe: 菜谱信息
func (t *TodayMenu) AddRecipe(recipe MenuRecipe) {
	// 检查是否已存在
	for _, r := range t.Recipes {
		if r.RecipeID == recipe.RecipeID {
			return
		}
	}
	t.Recipes = append(t.Recipes, recipe)
}

// RemoveRecipe 从菜单移除菜谱
// recipeID: 菜谱ID
// 返回: 是否移除成功
func (t *TodayMenu) RemoveRecipe(recipeID string) bool {
	for i, r := range t.Recipes {
		if r.RecipeID == recipeID {
			t.Recipes = append(t.Recipes[:i], t.Recipes[i+1:]...)
			return true
		}
	}
	return false
}

