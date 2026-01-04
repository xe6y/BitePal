package middleware

import (
	"github.com/gin-gonic/gin"
)

// CORSMiddleware 跨域请求中间件
// 允许跨域请求访问API
func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 设置允许的来源（生产环境应该限制具体域名）
		c.Header("Access-Control-Allow-Origin", "*")
		// 设置允许的请求方法
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		// 设置允许的请求头
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept")
		// 设置允许暴露的响应头
		c.Header("Access-Control-Expose-Headers", "Content-Length")
		// 设置预检请求的缓存时间（秒）
		c.Header("Access-Control-Max-Age", "86400")

		// 处理预检请求
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

