package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// FamilyHandler 家庭管理处理器
type FamilyHandler struct{}

// NewFamilyHandler 创建家庭管理处理器实例
// 返回: 家庭管理处理器
func NewFamilyHandler() *FamilyHandler {
	return &FamilyHandler{}
}

// CreateFamilyRequest 创建家庭请求结构
type CreateFamilyRequest struct {
	Name string `json:"name" binding:"required"` // 家庭名称
}

// JoinFamilyRequest 加入家庭请求结构
type JoinFamilyRequest struct {
	InviteCode string `json:"inviteCode" binding:"required"` // 邀请码
	Nickname   string `json:"nickname"`                      // 在家庭中的昵称
}

// UpdateMemberRequest 更新成员请求结构
type UpdateMemberRequest struct {
	Nickname string `json:"nickname"` // 在家庭中的昵称
}

// GetMyFamily 获取我的家庭
// @Summary 获取我的家庭
// @Description 获取用户所属的家庭信息
// @Tags 家庭管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response{data=models.FamilyResponse}
// @Router /api/family [get]
func (h *FamilyHandler) GetMyFamily(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 查找用户所属的家庭
	var memberInfo models.FamilyMemberInfo
	if result := config.DB.Where("user_id = ?", userID).First(&memberInfo); result.Error != nil {
		// 用户没有加入任何家庭
		c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", nil))
		return
	}

	// 获取家庭信息
	var family models.Family
	if result := config.DB.First(&family, "id = ?", memberInfo.FamilyID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"家庭不存在",
		))
		return
	}

	// 获取所有成员
	var members []models.FamilyMemberInfo
	config.DB.Where("family_id = ?", family.ID).Find(&members)

	// 构建成员列表（包含用户信息）
	memberBriefs := make([]models.FamilyMemberBrief, len(members))
	for i, m := range members {
		var user models.User
		config.DB.First(&user, "id = ?", m.UserID)
		memberBriefs[i] = models.FamilyMemberBrief{
			ID:       m.ID,
			UserID:   m.UserID,
			Nickname: m.Nickname,
			Avatar:   user.Avatar,
			Role:     m.Role,
		}
	}

	response := &models.FamilyResponse{
		ID:         family.ID,
		Name:       family.Name,
		InviteCode: family.InviteCode,
		IsOwner:    family.OwnerID == userID,
		Members:    memberBriefs,
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", response))
}

// CreateFamily 创建家庭
// @Summary 创建家庭
// @Description 创建新的家庭
// @Tags 家庭管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateFamilyRequest true "家庭信息"
// @Success 200 {object} models.Response{data=models.FamilyResponse}
// @Router /api/family [post]
func (h *FamilyHandler) CreateFamily(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 检查用户是否已经有家庭
	var existingMember models.FamilyMemberInfo
	if result := config.DB.Where("user_id = ?", userID).First(&existingMember); result.Error == nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"您已经加入了一个家庭，请先退出当前家庭",
		))
		return
	}

	var req CreateFamilyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请输入家庭名称",
		))
		return
	}

	// 获取用户信息
	var user models.User
	config.DB.First(&user, "id = ?", userID)

	// 创建家庭
	family := &models.Family{
		Name:    req.Name,
		OwnerID: userID,
	}
	if result := config.DB.Create(family); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建家庭失败",
		))
		return
	}

	// 将创建者添加为家庭成员
	memberInfo := &models.FamilyMemberInfo{
		FamilyID: family.ID,
		UserID:   userID,
		Nickname: user.Nickname,
		Role:     models.FamilyRoleOwner,
	}
	config.DB.Create(memberInfo)

	// 返回家庭信息
	response := &models.FamilyResponse{
		ID:         family.ID,
		Name:       family.Name,
		InviteCode: family.InviteCode,
		IsOwner:    true,
		Members: []models.FamilyMemberBrief{
			{
				ID:       memberInfo.ID,
				UserID:   userID,
				Nickname: memberInfo.Nickname,
				Avatar:   user.Avatar,
				Role:     models.FamilyRoleOwner,
			},
		},
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("创建成功", response))
}

// JoinFamily 加入家庭
// @Summary 加入家庭
// @Description 通过邀请码加入家庭
// @Tags 家庭管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body JoinFamilyRequest true "加入信息"
// @Success 200 {object} models.Response{data=models.FamilyResponse}
// @Router /api/family/join [post]
func (h *FamilyHandler) JoinFamily(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 检查用户是否已经有家庭
	var existingMember models.FamilyMemberInfo
	if result := config.DB.Where("user_id = ?", userID).First(&existingMember); result.Error == nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"您已经加入了一个家庭，请先退出当前家庭",
		))
		return
	}

	var req JoinFamilyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请输入邀请码",
		))
		return
	}

	// 查找家庭
	var family models.Family
	if result := config.DB.Where("invite_code = ?", req.InviteCode).First(&family); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"邀请码无效",
		))
		return
	}

	// 获取用户信息
	var user models.User
	config.DB.First(&user, "id = ?", userID)

	// 使用提供的昵称或用户昵称
	nickname := req.Nickname
	if nickname == "" {
		nickname = user.Nickname
	}

	// 添加为家庭成员
	memberInfo := &models.FamilyMemberInfo{
		FamilyID: family.ID,
		UserID:   userID,
		Nickname: nickname,
		Role:     models.FamilyRoleMember,
	}
	config.DB.Create(memberInfo)

	// 获取所有成员
	var members []models.FamilyMemberInfo
	config.DB.Where("family_id = ?", family.ID).Find(&members)

	// 构建成员列表
	memberBriefs := make([]models.FamilyMemberBrief, len(members))
	for i, m := range members {
		var u models.User
		config.DB.First(&u, "id = ?", m.UserID)
		memberBriefs[i] = models.FamilyMemberBrief{
			ID:       m.ID,
			UserID:   m.UserID,
			Nickname: m.Nickname,
			Avatar:   u.Avatar,
			Role:     m.Role,
		}
	}

	response := &models.FamilyResponse{
		ID:         family.ID,
		Name:       family.Name,
		InviteCode: family.InviteCode,
		IsOwner:    false,
		Members:    memberBriefs,
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("加入成功", response))
}

