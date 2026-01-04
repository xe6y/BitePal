package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// CategoryType 分类类型
type CategoryType string

const (
	// CategoryTypeTaste 口味分类
	CategoryTypeTaste CategoryType = "taste"
	// CategoryTypeCuisine 菜系分类
	CategoryTypeCuisine CategoryType = "cuisine"
	// CategoryTypeDifficulty 难度分类
	CategoryTypeDifficulty CategoryType = "difficulty"
	// CategoryTypeMealType 餐点类型分类
	CategoryTypeMealType CategoryType = "meal_type"
)

// RecipeCategory 菜谱分类配置
type RecipeCategory struct {
	ID        string       `json:"id" gorm:"primaryKey"`       // 分类ID
	Type      CategoryType `json:"type" gorm:"not null;index"` // 分类类型（taste/cuisine/difficulty/meal_type）
	Name      string       `json:"name" gorm:"not null"`       // 分类名称
	Color     string       `json:"color"`                      // 显示颜色（可选）
	Icon      string       `json:"icon"`                       // 图标（可选）
	SortOrder int          `json:"sortOrder" gorm:"default:0"` // 排序顺序
	IsActive  bool         `json:"isActive" gorm:"default:1"`  // 是否启用
	CreatedAt time.Time    `json:"createdAt"`                  // 创建时间
	UpdatedAt time.Time    `json:"updatedAt"`                  // 更新时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (rc *RecipeCategory) BeforeCreate(tx *gorm.DB) error {
	if rc.ID == "" {
		rc.ID = uuid.New().String()
	}
	return nil
}

// TableName 指定表名
func (RecipeCategory) TableName() string {
	return "recipe_categories"
}
