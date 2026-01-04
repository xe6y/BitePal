/// 食材分类模型
class IngredientCategory {
  /// 分类ID
  final String id;

  /// 分类名称
  final String name;

  /// 分类图标（emoji）
  final String icon;

  /// 分类颜色
  final String color;

  /// 排序顺序
  final int sortOrder;

  /// 是否为系统预设分类
  final bool isSystem;

  IngredientCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.sortOrder = 0,
    this.isSystem = false,
  });

  /// 从JSON创建IngredientCategory实例
  /// json: JSON数据
  /// 返回: IngredientCategory实例
  factory IngredientCategory.fromJson(Map<String, dynamic> json) {
    return IngredientCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📦',
      color: json['color'] ?? '#9E9E9E',
      sortOrder: json['sortOrder'] ?? 0,
      isSystem: json['isSystem'] ?? false,
    );
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'sortOrder': sortOrder,
      'isSystem': isSystem,
    };
  }
}

/// 食材库存模型
class IngredientItem {
  /// 食材ID
  final String id;

  /// 食材名称
  final String name;

  /// 数量数值
  final double quantity;

  /// 单位（个、斤、克、毫升等）
  final String unit;

  /// 数量描述（如：2个）- 兼容旧版本
  final String amount;

  /// 存储位置（room/fridge/freezer）
  final String storage;

  /// 食材分类ID
  final String categoryId;

  /// 食材分类名称
  final String categoryName;

  /// 缩略图URL
  final String thumbnail;

  /// 图标（emoji）- 兼容旧版本
  final String icon;

  /// 备注
  final String note;

  /// 批次ID
  final String batchId;

  /// 过期日期
  final String? expiryDate;

  /// 购买日期
  final String? purchaseDate;

  /// 距离过期的天数
  final int expiryDays;

  /// 过期文本（如：今天、明天、3天后）
  final String expiryText;

  /// 是否紧急（当天过期或已过期）
  final bool urgent;

  /// 分类详情
  final IngredientCategory? category;

  IngredientItem({
    required this.id,
    required this.name,
    this.quantity = 0,
    this.unit = '',
    required this.amount,
    this.storage = 'fridge',
    this.categoryId = '',
    this.categoryName = '',
    this.thumbnail = '',
    required this.icon,
    this.note = '',
    this.batchId = '',
    this.expiryDate,
    this.purchaseDate,
    required this.expiryDays,
    required this.expiryText,
    this.urgent = false,
    this.category,
  });

  /// 从JSON创建IngredientItem实例
  /// json: JSON数据
  /// 返回: IngredientItem实例
  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    return IngredientItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      amount: json['amount'] ?? '',
      storage: json['storage'] ?? json['category'] ?? 'fridge',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      icon: json['icon'] ?? '🥬',
      note: json['note'] ?? '',
      batchId: json['batchId'] ?? '',
      expiryDate: json['expiryDate'],
      purchaseDate: json['purchaseDate'],
      expiryDays: json['expiryDays'] ?? 0,
      expiryText: json['expiryText'] ?? '',
      urgent: json['urgent'] ?? false,
      category: json['category'] != null
          ? IngredientCategory.fromJson(json['category'])
          : null,
    );
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'amount': amount,
      'storage': storage,
      'categoryId': categoryId,
      'thumbnail': thumbnail,
      'icon': icon,
      'note': note,
      'expiryDate': expiryDate,
      'purchaseDate': purchaseDate,
    };
  }

  /// 获取显示用的数量文本
  /// 返回: 数量文本（优先使用数值+单位，否则使用amount字段）
  String get displayAmount {
    if (quantity > 0 && unit.isNotEmpty) {
      if (quantity == quantity.truncateToDouble()) {
        return '${quantity.toInt()}$unit';
      }
      return '$quantity$unit';
    }
    return amount;
  }

  /// 获取显示用的图片
  /// 如果有缩略图则返回缩略图URL，否则返回null
  String? get displayImage => thumbnail.isNotEmpty ? thumbnail : null;

  /// 复制并修改
  IngredientItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? amount,
    String? storage,
    String? categoryId,
    String? categoryName,
    String? thumbnail,
    String? icon,
    String? note,
    String? batchId,
    String? expiryDate,
    String? purchaseDate,
    int? expiryDays,
    String? expiryText,
    bool? urgent,
    IngredientCategory? category,
  }) {
    return IngredientItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      amount: amount ?? this.amount,
      storage: storage ?? this.storage,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      thumbnail: thumbnail ?? this.thumbnail,
      icon: icon ?? this.icon,
      note: note ?? this.note,
      batchId: batchId ?? this.batchId,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDays: expiryDays ?? this.expiryDays,
      expiryText: expiryText ?? this.expiryText,
      urgent: urgent ?? this.urgent,
      category: category ?? this.category,
    );
  }
}

/// 食材分组响应模型
class IngredientGroup {
  /// 分类信息
  final IngredientCategory category;

  /// 该分类下的食材列表
  final List<IngredientItem> ingredients;

  /// 该分类下的食材数量
  final int count;

  IngredientGroup({
    required this.category,
    required this.ingredients,
    required this.count,
  });

  /// 从JSON创建IngredientGroup实例
  /// json: JSON数据
  /// 返回: IngredientGroup实例
  factory IngredientGroup.fromJson(Map<String, dynamic> json) {
    return IngredientGroup(
      category: IngredientCategory.fromJson(json['category'] ?? {}),
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => IngredientItem.fromJson(e))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}
