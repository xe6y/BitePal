package utils

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

// 分页默认值常量
const (
	DefaultPage     = 1   // 默认页码
	DefaultPageSize = 20  // 默认每页数量
	MaxPageSize     = 100 // 最大每页数量
)

// Pagination 分页参数结构
type Pagination struct {
	Page     int // 当前页码
	PageSize int // 每页数量
	Offset   int // 偏移量
}

// GetPagination 从请求中获取分页参数
// c: Gin上下文
// 返回: 分页参数结构
func GetPagination(c *gin.Context) *Pagination {
	// 获取页码
	page, err := strconv.Atoi(c.DefaultQuery("page", strconv.Itoa(DefaultPage)))
	if err != nil || page < 1 {
		page = DefaultPage
	}

	// 获取每页数量
	pageSize, err := strconv.Atoi(c.DefaultQuery("pageSize", strconv.Itoa(DefaultPageSize)))
	if err != nil || pageSize < 1 {
		pageSize = DefaultPageSize
	}

	// 限制最大每页数量
	if pageSize > MaxPageSize {
		pageSize = MaxPageSize
	}

	// 计算偏移量
	offset := (page - 1) * pageSize

	return &Pagination{
		Page:     page,
		PageSize: pageSize,
		Offset:   offset,
	}
}

