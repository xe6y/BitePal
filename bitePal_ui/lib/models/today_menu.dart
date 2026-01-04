/// 今日菜单模型
class TodayMenu {
  /// 菜单ID
  final String? id;

  /// 日期（YYYY-MM-DD）
  final String date;

  /// 菜谱列表
  final List<MenuRecipe> recipes;

  TodayMenu({
    this.id,
    required this.date,
    required this.recipes,
  });

  /// 从JSON创建TodayMenu实例
  factory TodayMenu.fromJson(Map<String, dynamic> json) {
    return TodayMenu(
      id: json['id'],
      date: json['date'] ?? '',
      recipes: json['recipes'] != null
          ? (json['recipes'] as List)
              .map((e) => MenuRecipe.fromJson(e))
              .toList()
          : [],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'recipes': recipes.map((e) => e.toJson()).toList(),
    };
  }
}

/// 菜单中的菜谱
class MenuRecipe {
  /// 菜谱ID
  final String recipeId;

  /// 菜谱名称
  final String recipeName;

  /// 餐点类型（早餐/午餐/晚餐/夜宵）
  final String mealType;

  MenuRecipe({
    required this.recipeId,
    required this.recipeName,
    required this.mealType,
  });

  /// 从JSON创建MenuRecipe实例
  factory MenuRecipe.fromJson(Map<String, dynamic> json) {
    return MenuRecipe(
      recipeId: json['recipeId']?.toString() ?? '',
      recipeName: json['recipeName'] ?? '',
      mealType: json['mealType'] ?? '晚餐',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'recipeName': recipeName,
      'mealType': mealType,
    };
  }
}

