/// 菜谱模型
class Recipe {
  /// 菜谱ID
  final String id;

  /// 菜谱名称
  final String name;

  /// 图片URL
  final String? image;

  /// 制作时间
  final String time;

  /// 难度（简单/中等/困难）
  final String difficulty;

  /// 标签数组
  final List<String> tags;

  /// 标签颜色数组
  final List<String> tagColors;

  /// 是否收藏
  final bool favorite;

  /// 分类数组
  final List<String> categories;

  /// 食材列表
  final List<Ingredient>? ingredients;

  /// 制作步骤
  final List<String>? steps;

  /// 创建用户ID
  final String? userId;

  /// 是否公开
  final bool? isPublic;

  Recipe({
    required this.id,
    required this.name,
    this.image,
    required this.time,
    required this.difficulty,
    required this.tags,
    required this.tagColors,
    this.favorite = false,
    required this.categories,
    this.ingredients,
    this.steps,
    this.userId,
    this.isPublic,
  });

  /// 从JSON创建Recipe实例
  /// json: JSON数据
  /// 返回: Recipe实例
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      time: json['time'] ?? '',
      difficulty: json['difficulty'] ?? '简单',
      tags: List<String>.from(json['tags'] ?? []),
      tagColors: List<String>.from(json['tagColors'] ?? []),
      favorite: json['favorite'] ?? false,
      categories: List<String>.from(json['categories'] ?? []),
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List)
              .map((e) => Ingredient.fromJson(e))
              .toList()
          : null,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : null,
      userId: json['userId'],
      isPublic: json['isPublic'],
    );
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'time': time,
      'difficulty': difficulty,
      'tags': tags,
      'tagColors': tagColors,
      'favorite': favorite,
      'categories': categories,
      'ingredients': ingredients?.map((e) => e.toJson()).toList(),
      'steps': steps,
      'isPublic': isPublic,
    };
  }

  /// 复制并修改
  Recipe copyWith({
    String? id,
    String? name,
    String? image,
    String? time,
    String? difficulty,
    List<String>? tags,
    List<String>? tagColors,
    bool? favorite,
    List<String>? categories,
    List<Ingredient>? ingredients,
    List<String>? steps,
    String? userId,
    bool? isPublic,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      time: time ?? this.time,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      tagColors: tagColors ?? this.tagColors,
      favorite: favorite ?? this.favorite,
      categories: categories ?? this.categories,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      userId: userId ?? this.userId,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

/// 食材模型
class Ingredient {
  /// 食材名称
  final String name;

  /// 用量
  final String amount;

  /// 是否可用
  final bool available;

  Ingredient({
    required this.name,
    required this.amount,
    this.available = true,
  });

  /// 从JSON创建Ingredient实例
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      available: json['available'] ?? true,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'available': available,
    };
  }
}
