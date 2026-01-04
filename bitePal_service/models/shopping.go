package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ShoppingItem 购物项结构
type ShoppingItem struct {
	ID      string  `json:"id"`      // 购物项ID
	Name    string  `json:"name"`    // 商品名称
	Amount  string  `json:"amount"`  // 数量
	Price   float64 `json:"price"`   // 价格
	Checked bool    `json:"checked"` // 是否已购买
}

// ShoppingItems 购物项数组类型
type ShoppingItems []ShoppingItem

// Scan 从数据库读取值
func (s *ShoppingItems) Scan(value interface{}) error {
	if value == nil {
		*s = ShoppingItems{}
		return nil
	}
	return json.Unmarshal(value.([]byte), s)
}

// Value 写入数据库的值
func (s ShoppingItems) Value() (driver.Value, error) {
	return json.Marshal(s)
}

// ShoppingList 购物清单模型
type ShoppingList struct {
	ID          string         `json:"id" gorm:"primaryKey"`      // 清单ID
	Name        string         `json:"name"`                      // 清单名称
	Items       ShoppingItems  `json:"items" gorm:"type:json"`    // 购物项列表
	TotalPrice  float64        `json:"totalPrice"`                // 总价
	UserID      string         `json:"userId" gorm:"index"`       // 用户ID
	CreatedAt   time.Time      `json:"createdAt"`                 // 创建时间
	UpdatedAt   time.Time      `json:"updatedAt"`                 // 更新时间
	CompletedAt *time.Time     `json:"completedAt"`               // 完成时间
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`            // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (s *ShoppingList) BeforeCreate(tx *gorm.DB) error {
	if s.ID == "" {
		s.ID = uuid.New().String()
	}
	return nil
}

// CalculateTotalPrice 计算总价
// 返回: 总价
func (s *ShoppingList) CalculateTotalPrice() float64 {
	var total float64
	for _, item := range s.Items {
		total += item.Price
	}
	s.TotalPrice = total
	return total
}

// AddItem 添加购物项
// item: 购物项
func (s *ShoppingList) AddItem(item ShoppingItem) {
	if item.ID == "" {
		item.ID = uuid.New().String()
	}
	s.Items = append(s.Items, item)
	s.CalculateTotalPrice()
}

// UpdateItem 更新购物项
// itemID: 购物项ID
// updatedItem: 更新后的购物项
// 返回: 是否更新成功
func (s *ShoppingList) UpdateItem(itemID string, updatedItem ShoppingItem) bool {
	for i, item := range s.Items {
		if item.ID == itemID {
			updatedItem.ID = itemID
			s.Items[i] = updatedItem
			s.CalculateTotalPrice()
			return true
		}
	}
	return false
}

// RemoveItem 移除购物项
// itemID: 购物项ID
// 返回: 是否移除成功
func (s *ShoppingList) RemoveItem(itemID string) bool {
	for i, item := range s.Items {
		if item.ID == itemID {
			s.Items = append(s.Items[:i], s.Items[i+1:]...)
			s.CalculateTotalPrice()
			return true
		}
	}
	return false
}

// ShoppingListHistoryItem 购物清单历史项
type ShoppingListHistoryItem struct {
	ID          string     `json:"id"`          // 清单ID
	Name        string     `json:"name"`        // 清单名称
	TotalPrice  float64    `json:"totalPrice"`  // 总价
	ItemCount   int        `json:"itemCount"`   // 商品数量
	CompletedAt *time.Time `json:"completedAt"` // 完成时间
}

// ToHistoryItem 转换为历史项
// 返回: 购物清单历史项
func (s *ShoppingList) ToHistoryItem() *ShoppingListHistoryItem {
	return &ShoppingListHistoryItem{
		ID:          s.ID,
		Name:        s.Name,
		TotalPrice:  s.TotalPrice,
		ItemCount:   len(s.Items),
		CompletedAt: s.CompletedAt,
	}
}

