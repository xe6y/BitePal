/// 点餐清单模型
class MealOrder {
  /// 点餐ID
  final String id;

  /// 菜谱列表
  final List<OrderRecipe> recipes;

  /// 状态（pending/confirmed/completed）
  final String status;

  /// 创建时间
  final String? createdAt;

  /// 更新时间
  final String? updatedAt;

  MealOrder({
    required this.id,
    required this.recipes,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// 从JSON创建MealOrder实例
  factory MealOrder.fromJson(Map<String, dynamic> json) {
    return MealOrder(
      id: json['id']?.toString() ?? '',
      recipes: json['recipes'] != null
          ? (json['recipes'] as List)
              .map((e) => OrderRecipe.fromJson(e))
              .toList()
          : [],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipes': recipes.map((e) => e.toJson()).toList(),
      'status': status,
    };
  }

  /// 是否待确认
  bool get isPending => status == 'pending';

  /// 是否已确认
  bool get isConfirmed => status == 'confirmed';

  /// 是否已完成
  bool get isCompleted => status == 'completed';
}

/// 点餐中的菜谱
class OrderRecipe {
  /// 菜谱ID
  final String recipeId;

  /// 菜谱名称
  final String recipeName;

  OrderRecipe({
    required this.recipeId,
    required this.recipeName,
  });

  /// 从JSON创建OrderRecipe实例
  factory OrderRecipe.fromJson(Map<String, dynamic> json) {
    return OrderRecipe(
      recipeId: json['recipeId']?.toString() ?? '',
      recipeName: json['recipeName'] ?? '',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'recipeName': recipeName,
    };
  }
}

