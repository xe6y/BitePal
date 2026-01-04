import '../config/api_config.dart';
import '../models/ingredient_item.dart';
import 'http_client.dart';

/// 食材服务
/// 处理食材库存的增删改查
class IngredientService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final IngredientService _instance = IngredientService._internal();

  /// 工厂构造函数
  factory IngredientService() => _instance;

  /// 私有构造函数
  IngredientService._internal();

  /// 获取食材列表
  /// category: 分类筛选（room/fridge/freezer）
  /// urgent: 是否只显示紧急
  /// expiringDays: 过期天数筛选
  /// 返回: 食材列表
  Future<List<IngredientItem>> getIngredients({
    String? category,
    bool? urgent,
    int? expiringDays,
  }) async {
    final response = await _client.get(
      ApiConfig.ingredients,
      queryParams: {
        if (category != null) 'category': category,
        if (urgent != null) 'urgent': urgent,
        if (expiringDays != null) 'expiringDays': expiringDays,
      },
    );

    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => IngredientItem.fromJson(e))
          .toList();
    }

    return [];
  }

  /// 获取即将过期食材
  /// days: 天数（默认3，表示3天内过期）
  /// 返回: 即将过期的食材列表
  Future<List<IngredientItem>> getExpiringIngredients({int days = 3}) async {
    final response = await _client.get(
      ApiConfig.expiringIngredients,
      queryParams: {'days': days},
    );

    if (response.isSuccess && response.data != null) {
      return (response.data['list'] as List? ?? [])
          .map((e) => IngredientItem.fromJson(e))
          .toList();
    }

    return [];
  }

  /// 获取食材详情
  /// ingredientId: 食材ID
  /// 返回: 食材详情
  Future<IngredientItem?> getIngredientDetail(String ingredientId) async {
    final response = await _client.get(
      '${ApiConfig.ingredients}/$ingredientId',
    );

    if (response.isSuccess && response.data != null) {
      return IngredientItem.fromJson(response.data);
    }

    return null;
  }

  /// 添加食材
  /// name: 食材名称
  /// amount: 数量
  /// category: 存储分类
  /// icon: 图标
  /// expiryDate: 过期日期
  /// 返回: 添加的食材
  Future<IngredientItem?> createIngredient({
    required String name,
    String? amount,
    String? category,
    String? icon,
    String? expiryDate,
  }) async {
    final response = await _client.post(
      ApiConfig.ingredients,
      data: {
        'name': name,
        if (amount != null) 'amount': amount,
        if (category != null) 'category': category,
        if (icon != null) 'icon': icon,
        if (expiryDate != null) 'expiryDate': expiryDate,
      },
    );

    if (response.isSuccess && response.data != null) {
      return IngredientItem.fromJson(response.data);
    }

    return null;
  }

  /// 更新食材
  /// ingredientId: 食材ID
  /// name: 食材名称
  /// amount: 数量
  /// category: 存储分类
  /// icon: 图标
  /// expiryDate: 过期日期
  /// 返回: 更新后的食材
  Future<IngredientItem?> updateIngredient(
    String ingredientId, {
    String? name,
    String? amount,
    String? category,
    String? icon,
    String? expiryDate,
  }) async {
    final response = await _client.put(
      '${ApiConfig.ingredients}/$ingredientId',
      data: {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (category != null) 'category': category,
        if (icon != null) 'icon': icon,
        if (expiryDate != null) 'expiryDate': expiryDate,
      },
    );

    if (response.isSuccess && response.data != null) {
      return IngredientItem.fromJson(response.data);
    }

    return null;
  }

  /// 删除食材
  /// ingredientId: 食材ID
  /// 返回: 是否删除成功
  Future<bool> deleteIngredient(String ingredientId) async {
    final response = await _client.delete(
      '${ApiConfig.ingredients}/$ingredientId',
    );
    return response.isSuccess;
  }
}

