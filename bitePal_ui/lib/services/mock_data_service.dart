import '../models/recipe.dart';
import '../models/ingredient_item.dart';

/// 模拟数据服务 - 用于开发和测试
/// 在实际应用中，这些数据应该从API或数据库获取
class MockDataService {
  /// 获取示例食谱列表（用于点餐界面）
  static List<Recipe> getMealRecipes() {
    return [
      Recipe(
        id: "1",
        name: "番茄炒蛋",
        time: "15分钟",
        difficulty: "简单",
        tags: ["食材充足", "低热量"],
        tagColors: ["bg-green-500", "bg-green-500"],
        favorite: false,
        categories: ["酸", "甜"],
      ),
      Recipe(
        id: "2",
        name: "麻婆豆腐",
        time: "45分钟",
        difficulty: "中等",
        tags: ["中热量"],
        tagColors: ["bg-amber-500"],
        favorite: false,
        categories: ["麻", "辣"],
      ),
      Recipe(
        id: "3",
        name: "清蒸鲈鱼",
        image: "/images/image.png",
        time: "25分钟",
        difficulty: "简单",
        tags: ["食材充足", "低热量"],
        tagColors: ["bg-green-500", "bg-green-500"],
        favorite: false,
        categories: ["粤菜", "清淡"],
      ),
      Recipe(
        id: "4",
        name: "红烧肉",
        image: "/images/image.png",
        time: "45分钟",
        difficulty: "中等",
        tags: ["食材充足", "高热量"],
        tagColors: ["bg-green-500", "bg-red-500"],
        favorite: false,
        categories: ["甜"],
      ),
    ];
  }

  /// 获取今日推荐食谱
  static List<Recipe> getTodayRecipes() {
    return [
      Recipe(
        id: "1",
        name: "番茄炒蛋",
        time: "15 分钟",
        difficulty: "简单",
        tags: ["常做"],
        tagColors: ["bg-blue-500"],
        favorite: false,
        categories: ["家常菜", "酸甜"],
      ),
      Recipe(
        id: "4",
        name: "红烧肉",
        time: "45 分钟",
        difficulty: "中等",
        tags: ["常做"],
        tagColors: ["bg-blue-500"],
        favorite: false,
        categories: ["川菜", "咸鲜"],
      ),
    ];
  }

  /// 获取即将过期的食材
  static List<IngredientItem> getExpiringIngredients() {
    return [
      IngredientItem(
        id: "1",
        name: "生菜",
        amount: "1颗",
        storage: "fridge",
        icon: "🥬",
        expiryDays: 0,
        expiryText: "今天",
        urgent: true,
      ),
      IngredientItem(
        id: "2",
        name: "培根",
        amount: "200g",
        storage: "fridge",
        icon: "🥓",
        expiryDays: 1,
        expiryText: "明天",
        urgent: false,
      ),
      IngredientItem(
        id: "3",
        name: "牛奶",
        amount: "500ml",
        storage: "fridge",
        icon: "🥛",
        expiryDays: 3,
        expiryText: "3天后",
        urgent: false,
      ),
    ];
  }
}
