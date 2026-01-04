package utils

import (
	"golang.org/x/crypto/bcrypt"
)

// 密码哈希成本（越高越安全但越慢）
const bcryptCost = 10

// HashPassword 对密码进行哈希加密
// password: 明文密码
// 返回: 哈希后的密码, 错误信息
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	return string(bytes), err
}

// CheckPassword 验证密码是否正确
// password: 明文密码
// hash: 哈希后的密码
// 返回: 是否匹配
func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

