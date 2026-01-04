import '../config/api_config.dart';
import '../models/meal_order.dart';
import '../models/recipe.dart';
import 'http_client.dart';

/// 点餐服务
/// 处理家庭点餐相关功能
class MealService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final MealService _instance = MealService._internal();

  /// 工厂构造函数
  factory MealService() => _instance;

  /// 私有构造函数
  MealService._internal();

  /// 获取点餐菜品列表
  /// page: 页码
  /// pageSize: 每页数量
  /// keyword: 搜索关键词
  /// tastes: 口味筛选
  /// cuisines: 菜系筛选
  /// 返回: 菜谱列表和分页信息
  Future<PagedData<Recipe>?> getMealRecipes({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    String? tastes,
    String? cuisines,
  }) async {
    final response = await _client.get(
      ApiConfig.mealRecipes,
      queryParams: {
        'page': page,
        'pageSize': pageSize,
        if (keyword != null) 'keyword': keyword,
        if (tastes != null) 'tastes': tastes,
        if (cuisines != null) 'cuisines': cuisines,
      },
    );

    if (response.isSuccess && response.data != null) {
      final list = (response.data['list'] as List? ?? [])
          .map((e) => Recipe.fromJson(e))
          .toList();
      return PagedData<Recipe>(
        list: list,
        total: response.data['total'] ?? 0,
        page: response.data['page'] ?? page,
        pageSize: response.data['pageSize'] ?? pageSize,
      );
    }

    return null;
  }

  /// 创建点餐清单
  /// recipes: 菜谱列表
  /// 返回: 创建的点餐清单
  Future<MealOrder?> createMealOrder(List<OrderRecipe> recipes) async {
    final response = await _client.post(
      ApiConfig.mealOrders,
      data: {
        'recipes': recipes.map((e) => e.toJson()).toList(),
      },
    );

    if (response.isSuccess && response.data != null) {
      return MealOrder.fromJson(response.data);
    }

    return null;
  }

  /// 确认点餐
  /// orderId: 点餐ID
  /// 返回: 是否确认成功
  Future<bool> confirmMealOrder(String orderId) async {
    final response = await _client.post(
      '${ApiConfig.mealOrders}/$orderId/confirm',
    );
    return response.isSuccess;
  }

  /// 获取点餐历史
  /// page: 页码
  /// pageSize: 每页数量
  /// status: 状态筛选
  /// 返回: 点餐历史列表和分页信息
  Future<PagedData<MealOrder>?> getMealOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final response = await _client.get(
      ApiConfig.mealOrders,
      queryParams: {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status,
      },
    );

    if (response.isSuccess && response.data != null) {
      final list = (response.data['list'] as List? ?? [])
          .map((e) => MealOrder.fromJson(e))
          .toList();
      return PagedData<MealOrder>(
        list: list,
        total: response.data['total'] ?? 0,
        page: response.data['page'] ?? page,
        pageSize: response.data['pageSize'] ?? pageSize,
      );
    }

    return null;
  }
}

