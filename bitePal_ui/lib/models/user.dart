/// 用户模型
class User {
  /// 用户ID
  final String id;

  /// 用户名
  final String username;

  /// 昵称
  final String nickname;

  /// 头像URL
  final String? avatar;

  /// 用户唯一标识
  final String userId;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatar,
    required this.userId,
  });

  /// 从JSON创建User实例
  /// json: JSON数据
  /// 返回: User实例
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'],
      userId: json['userId'] ?? '',
    );
  }

  /// 转换为JSON
  /// 返回: JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'userId': userId,
    };
  }
}

/// 用户统计数据模型
class UserStats {
  /// 用户ID
  final String userId;

  /// 本月做饭次数
  final int monthlyCookingCount;

  /// 食材浪费减少率
  final double wasteReductionRate;

  /// 总菜谱数
  final int totalRecipes;

  /// 收藏菜谱数
  final int favoriteRecipes;

  UserStats({
    required this.userId,
    required this.monthlyCookingCount,
    required this.wasteReductionRate,
    required this.totalRecipes,
    required this.favoriteRecipes,
  });

  /// 从JSON创建UserStats实例
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'] ?? '',
      monthlyCookingCount: json['monthlyCookingCount'] ?? 0,
      wasteReductionRate: (json['wasteReductionRate'] ?? 0).toDouble(),
      totalRecipes: json['totalRecipes'] ?? 0,
      favoriteRecipes: json['favoriteRecipes'] ?? 0,
    );
  }
}

/// 家庭成员模型
class FamilyMember {
  /// 成员ID
  final String? id;

  /// 成员名称
  final String name;

  /// 偏好设置
  final MemberPreferences preferences;

  FamilyMember({this.id, required this.name, required this.preferences});

  /// 从JSON创建FamilyMember实例
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'] ?? '',
      preferences: MemberPreferences.fromJson(json['preferences'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'preferences': preferences.toJson(),
    };
  }
}

/// 成员偏好设置
class MemberPreferences {
  /// 口味偏好
  final List<String> tastes;

  /// 过敏食材
  final List<String> allergies;

  /// 不喜欢的食材
  final List<String> dislikes;

  MemberPreferences({
    required this.tastes,
    required this.allergies,
    required this.dislikes,
  });

  /// 从JSON创建MemberPreferences实例
  factory MemberPreferences.fromJson(Map<String, dynamic> json) {
    return MemberPreferences(
      tastes: List<String>.from(json['tastes'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      dislikes: List<String>.from(json['dislikes'] ?? []),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'tastes': tastes, 'allergies': allergies, 'dislikes': dislikes};
  }
}
