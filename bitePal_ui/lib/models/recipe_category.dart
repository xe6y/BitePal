/// 菜谱分类模型
class RecipeCategory {
  /// 分类ID
  final String id;

  /// 分类类型（taste/cuisine/difficulty/meal_type）
  final String type;

  /// 分类名称
  final String name;

  /// 显示颜色
  final String? color;

  /// 图标
  final String? icon;

  /// 排序顺序
  final int sortOrder;

  /// 是否启用
  final bool isActive;

  RecipeCategory({
    required this.id,
    required this.type,
    required this.name,
    this.color,
    this.icon,
    required this.sortOrder,
    required this.isActive,
  });

  /// 从JSON创建RecipeCategory实例
  /// json: JSON数据
  /// 返回: RecipeCategory实例
  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      color: json['color'],
      icon: json['icon'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'color': color,
      'icon': icon,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

