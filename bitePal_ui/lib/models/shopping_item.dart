/// 购物项模型
class ShoppingItem {
  /// 购物项ID
  final String id;

  /// 商品名称
  final String name;

  /// 数量
  final String amount;

  /// 价格
  final double price;

  /// 是否已购买
  final bool checked;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.price,
    this.checked = false,
  });

  /// 从JSON创建ShoppingItem实例
  /// json: JSON数据
  /// 返回: ShoppingItem实例
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      checked: json['checked'] ?? false,
    );
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'price': price,
      'checked': checked,
    };
  }

  /// 复制并修改
  ShoppingItem copyWith({
    String? id,
    String? name,
    String? amount,
    double? price,
    bool? checked,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      checked: checked ?? this.checked,
    );
  }
}

/// 购物清单模型
class ShoppingList {
  /// 清单ID
  final String id;

  /// 清单名称
  final String name;

  /// 购物项列表
  final List<ShoppingItem> items;

  /// 总价
  final double totalPrice;

  /// 创建时间
  final String? createdAt;

  /// 完成时间
  final String? completedAt;

  ShoppingList({
    required this.id,
    required this.name,
    required this.items,
    required this.totalPrice,
    this.createdAt,
    this.completedAt,
  });

  /// 从JSON创建ShoppingList实例
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '购物清单',
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => ShoppingItem.fromJson(e))
              .toList()
          : [],
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      createdAt: json['createdAt'],
      completedAt: json['completedAt'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
      'totalPrice': totalPrice,
    };
  }

  /// 是否已完成
  bool get isCompleted => completedAt != null;
}
