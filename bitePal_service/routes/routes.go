package routes

import (
	"bitePal_service/handlers"
	"bitePal_service/middleware"

	"github.com/gin-gonic/gin"
)

// SetupRouter 设置路由
// 返回: Gin路由引擎
func SetupRouter() *gin.Engine {
	router := gin.Default()

	// 应用中间件
	router.Use(middleware.CORSMiddleware())

	// 静态文件服务（用于上传的文件）
	router.Static("/uploads", "./uploads")

	// API路由组
	api := router.Group("/api")
	{
		// 初始化处理器
		authHandler := handlers.NewAuthHandler()
		recipeHandler := handlers.NewRecipeHandler()
		menuHandler := handlers.NewMenuHandler()
		mealHandler := handlers.NewMealHandler()
		ingredientHandler := handlers.NewIngredientHandler()
		shoppingHandler := handlers.NewShoppingHandler()
		randomHandler := handlers.NewRandomHandler()
		statsHandler := handlers.NewStatsHandler()
		preferenceHandler := handlers.NewPreferenceHandler()
		uploadHandler := handlers.NewUploadHandler()

		// ==================== 认证接口（无需Token） ====================
		auth := api.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)       // 用户登录
			auth.POST("/register", authHandler.Register) // 用户注册
		}

		// ==================== 需要认证的接口 ====================
		// 用户相关
		user := api.Group("/user")
		user.Use(middleware.AuthMiddleware())
		{
			user.GET("/info", authHandler.GetUserInfo)          // 获取用户信息
			user.PUT("/info", authHandler.UpdateUserInfo)       // 更新用户信息
			user.GET("/stats", statsHandler.GetUserStats)       // 获取用户统计数据
			user.GET("/preferences", preferenceHandler.GetPreferences)       // 获取家庭成员偏好
			user.PUT("/preferences", preferenceHandler.UpdatePreferences)    // 更新家庭成员偏好
			user.DELETE("/preferences/:memberId", preferenceHandler.DeleteFamilyMember) // 删除家庭成员
		}

		// 菜谱相关
		recipes := api.Group("/recipes")
		recipes.Use(middleware.AuthMiddleware())
		{
			recipes.GET("/my", recipeHandler.GetMyRecipes)                  // 获取我的菜谱列表
			recipes.GET("/public", recipeHandler.GetPublicRecipes)          // 获取网络菜谱列表
			recipes.GET("/:recipeId", recipeHandler.GetRecipeDetail)        // 获取菜谱详情
			recipes.POST("", recipeHandler.CreateRecipe)                    // 创建菜谱
			recipes.PUT("/:recipeId", recipeHandler.UpdateRecipe)           // 更新菜谱
			recipes.DELETE("/:recipeId", recipeHandler.DeleteRecipe)        // 删除菜谱
			recipes.POST("/:recipeId/favorite", recipeHandler.ToggleFavorite) // 收藏/取消收藏
			recipes.POST("/:recipeId/add-to-my", recipeHandler.AddToMyRecipes) // 加入我的菜单
			recipes.POST("/random", randomHandler.RandomRecipe)             // 随机推荐菜品
		}

		// 今日菜单相关
		todayMenu := api.Group("/today-menu")
		todayMenu.Use(middleware.AuthMiddleware())
		{
			todayMenu.GET("", menuHandler.GetTodayMenu)                        // 获取今日菜单
			todayMenu.POST("/recipes", menuHandler.AddRecipeToMenu)            // 添加菜谱到菜单
			todayMenu.DELETE("/recipes/:recipeId", menuHandler.RemoveRecipeFromMenu) // 从菜单移除菜谱
		}

		// 家庭点餐相关
		meals := api.Group("/meals")
		meals.Use(middleware.AuthMiddleware())
		{
			meals.GET("/recipes", mealHandler.GetMealRecipes)                  // 获取点餐菜品列表
			meals.POST("/orders", mealHandler.CreateMealOrder)                 // 创建点餐清单
			meals.GET("/orders", mealHandler.GetMealOrders)                    // 获取点餐历史
			meals.POST("/orders/:orderId/confirm", mealHandler.ConfirmMealOrder) // 确认点餐
		}

		// 食材分类相关
		ingredientCategoryHandler := handlers.NewIngredientCategoryHandler()
		ingredientCategories := api.Group("/ingredient-categories")
		ingredientCategories.Use(middleware.AuthMiddleware())
		{
			ingredientCategories.GET("", ingredientCategoryHandler.GetCategories)              // 获取分类列表
			ingredientCategories.GET("/:categoryId", ingredientCategoryHandler.GetCategoryDetail) // 获取分类详情
			ingredientCategories.POST("", ingredientCategoryHandler.CreateCategory)            // 创建分类
			ingredientCategories.PUT("/:categoryId", ingredientCategoryHandler.UpdateCategory) // 更新分类
			ingredientCategories.DELETE("/:categoryId", ingredientCategoryHandler.DeleteCategory) // 删除分类
		}

		// 食材库存相关
		ingredients := api.Group("/ingredients")
		ingredients.Use(middleware.AuthMiddleware())
		{
			ingredients.GET("", ingredientHandler.GetIngredients)                     // 获取食材列表
			ingredients.GET("/grouped", ingredientHandler.GetIngredientsGrouped)      // 获取分组食材列表
			ingredients.GET("/expiring", ingredientHandler.GetExpiringIngredients)    // 获取即将过期食材
			ingredients.GET("/batches", ingredientHandler.GetIngredientBatches)       // 获取同名食材批次
			ingredients.GET("/:ingredientId", ingredientHandler.GetIngredientDetail)  // 获取食材详情
			ingredients.POST("", ingredientHandler.CreateIngredient)                  // 添加食材
			ingredients.PUT("/:ingredientId", ingredientHandler.UpdateIngredient)     // 更新食材
			ingredients.DELETE("/:ingredientId", ingredientHandler.DeleteIngredient)  // 删除食材
		}

		// 购物清单相关
		shoppingLists := api.Group("/shopping-lists")
		shoppingLists.Use(middleware.AuthMiddleware())
		{
			shoppingLists.GET("", shoppingHandler.GetShoppingLists)                 // 获取购物清单列表
			shoppingLists.GET("/current", shoppingHandler.GetCurrentShoppingList)   // 获取当前购物清单
			shoppingLists.GET("/history", shoppingHandler.GetShoppingHistory)       // 获取购物订单历史
			shoppingLists.POST("", shoppingHandler.CreateShoppingList)              // 创建购物清单
			shoppingLists.PUT("/:listId", shoppingHandler.UpdateShoppingList)       // 更新购物清单
			shoppingLists.POST("/:listId/items", shoppingHandler.AddShoppingItem)   // 添加购物项
			shoppingLists.PUT("/:listId/items/:itemId", shoppingHandler.UpdateShoppingItem)    // 更新购物项
			shoppingLists.DELETE("/:listId/items/:itemId", shoppingHandler.DeleteShoppingItem) // 删除购物项
			shoppingLists.POST("/:listId/complete", shoppingHandler.CompleteShoppingList)      // 完成购物清单
			shoppingLists.POST("/:listId/share", shoppingHandler.ShareShoppingList)            // 分享购物清单
		}

		// 文件上传相关
		upload := api.Group("/upload")
		upload.Use(middleware.AuthMiddleware())
		{
			upload.POST("/image", uploadHandler.UploadImage) // 上传图片
		}
	}

	return router
}

