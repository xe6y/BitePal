package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Family 家庭模型
type Family struct {
	ID        string         `json:"id" gorm:"primaryKey"`      // 家庭ID
	Name      string         `json:"name"`                      // 家庭名称
	InviteCode string        `json:"inviteCode" gorm:"uniqueIndex"` // 邀请码
	OwnerID   string         `json:"ownerId" gorm:"index"`      // 创建者ID
	CreatedAt time.Time      `json:"createdAt"`                 // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                 // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`            // 软删除时间
}

// BeforeCreate 创建前钩子，自动生成ID和邀请码
func (f *Family) BeforeCreate(tx *gorm.DB) error {
	if f.ID == "" {
		f.ID = uuid.New().String()
	}
	if f.InviteCode == "" {
		// 生成6位邀请码
		f.InviteCode = uuid.New().String()[:6]
	}
	return nil
}

// FamilyMemberInfo 家庭成员信息（关联用户）
type FamilyMemberInfo struct {
	ID        string         `json:"id" gorm:"primaryKey"`      // 成员ID
	FamilyID  string         `json:"familyId" gorm:"index"`     // 家庭ID
	UserID    string         `json:"userId" gorm:"uniqueIndex"` // 用户ID
	Nickname  string         `json:"nickname"`                  // 在家庭中的昵称
	Role      string         `json:"role"`                      // 角色：owner/member
	JoinedAt  time.Time      `json:"joinedAt"`                  // 加入时间
	CreatedAt time.Time      `json:"createdAt"`                 // 创建时间
	UpdatedAt time.Time      `json:"updatedAt"`                 // 更新时间
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`            // 软删除时间
}

// 家庭角色常量
const (
	FamilyRoleOwner  = "owner"  // 创建者
	FamilyRoleMember = "member" // 成员
)

// BeforeCreate 创建前钩子，自动生成ID
func (fm *FamilyMemberInfo) BeforeCreate(tx *gorm.DB) error {
	if fm.ID == "" {
		fm.ID = uuid.New().String()
	}
	if fm.JoinedAt.IsZero() {
		fm.JoinedAt = time.Now()
	}
	return nil
}

// FamilyResponse 家庭响应结构
type FamilyResponse struct {
	ID         string              `json:"id"`         // 家庭ID
	Name       string              `json:"name"`       // 家庭名称
	InviteCode string              `json:"inviteCode"` // 邀请码
	IsOwner    bool                `json:"isOwner"`    // 是否为创建者
	Members    []FamilyMemberBrief `json:"members"`    // 成员列表
}

// FamilyMemberBrief 家庭成员简要信息
type FamilyMemberBrief struct {
	ID       string `json:"id"`       // 成员ID
	UserID   string `json:"userId"`   // 用户ID
	Nickname string `json:"nickname"` // 昵称
	Avatar   string `json:"avatar"`   // 头像
	Role     string `json:"role"`     // 角色
}

