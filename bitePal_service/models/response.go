package models

// 响应状态码常量
const (
	CodeSuccess       = 200 // 成功
	CodeBadRequest    = 400 // 请求参数错误
	CodeUnauthorized  = 401 // 未授权
	CodeForbidden     = 403 // 无权限
	CodeNotFound      = 404 // 资源不存在
	CodeValidation    = 422 // 数据验证失败
	CodeTooMany       = 429 // 请求频率过高
	CodeServerError   = 500 // 服务器内部错误
	CodeUnavailable   = 503 // 服务不可用
)

// Response 通用响应结构
type Response struct {
	Code    int         `json:"code"`    // 响应状态码
	Message string      `json:"message"` // 响应消息
	Data    interface{} `json:"data"`    // 响应数据
}

// ErrorResponse 错误响应结构（包含详细错误）
type ErrorResponse struct {
	Code    int           `json:"code"`           // 响应状态码
	Message string        `json:"message"`        // 响应消息
	Data    interface{}   `json:"data"`           // 响应数据（通常为nil）
	Errors  []FieldError  `json:"errors,omitempty"` // 字段错误列表
}

// FieldError 字段错误结构
type FieldError struct {
	Field   string `json:"field"`   // 字段名
	Message string `json:"message"` // 错误信息
}

// NewSuccessResponse 创建成功响应
// data: 响应数据
// 返回: 响应结构
func NewSuccessResponse(data interface{}) *Response {
	return &Response{
		Code:    CodeSuccess,
		Message: "操作成功",
		Data:    data,
	}
}

// NewSuccessResponseWithMessage 创建带消息的成功响应
// message: 响应消息
// data: 响应数据
// 返回: 响应结构
func NewSuccessResponseWithMessage(message string, data interface{}) *Response {
	return &Response{
		Code:    CodeSuccess,
		Message: message,
		Data:    data,
	}
}

// NewErrorResponse 创建错误响应
// code: 错误码
// message: 错误消息
// 返回: 响应结构
func NewErrorResponse(code int, message string) *Response {
	return &Response{
		Code:    code,
		Message: message,
		Data:    nil,
	}
}

// NewValidationErrorResponse 创建验证错误响应
// message: 错误消息
// errors: 字段错误列表
// 返回: 错误响应结构
func NewValidationErrorResponse(message string, errors []FieldError) *ErrorResponse {
	return &ErrorResponse{
		Code:    CodeBadRequest,
		Message: message,
		Data:    nil,
		Errors:  errors,
	}
}

// PagedResponse 分页响应结构
type PagedResponse struct {
	List     interface{} `json:"list"`     // 数据列表
	Total    int64       `json:"total"`    // 总数
	Page     int         `json:"page"`     // 当前页码
	PageSize int         `json:"pageSize"` // 每页数量
}

// NewPagedResponse 创建分页响应
// list: 数据列表
// total: 总数
// page: 当前页码
// pageSize: 每页数量
// 返回: 分页响应结构
func NewPagedResponse(list interface{}, total int64, page, pageSize int) *PagedResponse {
	return &PagedResponse{
		List:     list,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}
}

