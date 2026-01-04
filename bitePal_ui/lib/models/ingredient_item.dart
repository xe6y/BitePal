/// 食材库存模型
class IngredientItem {
  /// 食材ID
  final String id;

  /// 食材名称
  final String name;

  /// 数量（如：2个）
  final String amount;

  /// 存储分类（room/fridge/freezer）
  final String category;

  /// 图标（emoji）
  final String icon;

  /// 过期日期
  final String? expiryDate;

  /// 距离过期的天数
  final int expiryDays;

  /// 过期文本（如：今天、明天、3天后）
  final String expiryText;

  /// 是否紧急（当天过期）
  final bool urgent;

  IngredientItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.icon,
    this.expiryDate,
    required this.expiryDays,
    required this.expiryText,
    this.urgent = false,
  });

  /// 从JSON创建IngredientItem实例
  /// json: JSON数据
  /// 返回: IngredientItem实例
  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    return IngredientItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      category: json['category'] ?? 'fridge',
      icon: json['icon'] ?? '🥬',
      expiryDate: json['expiryDate'],
      expiryDays: json['expiryDays'] ?? 0,
      expiryText: json['expiryText'] ?? '',
      urgent: json['urgent'] ?? false,
    );
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'icon': icon,
      'expiryDate': expiryDate,
    };
  }

  /// 复制并修改
  IngredientItem copyWith({
    String? id,
    String? name,
    String? amount,
    String? category,
    String? icon,
    String? expiryDate,
    int? expiryDays,
    String? expiryText,
    bool? urgent,
  }) {
    return IngredientItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      expiryDate: expiryDate ?? this.expiryDate,
      expiryDays: expiryDays ?? this.expiryDays,
      expiryText: expiryText ?? this.expiryText,
      urgent: urgent ?? this.urgent,
    );
  }
}
