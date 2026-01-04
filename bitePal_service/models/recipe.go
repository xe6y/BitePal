package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// StringArray 字符串数组类型（用于GORM存储）
type StringArray []string

// Scan 从数据库读取值
func (s *StringArray) Scan(value interface{}) error {
	if value == nil {
		*s = StringArray{}
		return nil
	}
	return json.Unmarshal(value.([]byte), s)
}

// Value 写入数据库的值
func (s StringArray) Value() (driver.Value, error) {
	return json.Marshal(s)
}

// RecipeIngredient 菜谱食材结构
type RecipeIngredient struct {
	Name      string `json:"name"`      // 食材名称
	Amount    string `json:"amount"`    // 用量
	Available bool   `json:"available"` // 是否可用
}

// RecipeIngredients 菜谱食材数组类型
type RecipeIngredients []RecipeIngredient

// Scan 从数据库读取值
func (r *RecipeIngredients) Scan(value interface{}) error {
	if value == nil {
		*r = RecipeIngredients{}
		return nil
	}
	return json.Unmarshal(value.([]byte), r)
}

// Value 写入数据库的值
func (r RecipeIngredients) Value() (driver.Value, error) {
	return json.Marshal(r)
}

// Recipe 菜谱模型
type Recipe struct {
	ID          string            `json:"id" gorm:"primaryKey"`         // 菜谱ID
	Name        string            `json:"name" gorm:"not null"`         // 菜谱名称
	Image       string            `json:"image"`                        // 图片URL
	Time        string            `json:"time"`                         // 制作时间
	Difficulty  string            `json:"difficulty"`                   // 难度（简单/中等/困难）
	Tags        StringArray       `json:"tags" gorm:"type:json"`        // 标签数组
	TagColors   StringArray       `json:"tagColors" gorm:"type:json"`   // 标签颜色数组
	Favorite    bool              `json:"favorite"`                     // 是否收藏
	Categories  StringArray       `json:"categories" gorm:"type:json"`  // 分类数组
	Ingredients RecipeIngredients `json:"ingredients" gorm:"type:json"` // 食材列表
	Steps       StringArray       `json:"steps" gorm:"type:json"`       // 制作步骤
	UserID      string            `json:"userId" gorm:"index"`          // 创建用户ID
	IsPublic    bool              `json:"isPublic"`                     // 是否公开
	CreatedAt   time.Time         `json:"createdAt"`                    // 创建时间
	UpdatedAt   time.Time         `json:"updatedAt"`                    // 更新时间
	DeletedAt   gorm.DeletedAt    `json:"-" gorm:"index"`               // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (r *Recipe) BeforeCreate(tx *gorm.DB) error {
	if r.ID == "" {
		r.ID = uuid.New().String()
	}
	return nil
}

// RecipeListItem 菜谱列表项（简化版本）
type RecipeListItem struct {
	ID         string      `json:"id"`         // 菜谱ID
	Name       string      `json:"name"`       // 菜谱名称
	Image      string      `json:"image"`      // 图片URL
	Time       string      `json:"time"`       // 制作时间
	Difficulty string      `json:"difficulty"` // 难度
	Tags       StringArray `json:"tags"`       // 标签数组
	TagColors  StringArray `json:"tagColors"`  // 标签颜色数组
	Favorite   bool        `json:"favorite"`   // 是否收藏
	Categories StringArray `json:"categories"` // 分类数组
}

// ToListItem 转换为列表项
// 返回: 菜谱列表项
func (r *Recipe) ToListItem() *RecipeListItem {
	return &RecipeListItem{
		ID:         r.ID,
		Name:       r.Name,
		Image:      r.Image,
		Time:       r.Time,
		Difficulty: r.Difficulty,
		Tags:       r.Tags,
		TagColors:  r.TagColors,
		Favorite:   r.Favorite,
		Categories: r.Categories,
	}
}

// UserFavorite 用户收藏关联表
type UserFavorite struct {
	ID        string         `json:"id" gorm:"primaryKey"`  // ID
	UserID    string         `json:"userId" gorm:"index"`   // 用户ID
	RecipeID  string         `json:"recipeId" gorm:"index"` // 菜谱ID
	CreatedAt time.Time      `json:"createdAt"`             // 创建时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`        // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (uf *UserFavorite) BeforeCreate(tx *gorm.DB) error {
	if uf.ID == "" {
		uf.ID = uuid.New().String()
	}
	return nil
}
