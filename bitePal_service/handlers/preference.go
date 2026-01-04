package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// PreferenceHandler 偏好设置处理器
type PreferenceHandler struct{}

// NewPreferenceHandler 创建偏好设置处理器实例
// 返回: 偏好设置处理器
func NewPreferenceHandler() *PreferenceHandler {
	return &PreferenceHandler{}
}

// FamilyMemberRequest 家庭成员请求结构
type FamilyMemberRequest struct {
	ID          string                   `json:"id"`          // 成员ID（更新时必填）
	Name        string                   `json:"name"`        // 成员名称
	Preferences models.MemberPreferences `json:"preferences"` // 偏好设置
}

// UpdatePreferencesRequest 更新偏好设置请求结构
type UpdatePreferencesRequest struct {
	FamilyMembers []FamilyMemberRequest `json:"familyMembers"` // 家庭成员列表
}

// GetPreferences 获取家庭成员偏好
// @Summary 获取家庭成员偏好
// @Description 获取用户的家庭成员偏好设置
// @Tags 家庭成员偏好
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response{data=object}
// @Router /api/user/preferences [get]
func (h *PreferenceHandler) GetPreferences(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var members []models.FamilyMember
	config.DB.Where("user_id = ?", userID).Find(&members)

	// 转换为响应结构
	memberResponses := make([]*models.FamilyMemberResponse, len(members))
	for i, member := range members {
		memberResponses[i] = member.ToResponse()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", gin.H{
		"familyMembers": memberResponses,
	}))
}

// UpdatePreferences 更新家庭成员偏好
// @Summary 更新家庭成员偏好
// @Description 更新用户的家庭成员偏好设置
// @Tags 家庭成员偏好
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body UpdatePreferencesRequest true "偏好设置"
// @Success 200 {object} models.Response{data=object}
// @Router /api/user/preferences [put]
func (h *PreferenceHandler) UpdatePreferences(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req UpdatePreferencesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	// 处理每个家庭成员
	for _, memberReq := range req.FamilyMembers {
		if memberReq.ID != "" {
			// 更新现有成员
			var member models.FamilyMember
			if result := config.DB.Where("id = ? AND user_id = ?", memberReq.ID, userID).First(&member); result.Error == nil {
				config.DB.Model(&member).Updates(map[string]interface{}{
					"name":        memberReq.Name,
					"preferences": memberReq.Preferences,
				})
			}
		} else {
			// 创建新成员
			member := &models.FamilyMember{
				Name:        memberReq.Name,
				Preferences: memberReq.Preferences,
				UserID:      userID,
			}
			config.DB.Create(member)
		}
	}

	// 获取更新后的列表
	var members []models.FamilyMember
	config.DB.Where("user_id = ?", userID).Find(&members)

	memberResponses := make([]*models.FamilyMemberResponse, len(members))
	for i, member := range members {
		memberResponses[i] = member.ToResponse()
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", gin.H{
		"familyMembers": memberResponses,
	}))
}

// DeleteFamilyMember 删除家庭成员
// @Summary 删除家庭成员
// @Description 删除指定的家庭成员
// @Tags 家庭成员偏好
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param memberId path string true "成员ID"
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Router /api/user/preferences/{memberId} [delete]
func (h *PreferenceHandler) DeleteFamilyMember(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)
	memberID := c.Param("memberId")

	var member models.FamilyMember
	if result := config.DB.Where("id = ? AND user_id = ?", memberID, userID).First(&member); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"家庭成员不存在",
		))
		return
	}

	config.DB.Delete(&member)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("删除成功", nil))
}

