package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// MemberPreferences 成员偏好结构
type MemberPreferences struct {
	Tastes    []string `json:"tastes"`    // 口味偏好
	Allergies []string `json:"allergies"` // 过敏食材
	Dislikes  []string `json:"dislikes"`  // 不喜欢的食材
}

// Scan 从数据库读取值
func (m *MemberPreferences) Scan(value interface{}) error {
	if value == nil {
		*m = MemberPreferences{}
		return nil
	}
	return json.Unmarshal(value.([]byte), m)
}

// Value 写入数据库的值
func (m MemberPreferences) Value() (driver.Value, error) {
	return json.Marshal(m)
}

// FamilyMember 家庭成员模型
type FamilyMember struct {
	ID          string            `json:"id" gorm:"primaryKey"`          // 成员ID
	Name        string            `json:"name"`                          // 成员名称
	Preferences MemberPreferences `json:"preferences" gorm:"type:json"`  // 偏好设置
	UserID      string            `json:"userId" gorm:"index"`           // 所属用户ID
	CreatedAt   time.Time         `json:"createdAt"`                     // 创建时间
	UpdatedAt   time.Time         `json:"updatedAt"`                     // 更新时间
	DeletedAt   gorm.DeletedAt    `json:"-" gorm:"index"`                // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (f *FamilyMember) BeforeCreate(tx *gorm.DB) error {
	if f.ID == "" {
		f.ID = uuid.New().String()
	}
	return nil
}

// FamilyMemberResponse 家庭成员响应结构
type FamilyMemberResponse struct {
	ID          string            `json:"id"`          // 成员ID
	Name        string            `json:"name"`        // 成员名称
	Preferences MemberPreferences `json:"preferences"` // 偏好设置
}

// ToResponse 转换为响应结构
// 返回: 家庭成员响应结构
func (f *FamilyMember) ToResponse() *FamilyMemberResponse {
	return &FamilyMemberResponse{
		ID:          f.ID,
		Name:        f.Name,
		Preferences: f.Preferences,
	}
}

