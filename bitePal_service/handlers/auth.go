package handlers

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"bitePal_service/models"
	"bitePal_service/utils"
	"net/http"

	"github.com/gin-gonic/gin"
)

// AuthHandler 认证处理器
type AuthHandler struct{}

// NewAuthHandler 创建认证处理器实例
// 返回: 认证处理器
func NewAuthHandler() *AuthHandler {
	return &AuthHandler{}
}

// LoginRequest 登录请求结构
type LoginRequest struct {
	Username string `json:"username" binding:"required"` // 用户名或手机号
	Password string `json:"password" binding:"required"` // 密码
}

// RegisterRequest 注册请求结构
type RegisterRequest struct {
	Username string `json:"username" binding:"required"` // 用户名
	Password string `json:"password" binding:"required"` // 密码
	Nickname string `json:"nickname"`                    // 昵称（可选）
	Phone    string `json:"phone"`                       // 手机号（可选）
}

// LoginResponse 登录响应结构
type LoginResponse struct {
	Token string               `json:"token"` // JWT Token
	User  *models.UserResponse `json:"user"`  // 用户信息
}

// Login 用户登录
// @Summary 用户登录
// @Description 通过用户名和密码登录，返回JWT Token
// @Tags 认证
// @Accept json
// @Produce json
// @Param request body LoginRequest true "登录请求"
// @Success 200 {object} models.Response{data=LoginResponse}
// @Failure 400 {object} models.Response
// @Failure 401 {object} models.Response
// @Router /api/auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：用户名和密码不能为空",
		))
		return
	}

	// 查询用户
	var user models.User
	result := config.DB.Where("username = ? OR phone = ?", req.Username, req.Username).First(&user)
	if result.Error != nil {
		c.JSON(http.StatusUnauthorized, models.NewErrorResponse(
			models.CodeUnauthorized,
			"用户名或密码错误",
		))
		return
	}

	// 验证密码
	if !utils.CheckPassword(req.Password, user.Password) {
		c.JSON(http.StatusUnauthorized, models.NewErrorResponse(
			models.CodeUnauthorized,
			"用户名或密码错误",
		))
		return
	}

	// 生成Token
	token, err := utils.GenerateToken(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"Token生成失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("登录成功", &LoginResponse{
		Token: token,
		User:  user.ToResponse(),
	}))
}

// Register 用户注册
// @Summary 用户注册
// @Description 注册新用户，返回JWT Token
// @Tags 认证
// @Accept json
// @Produce json
// @Param request body RegisterRequest true "注册请求"
// @Success 200 {object} models.Response{data=LoginResponse}
// @Failure 400 {object} models.Response
// @Router /api/auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数错误：用户名和密码不能为空",
		))
		return
	}

	// 检查用户名是否已存在
	var existingUser models.User
	if result := config.DB.Where("username = ?", req.Username).First(&existingUser); result.Error == nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"用户名已存在",
		))
		return
	}

	// 加密密码
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"密码加密失败",
		))
		return
	}

	// 创建用户
	user := &models.User{
		Username: req.Username,
		Password: hashedPassword,
		Nickname: req.Nickname,
		Phone:    req.Phone,
	}

	// 如果没有设置昵称，使用用户名作为昵称
	if user.Nickname == "" {
		user.Nickname = user.Username
	}

	if result := config.DB.Create(user); result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"用户创建失败",
		))
		return
	}

	// 生成Token
	token, err := utils.GenerateToken(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"Token生成失败",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("注册成功", &LoginResponse{
		Token: token,
		User:  user.ToResponse(),
	}))
}

// GetUserInfo 获取用户信息
// @Summary 获取用户信息
// @Description 获取当前登录用户的信息
// @Tags 用户
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.Response{data=models.UserResponse}
// @Failure 401 {object} models.Response
// @Router /api/user/info [get]
func (h *AuthHandler) GetUserInfo(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var user models.User
	if result := config.DB.First(&user, "id = ?", userID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"用户不存在",
		))
		return
	}

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("获取成功", user.ToResponse()))
}

// UpdateUserInfoRequest 更新用户信息请求结构
type UpdateUserInfoRequest struct {
	Nickname string `json:"nickname"` // 新昵称（可选）
	Avatar   string `json:"avatar"`   // 新头像URL（可选）
}

// UpdateUserInfo 更新用户信息
// @Summary 更新用户信息
// @Description 更新当前登录用户的信息
// @Tags 用户
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body UpdateUserInfoRequest true "更新请求"
// @Success 200 {object} models.Response{data=models.UserResponse}
// @Failure 401 {object} models.Response
// @Router /api/user/info [put]
func (h *AuthHandler) UpdateUserInfo(c *gin.Context) {
	userID := middleware.GetUserIDFromContext(c)

	var req UpdateUserInfoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请求参数格式错误",
		))
		return
	}

	var user models.User
	if result := config.DB.First(&user, "id = ?", userID); result.Error != nil {
		c.JSON(http.StatusNotFound, models.NewErrorResponse(
			models.CodeNotFound,
			"用户不存在",
		))
		return
	}

	// 更新字段
	updates := make(map[string]interface{})
	if req.Nickname != "" {
		updates["nickname"] = req.Nickname
	}
	if req.Avatar != "" {
		updates["avatar"] = req.Avatar
	}

	if len(updates) > 0 {
		if result := config.DB.Model(&user).Updates(updates); result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
				models.CodeServerError,
				"更新失败",
			))
			return
		}
	}

	// 重新获取用户信息
	config.DB.First(&user, "id = ?", userID)

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("更新成功", user.ToResponse()))
}

