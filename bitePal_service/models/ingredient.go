package models

import (
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// 食材存储分类常量（存放位置）
const (
	StorageRoom    = "room"    // 常温
	StorageFridge  = "fridge"  // 冷藏
	StorageFreezer = "freezer" // 冷冻
)

// 默认食材类型分类常量
const (
	IngredientTypeMeat      = "meat"      // 肉类
	IngredientTypeVegetable = "vegetable" // 蔬菜
	IngredientTypeFruit     = "fruit"     // 水果
	IngredientTypeSeafood   = "seafood"   // 海鲜
	IngredientTypeDairy     = "dairy"     // 奶制品
	IngredientTypeGrain     = "grain"     // 谷物
	IngredientTypeSeasoning = "seasoning" // 调味料
	IngredientTypeOther     = "other"     // 其他
)

// IngredientCategory 食材分类模型
type IngredientCategory struct {
	ID        string         `json:"id" gorm:"primaryKey"`          // 分类ID
	Name      string         `json:"name" gorm:"not null"`          // 分类名称
	Icon      string         `json:"icon"`                          // 分类图标（emoji）
	Color     string         `json:"color"`                         // 分类颜色
	SortOrder int            `json:"sortOrder" gorm:"default:0"`    // 排序顺序
	IsSystem  bool           `json:"isSystem" gorm:"default:false"` // 是否为系统预设分类
	UserID    string         `json:"userId" gorm:"index"`           // 用户ID（系统分类为空）
	CreatedAt time.Time      `json:"createdAt"`                     // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                     // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`                // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (c *IngredientCategory) BeforeCreate(tx *gorm.DB) error {
	if c.ID == "" {
		c.ID = uuid.New().String()
	}
	return nil
}

// IngredientItem 食材库存模型
type IngredientItem struct {
	ID           string         `json:"id" gorm:"primaryKey"`    // 食材ID
	Name         string         `json:"name" gorm:"not null"`    // 食材名称
	Quantity     float64        `json:"quantity"`                // 数量数值
	Unit         string         `json:"unit"`                    // 单位（个、斤、克、毫升等）
	Amount       string         `json:"amount"`                  // 数量描述（兼容旧版本，如：2个）
	Storage      string         `json:"storage"`                 // 存储位置（room/fridge/freezer）
	CategoryID   string         `json:"categoryId" gorm:"index"` // 食材类型分类ID
	Thumbnail    string         `json:"thumbnail"`               // 缩略图URL
	Icon         string         `json:"icon"`                    // 图标（emoji，兼容旧版本）
	Note         string         `json:"note"`                    // 备注
	BatchID      string         `json:"batchId" gorm:"index"`    // 批次ID（用于区分同一食材不同批次）
	ExpiryDate   time.Time      `json:"expiryDate"`              // 过期日期
	PurchaseDate time.Time      `json:"purchaseDate"`            // 购买日期
	UserID       string         `json:"userId" gorm:"index"`     // 用户ID
	CreatedAt    time.Time      `json:"createdAt"`               // 创建时间
	UpdatedAt    time.Time      `json:"updatedAt"`               // 更新时间
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`          // 软删除时间

	// 关联关系
	Category *IngredientCategory `json:"category,omitempty" gorm:"foreignKey:CategoryID"` // 所属分类
}

// BeforeCreate 创建前钩子，自动生成ID和批次ID
func (i *IngredientItem) BeforeCreate(tx *gorm.DB) error {
	if i.ID == "" {
		i.ID = uuid.New().String()
	}
	if i.BatchID == "" {
		i.BatchID = uuid.New().String()
	}
	return nil
}

// IngredientResponse 食材响应结构（包含计算字段）
type IngredientResponse struct {
	ID           string                  `json:"id"`                 // 食材ID
	Name         string                  `json:"name"`               // 食材名称
	Quantity     float64                 `json:"quantity"`           // 数量数值
	Unit         string                  `json:"unit"`               // 单位
	Amount       string                  `json:"amount"`             // 数量描述
	Storage      string                  `json:"storage"`            // 存储位置
	CategoryID   string                  `json:"categoryId"`         // 食材类型分类ID
	CategoryName string                  `json:"categoryName"`       // 分类名称
	Thumbnail    string                  `json:"thumbnail"`          // 缩略图URL
	Icon         string                  `json:"icon"`               // 图标
	Note         string                  `json:"note"`               // 备注
	BatchID      string                  `json:"batchId"`            // 批次ID
	ExpiryDate   string                  `json:"expiryDate"`         // 过期日期
	ExpiryDays   int                     `json:"expiryDays"`         // 距离过期的天数
	ExpiryText   string                  `json:"expiryText"`         // 过期文本
	Urgent       bool                    `json:"urgent"`             // 是否紧急
	PurchaseDate string                  `json:"purchaseDate"`       // 购买日期
	CreatedAt    time.Time               `json:"createdAt"`          // 创建时间
	UpdatedAt    time.Time               `json:"updatedAt"`          // 更新时间
	Category     *IngredientCategoryResp `json:"category,omitempty"` // 分类详情
}

// IngredientCategoryResp 食材分类响应结构
type IngredientCategoryResp struct {
	ID        string `json:"id"`        // 分类ID
	Name      string `json:"name"`      // 分类名称
	Icon      string `json:"icon"`      // 分类图标
	Color     string `json:"color"`     // 分类颜色
	SortOrder int    `json:"sortOrder"` // 排序顺序
	IsSystem  bool   `json:"isSystem"`  // 是否为系统预设分类
}

// IngredientGroupResponse 按分类分组的食材响应结构
type IngredientGroupResponse struct {
	Category    *IngredientCategoryResp `json:"category"`    // 分类信息
	Ingredients []*IngredientResponse   `json:"ingredients"` // 该分类下的食材列表
	Count       int                     `json:"count"`       // 该分类下的食材数量
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

	// 构建响应
	resp := &IngredientResponse{
		ID:         i.ID,
		Name:       i.Name,
		Quantity:   i.Quantity,
		Unit:       i.Unit,
		Amount:     i.Amount,
		Storage:    i.Storage,
		CategoryID: i.CategoryID,
		Thumbnail:  i.Thumbnail,
		Icon:       i.Icon,
		Note:       i.Note,
		BatchID:    i.BatchID,
		ExpiryDate: i.ExpiryDate.Format("2006-01-02"),
		ExpiryDays: expiryDays,
		ExpiryText: expiryText,
		Urgent:     expiryDays <= 0,
		CreatedAt:  i.CreatedAt,
		UpdatedAt:  i.UpdatedAt,
	}

	// 如果购买日期不为零值，则格式化
	if !i.PurchaseDate.IsZero() {
		resp.PurchaseDate = i.PurchaseDate.Format("2006-01-02")
	}

	// 处理分类信息
	if i.Category != nil {
		resp.CategoryName = i.Category.Name
		resp.Category = &IngredientCategoryResp{
			ID:        i.Category.ID,
			Name:      i.Category.Name,
			Icon:      i.Category.Icon,
			Color:     i.Category.Color,
			SortOrder: i.Category.SortOrder,
			IsSystem:  i.Category.IsSystem,
		}
	}

	return resp
}

// ToCategoryResp 转换为分类响应结构
func (c *IngredientCategory) ToCategoryResp() *IngredientCategoryResp {
	return &IngredientCategoryResp{
		ID:        c.ID,
		Name:      c.Name,
		Icon:      c.Icon,
		Color:     c.Color,
		SortOrder: c.SortOrder,
		IsSystem:  c.IsSystem,
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

// GetDefaultCategories 获取默认的系统分类列表
// 返回: 默认分类列表
func GetDefaultCategories() []*IngredientCategory {
	return []*IngredientCategory{
		{ID: "cat_meat", Name: "肉类", Icon: "🥩", Color: "#E53935", SortOrder: 1, IsSystem: true},
		{ID: "cat_vegetable", Name: "蔬菜", Icon: "🥬", Color: "#43A047", SortOrder: 2, IsSystem: true},
		{ID: "cat_fruit", Name: "水果", Icon: "🍎", Color: "#FB8C00", SortOrder: 3, IsSystem: true},
		{ID: "cat_seafood", Name: "海鲜", Icon: "🦐", Color: "#039BE5", SortOrder: 4, IsSystem: true},
		{ID: "cat_dairy", Name: "奶制品", Icon: "🥛", Color: "#FDD835", SortOrder: 5, IsSystem: true},
		{ID: "cat_grain", Name: "谷物", Icon: "🌾", Color: "#8D6E63", SortOrder: 6, IsSystem: true},
		{ID: "cat_egg", Name: "蛋类", Icon: "🥚", Color: "#FFB74D", SortOrder: 7, IsSystem: true},
		{ID: "cat_seasoning", Name: "调味料", Icon: "🧂", Color: "#78909C", SortOrder: 8, IsSystem: true},
		{ID: "cat_other", Name: "其他", Icon: "📦", Color: "#9E9E9E", SortOrder: 99, IsSystem: true},
	}
}
