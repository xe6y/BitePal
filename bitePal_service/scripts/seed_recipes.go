package main

import (
	"bitePal_service/config"
	"bitePal_service/models"
	"log"
	"time"
)

// main 插入模拟菜谱数据
func main() {
	// 初始化配置
	config.InitConfig()
	cfg := config.AppConfig

	// 初始化数据库
	if err := config.InitDB(cfg); err != nil {
		log.Fatalf("数据库初始化失败: %v", err)
	}

	// 获取第一个用户ID（用于创建家庭菜谱）
	var user models.User
	if result := config.DB.First(&user); result.Error != nil {
		log.Fatalf("未找到用户: %v", result.Error)
	}

	log.Printf("使用用户ID: %s (用户名: %s)", user.ID, user.Username)

	// 模拟菜谱数据
	recipes := []models.Recipe{
		// 家庭菜谱 - 红烧土豆丝
		{
			ID:         "recipe-001",
			Name:       "红烧土豆丝",
			Image:      "https://example.com/images/potato-strips.jpg",
			Time:       "25分钟",
			Difficulty: "简单",
			Tags:       models.StringArray{"家常菜", "快手菜", "下饭菜"},
			TagColors:  models.StringArray{"#FF5722", "#4CAF50", "#2196F3"},
			Favorite:   true,
			Categories: models.StringArray{"午餐", "晚餐"},
			Ingredients: models.RecipeIngredients{
				{Name: "土豆", Amount: "2个", Available: true},
				{Name: "青椒", Amount: "1个", Available: true},
				{Name: "生抽", Amount: "2勺", Available: true},
				{Name: "老抽", Amount: "1勺", Available: false},
				{Name: "蒜末", Amount: "适量", Available: true},
			},
			Steps: models.StringArray{
				"土豆去皮切丝，用清水浸泡去除淀粉",
				"青椒切丝，大蒜切末备用",
				"锅中倒油，烧至七成热，放入蒜末爆香",
				"倒入土豆丝大火翻炒2分钟",
				"加入生抽、老抽调色，继续翻炒",
				"放入青椒丝，翻炒1分钟",
				"加少许盐调味，出锅即可",
			},
			UserID:    user.ID,
			IsPublic:  false,
			CreatedAt: time.Now().AddDate(0, 0, -5),
			UpdatedAt: time.Now().AddDate(0, 0, -5),
		},
		// 家庭菜谱 - 西红柿炒鸡蛋
		{
			ID:         "recipe-002",
			Name:       "西红柿炒鸡蛋",
			Image:      "https://example.com/images/tomato-egg.jpg",
			Time:       "15分钟",
			Difficulty: "简单",
			Tags:       models.StringArray{"经典菜", "快手菜", "营养"},
			TagColors:  models.StringArray{"#E91E63", "#4CAF50", "#FF9800"},
			Favorite:   false,
			Categories: models.StringArray{"早餐", "午餐", "晚餐"},
			Ingredients: models.RecipeIngredients{
				{Name: "西红柿", Amount: "2个", Available: true},
				{Name: "鸡蛋", Amount: "3个", Available: true},
				{Name: "葱花", Amount: "少许", Available: true},
				{Name: "白糖", Amount: "1勺", Available: true},
				{Name: "盐", Amount: "适量", Available: true},
			},
			Steps: models.StringArray{
				"西红柿切块，鸡蛋打散加少许盐",
				"锅中倒油，油热后倒入蛋液炒散盛出",
				"另起油锅，放入西红柿翻炒出汁",
				"加白糖提鲜，倒入炒好的鸡蛋",
				"翻炒均匀，撒葱花出锅",
			},
			UserID:    user.ID,
			IsPublic:  false,
			CreatedAt: time.Now().AddDate(0, 0, -3),
			UpdatedAt: time.Now().AddDate(0, 0, -3),
		},
		// 网络菜谱 - 清蒸鲈鱼
		{
			ID:         "recipe-003",
			Name:       "清蒸鲈鱼",
			Image:      "https://example.com/images/steamed-bass.jpg",
			Time:       "35分钟",
			Difficulty: "中等",
			Tags:       models.StringArray{"粤菜", "清淡", "宴客菜"},
			TagColors:  models.StringArray{"#9C27B0", "#00BCD4", "#FFC107"},
			Favorite:   false,
			Categories: models.StringArray{"午餐", "晚餐", "宴客"},
			Ingredients: models.RecipeIngredients{
				{Name: "鲈鱼", Amount: "1条(约500g)", Available: true},
				{Name: "姜丝", Amount: "30g", Available: true},
				{Name: "葱丝", Amount: "2根", Available: true},
				{Name: "蒸鱼豉油", Amount: "3勺", Available: false},
				{Name: "料酒", Amount: "2勺", Available: true},
			},
			Steps: models.StringArray{
				"鲈鱼处理干净，两面划几刀便于入味",
				"鱼身抹少许盐和料酒，腌制10分钟",
				"盘底铺姜丝，放上鱼，鱼身再铺姜丝",
				"水开后上锅蒸8-10分钟",
				"取出倒掉盘中水，铺上葱丝",
				"淋上热油，浇蒸鱼豉油即可",
			},
			UserID:    "system-user-001", // 系统用户，表示网络菜谱
			IsPublic:  true,
			CreatedAt: time.Now().AddDate(0, 0, -10),
			UpdatedAt: time.Now().AddDate(0, 0, -10),
		},
		// 网络菜谱 - 宫保鸡丁
		{
			ID:         "recipe-004",
			Name:       "宫保鸡丁",
			Image:      "https://example.com/images/kung-pao-chicken.jpg",
			Time:       "30分钟",
			Difficulty: "中等",
			Tags:       models.StringArray{"川菜", "下饭菜", "经典"},
			TagColors:  models.StringArray{"#F44336", "#2196F3", "#FF9800"},
			Favorite:   false,
			Categories: models.StringArray{"午餐", "晚餐"},
			Ingredients: models.RecipeIngredients{
				{Name: "鸡胸肉", Amount: "300g", Available: true},
				{Name: "花生米", Amount: "50g", Available: false},
				{Name: "干辣椒", Amount: "10个", Available: true},
				{Name: "花椒", Amount: "1勺", Available: true},
				{Name: "生抽", Amount: "2勺", Available: true},
				{Name: "老抽", Amount: "1勺", Available: false},
				{Name: "料酒", Amount: "1勺", Available: true},
				{Name: "白糖", Amount: "1勺", Available: true},
			},
			Steps: models.StringArray{
				"鸡胸肉切丁，用料酒、生抽、盐腌制15分钟",
				"花生米炸至金黄备用",
				"热锅下油，放入干辣椒和花椒爆香",
				"倒入鸡丁大火翻炒至变色",
				"加入生抽、老抽、白糖调味",
				"最后放入花生米翻炒均匀即可",
			},
			UserID:    "system-user-001",
			IsPublic:  true,
			CreatedAt: time.Now().AddDate(0, 0, -8),
			UpdatedAt: time.Now().AddDate(0, 0, -8),
		},
		// 网络菜谱 - 麻婆豆腐
		{
			ID:         "recipe-005",
			Name:       "麻婆豆腐",
			Image:      "https://example.com/images/mapo-tofu.jpg",
			Time:       "20分钟",
			Difficulty: "简单",
			Tags:       models.StringArray{"川菜", "素食", "快手菜"},
			TagColors:  models.StringArray{"#F44336", "#4CAF50", "#4CAF50"},
			Favorite:   false,
			Categories: models.StringArray{"午餐", "晚餐"},
			Ingredients: models.RecipeIngredients{
				{Name: "嫩豆腐", Amount: "1块", Available: true},
				{Name: "肉末", Amount: "100g", Available: false},
				{Name: "豆瓣酱", Amount: "2勺", Available: true},
				{Name: "花椒粉", Amount: "1勺", Available: true},
				{Name: "葱花", Amount: "适量", Available: true},
			},
			Steps: models.StringArray{
				"豆腐切块，用开水焯一下去除豆腥味",
				"热锅下油，放入肉末炒散",
				"加入豆瓣酱炒出红油",
				"倒入豆腐，轻轻推炒",
				"加少许水，小火煮5分钟",
				"撒花椒粉和葱花即可",
			},
			UserID:    "system-user-001",
			IsPublic:  true,
			CreatedAt: time.Now().AddDate(0, 0, -6),
			UpdatedAt: time.Now().AddDate(0, 0, -6),
		},
		// 家庭菜谱 - 糖醋里脊
		{
			ID:         "recipe-006",
			Name:       "糖醋里脊",
			Image:      "https://example.com/images/sweet-sour-pork.jpg",
			Time:       "40分钟",
			Difficulty: "中等",
			Tags:       models.StringArray{"家常菜", "酸甜", "下饭菜"},
			TagColors:  models.StringArray{"#FF5722", "#FF9800", "#2196F3"},
			Favorite:   true,
			Categories: models.StringArray{"午餐", "晚餐"},
			Ingredients: models.RecipeIngredients{
				{Name: "猪里脊", Amount: "300g", Available: true},
				{Name: "鸡蛋", Amount: "1个", Available: true},
				{Name: "淀粉", Amount: "适量", Available: true},
				{Name: "番茄酱", Amount: "3勺", Available: true},
				{Name: "白糖", Amount: "2勺", Available: true},
				{Name: "白醋", Amount: "1勺", Available: true},
			},
			Steps: models.StringArray{
				"里脊肉切条，用盐、料酒腌制15分钟",
				"鸡蛋打散，肉条裹上蛋液和淀粉",
				"油温六成热，下肉条炸至金黄",
				"复炸一次使外皮更酥脆",
				"另起锅，放入番茄酱、白糖、白醋调汁",
				"倒入炸好的肉条，快速翻炒均匀即可",
			},
			UserID:    user.ID,
			IsPublic:  false,
			CreatedAt: time.Now().AddDate(0, 0, -2),
			UpdatedAt: time.Now().AddDate(0, 0, -2),
		},
		// 网络菜谱 - 鱼香肉丝
		{
			ID:         "recipe-007",
			Name:       "鱼香肉丝",
			Image:      "https://example.com/images/fish-fragrant-pork.jpg",
			Time:       "25分钟",
			Difficulty: "中等",
			Tags:       models.StringArray{"川菜", "经典", "下饭菜"},
			TagColors:  models.StringArray{"#F44336", "#FF9800", "#2196F3"},
			Favorite:   false,
			Categories: models.StringArray{"午餐", "晚餐"},
			Ingredients: models.RecipeIngredients{
				{Name: "猪里脊", Amount: "200g", Available: true},
				{Name: "木耳", Amount: "50g", Available: false},
				{Name: "胡萝卜", Amount: "1根", Available: true},
				{Name: "青椒", Amount: "1个", Available: true},
				{Name: "豆瓣酱", Amount: "1勺", Available: true},
				{Name: "生抽", Amount: "2勺", Available: true},
				{Name: "醋", Amount: "1勺", Available: true},
				{Name: "白糖", Amount: "1勺", Available: true},
			},
			Steps: models.StringArray{
				"里脊肉切丝，用料酒、生抽腌制",
				"木耳、胡萝卜、青椒切丝",
				"热锅下油，放入肉丝炒至变色盛出",
				"另起油锅，放入豆瓣酱炒出红油",
				"倒入蔬菜丝翻炒",
				"加入肉丝，调入生抽、醋、白糖炒匀即可",
			},
			UserID:    "system-user-001",
			IsPublic:  true,
			CreatedAt: time.Now().AddDate(0, 0, -7),
			UpdatedAt: time.Now().AddDate(0, 0, -7),
		},
		// 家庭菜谱 - 蒜蓉西兰花
		{
			ID:         "recipe-008",
			Name:       "蒜蓉西兰花",
			Image:      "https://example.com/images/garlic-broccoli.jpg",
			Time:       "10分钟",
			Difficulty: "简单",
			Tags:       models.StringArray{"素食", "快手菜", "健康"},
			TagColors:  models.StringArray{"#4CAF50", "#4CAF50", "#4CAF50"},
			Favorite:   false,
			Categories: models.StringArray{"午餐", "晚餐"},
			Ingredients: models.RecipeIngredients{
				{Name: "西兰花", Amount: "1颗", Available: true},
				{Name: "大蒜", Amount: "5瓣", Available: true},
				{Name: "盐", Amount: "适量", Available: true},
				{Name: "生抽", Amount: "1勺", Available: true},
			},
			Steps: models.StringArray{
				"西兰花掰成小朵，用盐水浸泡10分钟",
				"大蒜切末",
				"锅中烧水，水开后放入西兰花焯水1分钟",
				"热锅下油，放入蒜末爆香",
				"倒入西兰花大火翻炒",
				"加盐和生抽调味即可",
			},
			UserID:    user.ID,
			IsPublic:  false,
			CreatedAt: time.Now().AddDate(0, 0, -1),
			UpdatedAt: time.Now().AddDate(0, 0, -1),
		},
	}

	// 插入菜谱数据
	log.Println("开始插入模拟菜谱数据...")
	for i, recipe := range recipes {
		// 检查是否已存在
		var existing models.Recipe
		if result := config.DB.Where("id = ?", recipe.ID).First(&existing); result.Error == nil {
			log.Printf("菜谱 %s 已存在，跳过", recipe.Name)
			continue
		}

		// 创建菜谱
		if result := config.DB.Create(&recipe); result.Error != nil {
			log.Printf("创建菜谱 %s 失败: %v", recipe.Name, result.Error)
			continue
		}

		log.Printf("[%d/%d] 成功创建菜谱: %s (ID: %s)", i+1, len(recipes), recipe.Name, recipe.ID)
	}

	log.Println("模拟数据插入完成！")
	log.Printf("共创建了 %d 个菜谱", len(recipes))
	log.Println("\n菜谱列表:")
	log.Println("- 家庭菜谱 (isPublic=false):")
	log.Println("  1. 红烧土豆丝")
	log.Println("  2. 西红柿炒鸡蛋")
	log.Println("  3. 糖醋里脊")
	log.Println("  4. 蒜蓉西兰花")
	log.Println("\n- 网络菜谱 (isPublic=true):")
	log.Println("  1. 清蒸鲈鱼")
	log.Println("  2. 宫保鸡丁")
	log.Println("  3. 麻婆豆腐")
	log.Println("  4. 鱼香肉丝")
}
