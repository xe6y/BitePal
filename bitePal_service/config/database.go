package config

import (
	"log"

	. "bitePal_service/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DB 全局数据库实例
var DB *gorm.DB

// InitDB 初始化数据库连接
// cfg: 应用配置
// 返回: 错误信息
func InitDB(cfg *Config) error {
	var err error

	// 配置GORM日志
	gormConfig := &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	}

	// 连接SQLite数据库
	DB, err = gorm.Open(sqlite.Open(cfg.DatabasePath), gormConfig)
	if err != nil {
		log.Printf("数据库连接失败: %v", err)
		return err
	}

	log.Printf("数据库连接成功: %s", cfg.DatabasePath)

	// 自动迁移数据库表结构
	if err := autoMigrate(); err != nil {
		log.Printf("数据库迁移失败: %v", err)
		return err
	}

	return nil
}

// autoMigrate 自动迁移数据库表
// 返回: 错误信息
func autoMigrate() error {
	// 导入models包中的所有模型进行迁移
	err := DB.AutoMigrate(
		&User{},
		&Recipe{},
		&UserFavorite{},
		&IngredientCategory{},
		&IngredientItem{},
		&ShoppingList{},
		&TodayMenu{},
		&MealOrder{},
		&UserStats{},
		&FamilyMember{},
	)
	if err != nil {
		return err
	}

	// 初始化默认食材分类
	initDefaultCategories()

	return nil
}

// initDefaultCategories 初始化默认食材分类
func initDefaultCategories() {
	defaultCategories := GetDefaultCategories()
	for _, cat := range defaultCategories {
		// 检查是否已存在，不存在则创建
		var existing IngredientCategory
		if result := DB.Where("id = ?", cat.ID).First(&existing); result.Error != nil {
			DB.Create(cat)
			log.Printf("创建默认食材分类: %s", cat.Name)
		}
	}
}

// GetDB 获取数据库实例
// 返回: 数据库实例
func GetDB() *gorm.DB {
	return DB
}
