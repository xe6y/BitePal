package handlers

import (
	"bitePal_service/models"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// UploadHandler 文件上传处理器
type UploadHandler struct{}

// NewUploadHandler 创建文件上传处理器实例
// 返回: 文件上传处理器
func NewUploadHandler() *UploadHandler {
	return &UploadHandler{}
}

// 上传配置常量
const (
	MaxUploadSize = 10 << 20 // 最大上传大小：10MB
	UploadDir     = "uploads" // 上传目录
)

// 允许的图片类型
var allowedImageTypes = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
	"image/gif":  true,
	"image/webp": true,
}

// UploadImage 上传图片
// @Summary 上传图片
// @Description 上传图片文件
// @Tags 文件上传
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param file formData file true "图片文件"
// @Success 200 {object} models.Response{data=object}
// @Failure 400 {object} models.Response
// @Router /api/upload/image [post]
func (h *UploadHandler) UploadImage(c *gin.Context) {
	// 获取上传的文件
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"请选择要上传的文件",
		))
		return
	}
	defer file.Close()

	// 检查文件大小
	if header.Size > MaxUploadSize {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"文件大小超过限制（最大10MB）",
		))
		return
	}

	// 检查文件类型
	contentType := header.Header.Get("Content-Type")
	if !allowedImageTypes[contentType] {
		c.JSON(http.StatusBadRequest, models.NewErrorResponse(
			models.CodeBadRequest,
			"不支持的文件类型，仅支持 JPEG、PNG、GIF、WebP 格式",
		))
		return
	}

	// 确保上传目录存在
	if err := os.MkdirAll(UploadDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"创建上传目录失败",
		))
		return
	}

	// 生成唯一文件名
	ext := filepath.Ext(header.Filename)
	filename := time.Now().Format("20060102") + "_" + uuid.New().String() + ext
	filePath := filepath.Join(UploadDir, filename)

	// 保存文件
	if err := c.SaveUploadedFile(header, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, models.NewErrorResponse(
			models.CodeServerError,
			"文件保存失败",
		))
		return
	}

	// 返回文件URL
	// 实际生产环境中，应该返回CDN或对象存储的URL
	fileURL := "/uploads/" + filename

	c.JSON(http.StatusOK, models.NewSuccessResponseWithMessage("上传成功", gin.H{
		"url": fileURL,
	}))
}