// LeaveFamily 退出家庭
// @Summary 退出家庭
// @Description 退出当前家庭
// @Tags 家庭管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response
// @Router /api/family/leave [post]
func (h *FamilyHandler) LeaveFamily(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 查找用户所属的家庭
	var memberInfo models.FamilyMemberInfo
	if result := config.DB.Where("user_id = ?", userID).First(&memberInfo); result.Error != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"您没有加入任何家庭",
		))
		return
	}

	// 获取家庭信息
	var family models.Family
	config.DB.First(&family, "id = ?", memberInfo.FamilyID)

	// 如果是创建者，检查是否还有其他成员
	if family.OwnerID == userID {
		var count int64
		config.DB.Model(&models.FamilyMemberInfo{}).Where("family_id = ?", family.ID).Count(&count)
		if count > 1 {
			c.JSON(http.StatusBadRequest, models.NewErrorResponse(
				models.CodeBadRequest,
				"您是家庭创建者，请先移除其他成员或转让家庭",
			))
			return
		}
		// 删除家庭
		config.DB.Delete(&family)
	}

	// 删除成员记录
	config.DB.Delete(&memberInfo)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("退出成功", nil))
}

// RemoveMember 移除成员
// @Summary 移除成员
// @Description 移除家庭成员（仅创建者可操作）
// @Tags 家庭管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param memberId path string true "成员ID"
// @Success 200 {object} models.Response
// @Router /api/family/members/{memberId} [delete]
func (h *FamilyHandler) RemoveMember(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	memberID := c.Param("memberId")

	// 查找用户所属的家庭
	var myMemberInfo models.FamilyMemberInfo
	if result := config.DB.Where("user_id = ?", userID).First(&myMemberInfo); result.Error != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"您没有加入任何家庭",
		))
		return
	}

	// 验证是否为创建者
	var family models.Family
	config.DB.First(&family, "id = ?", myMemberInfo.FamilyID)
	if family.OwnerID != userID {
		c.JSON(http.StatusForbidden, models.NewErrorResponse(
			models.CodeForbidden,
			"只有家庭创建者才能移除成员",
		))
		return
	}

	// 查找要移除的成员
	var targetMember models.FamilyMemberInfo
	if result := config.DB.Where("id = ? AND family_id = ?", memberID, family.ID).First(&targetMember); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"成员不存在",
		))
		return
	}

	// 不能移除自己
	if targetMember.UserID == userID {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"不能移除自己",
		))
		return
	}

	// 删除成员
	config.DB.Delete(&targetMember)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("移除成功", nil))
}

// UpdateMember 更新成员信息
// @Summary 更新成员信息
// @Description 更新家庭成员的昵称等信息
// @Tags 家庭管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param memberId path string true "成员ID"
// @Param request body UpdateMemberRequest true "成员信息"
// @Success 200 {object} models.Response
// @Router /api/family/members/{memberId} [put]
func (h *FamilyHandler) UpdateMember(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	memberID := c.Param("memberId")

	// 查找用户所属的家庭
	var myMemberInfo models.FamilyMemberInfo
	if result := config.DB.Where("user_id = ?", userID).First(&myMemberInfo); result.Error != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"您没有加入任何家庭",
		))
		return
	}

	// 查找要更新的成员（只能更新自己，或者创建者可以更新任何人）
	var targetMember models.FamilyMemberInfo
	if result := config.DB.Where("id = ? AND family_id = ?", memberID, myMemberInfo.FamilyID).First(&targetMember); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"成员不存在",
		))
		return
	}

	// 获取家庭信息
	var family models.Family
	config.DB.First(&family, "id = ?", myMemberInfo.FamilyID)

	// 检查权限
	if targetMember.UserID != userID && family.OwnerID != userID {
		c.JSON(http.StatusForbidden, models.NewErrorResponse(
			models.CodeForbidden,
			"无权限修改此成员信息",
		))
		return
	}

	var req UpdateMemberRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 更新成员信息
	if req.Nickname != "" {
		config.DB.Model(&targetMember).Update("nickname", req.Nickname)
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", nil))
}

// RefreshInviteCode 刷新邀请码
// @Summary 刷新邀请码
// @Description 生成新的邀请码（仅创建者可操作）
// @Tags 家庭管理
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response{data=object}
// @Router /api/family/invite-code [post]
func (h *FamilyHandler) RefreshInviteCode(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	// 查找用户所属的家庭
	var memberInfo models.FamilyMemberInfo
	if result := config.DB.Where("user_id = ?", userID).First(&memberInfo); result.Error != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"您没有加入任何家庭",
		))
		return
	}

	// 获取家庭信息
	var family models.Family
	config.DB.First(&family, "id = ?", memberInfo.FamilyID)

	// 验证是否为创建者
	if family.OwnerID != userID {
		c.JSON(http.StatusForbidden, models.NewErrorResponse(
			models.CodeForbidden,
			"只有家庭创建者才能刷新邀请码",
		))
		return
	}

	// 生成新邀请码
	newCode := family.ID[:6] // 简单实现，实际应该用随机生成
	config.DB.Model(&family).Update("invite_code", newCode)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("刷新成功", gin.H{
		"inviteCode": newCode,
	}))
}

