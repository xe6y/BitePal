package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID        string         `json:"id" gorm:"primaryKey"`                  // 用户ID
	Username  string         `json:"username" gorm:"uniqueIndex;not null"`  // 用户名
	Password  string         `json:"-" gorm:"not null"`                     // 密码（JSON不返回）
	Nickname  string         `json:"nickname"`                              // 昵称
	Avatar    string         `json:"avatar"`                                // 头像URL
	UserID    string         `json:"userId" gorm:"uniqueIndex"`             // 用户唯一标识
	Phone     string         `json:"phone"`                                 // 手机号
	CreatedAt time.Time      `json:"createdAt"`                             // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                             // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`                        // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == "" {
		u.ID = uuid.New().String()
	}
	if u.UserID == "" {
		// 生成用户唯一标识，格式：COOK_年份_序号
		u.UserID = "COOK_" + time.Now().Format("2006") + "_" + uuid.New().String()[:8]
	}
	return nil
}

// UserResponse 用户响应结构（不包含敏感信息）
type UserResponse struct {
	ID       string `json:"id"`       // 用户ID
	Username string `json:"username"` // 用户名
	Nickname string `json:"nickname"` // 昵称
	Avatar   string `json:"avatar"`   // 头像URL
	UserID   string `json:"userId"`   // 用户唯一标识
}

// ToResponse 转换为响应结构
// 返回: 用户响应结构
func (u *User) ToResponse() *UserResponse {
	return &UserResponse{
		ID:       u.ID,
		Username: u.Username,
		Nickname: u.Nickname,
		Avatar:   u.Avatar,
		UserID:   u.UserID,
	}
}

