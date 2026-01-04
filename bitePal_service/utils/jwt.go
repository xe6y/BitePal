package utils

import (
	"bitePal_service/config"
	"bitePal_service/middleware"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// GenerateToken 生成JWT Token
// userID: 用户ID
// username: 用户名
// 返回: Token字符串, 错误信息
func GenerateToken(userID, username string) (string, error) {
	// 计算过期时间
	expirationTime := time.Now().Add(time.Duration(config.AppConfig.JWTExpiry) * time.Hour)

	// 创建声明
	claims := &middleware.Claims{
		UserID:   userID,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "bitepal",
		},
	}

	// 生成Token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// 签名Token
	tokenString, err := token.SignedString([]byte(config.AppConfig.JWTSecret))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// ParseToken 解析JWT Token
// tokenString: Token字符串
// 返回: 声明结构, 错误信息
func ParseToken(tokenString string) (*middleware.Claims, error) {
	claims := &middleware.Claims{}

	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.AppConfig.JWTSecret), nil
	})

	if err != nil || !token.Valid {
		return nil, err
	}

	return claims, nil
}

