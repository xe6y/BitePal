package config

import (
	"os"
)

// 默认配置值
const (
	DefaultServerPort   = "8080"           // 默认服务端口
	DefaultDatabasePath = "./bitepal.db"   // 默认数据库路径
	DefaultJWTSecret    = "bitepal_secret" // 默认JWT密钥（生产环境请修改）
	DefaultJWTExpiry    = 168              // 默认Token有效期（小时），7天
)

// Config 应用配置结构
type Config struct {
	ServerPort   string // 服务端口
	DatabasePath string // 数据库文件路径
	JWTSecret    string // JWT密钥
	JWTExpiry    int    // JWT有效期（小时）
}

// LoadConfig 加载配置
// 优先从环境变量读取，否则使用默认值
func LoadConfig() *Config {
	return &Config{
		ServerPort:   getEnvOrDefault("SERVER_PORT", DefaultServerPort),
		DatabasePath: getEnvOrDefault("DATABASE_PATH", DefaultDatabasePath),
		JWTSecret:    getEnvOrDefault("JWT_SECRET", DefaultJWTSecret),
		JWTExpiry:    DefaultJWTExpiry,
	}
}

// getEnvOrDefault 获取环境变量，如果不存在则返回默认值
// envKey: 环境变量名
// defaultVal: 默认值
// 返回: 环境变量值或默认值
func getEnvOrDefault(envKey, defaultVal string) string {
	if value := os.Getenv(envKey); value != "" {
		return value
	}
	return defaultVal
}

// AppConfig 全局配置实例
var AppConfig *Config

// InitConfig 初始化全局配置
func InitConfig() {
	AppConfig = LoadConfig()
}

