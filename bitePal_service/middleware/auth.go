package middleware

import (
	"bitePal_service/config"
	"bitePal_service/models"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// 上下文键常量
const (
	ContextKeyUserID = "userID" // 用户ID上下文键
	ContextKeyUser   = "user"   // 用户信息上下文键
)

// Claims JWT声明结构
type Claims struct {
	UserID   string `json:"userId"`   // 用户ID
	Username string `json:"username"` // 用户名
	jwt.RegisteredClaims
}

// AuthMiddleware JWT认证中间件
// 验证请求头中的Token并设置用户信息到上下文
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取Authorization请求头
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, models.NewErrorResponse(
				models.CodeUnauthorized,
				"未提供认证Token",
			))
			c.Abort()
			return
		}

		// 检查Bearer前缀
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, models.NewErrorResponse(
				models.CodeUnauthorized,
				"Token格式错误，应为: Bearer {token}",
			))
			c.Abort()
			return
		}

		tokenString := parts[1]

		// 解析Token
		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(config.AppConfig.JWTSecret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, models.NewErrorResponse(
				models.CodeUnauthorized,
				"Token无效或已过期，请重新登录",
			))
			c.Abort()
			return
		}

		// 设置用户信息到上下文
		c.Set(ContextKeyUserID, claims.UserID)
		c.Set(ContextKeyUser, claims)

		c.Next()
	}
}

// GetUserIDFromContext 从上下文获取用户ID
// c: Gin上下文
// 返回: 用户ID
func GetUserIDFromContext(c *gin.Context) string {
	userID, exists := c.Get(ContextKeyUserID)
	if !exists {
		return ""
	}
	return userID.(string)
}

// GetClaimsFromContext 从上下文获取用户声明
// c: Gin上下文
// 返回: 用户声明
func GetClaimsFromContext(c *gin.Context) *Claims {
	claims, exists := c.Get(ContextKeyUser)
	if !exists {
		return nil
	}
	return claims.(*Claims)
}

