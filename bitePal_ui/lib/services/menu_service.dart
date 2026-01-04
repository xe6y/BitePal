import '../config/api_config.dart';
import '../models/today_menu.dart';
import 'http_client.dart';

/// 今日菜单服务
/// 处理今日菜单的获取、添加、移除菜谱等
class MenuService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final MenuService _instance = MenuService._internal();

  /// 工厂构造函数
  factory MenuService() => _instance;

  /// 私有构造函数
  MenuService._internal();

  /// 获取今日菜单
  /// date: 日期（可选，格式：YYYY-MM-DD，默认今天）
  /// 返回: 今日菜单
  Future<TodayMenu?> getTodayMenu({String? date}) async {
    final response = await _client.get(
      ApiConfig.todayMenu,
      queryParams: {
        if (date != null) 'date': date,
      },
    );

    if (response.isSuccess && response.data != null) {
      return TodayMenu.fromJson(response.data);
    }

    return null;
  }

  /// 添加菜谱到今日菜单
  /// recipeId: 菜谱ID
  /// mealType: 餐点类型（可选，默认晚餐）
  /// date: 日期（可选，默认今天）
  /// 返回: 更新后的今日菜单
  Future<TodayMenu?> addRecipeToMenu(
    String recipeId, {
    String? mealType,
    String? date,
  }) async {
    final response = await _client.post(
      ApiConfig.todayMenuRecipes,
      data: {
        'recipeId': recipeId,
        if (mealType != null) 'mealType': mealType,
        if (date != null) 'date': date,
      },
    );

    if (response.isSuccess && response.data != null) {
      return TodayMenu.fromJson(response.data);
    }

    return null;
  }

  /// 从今日菜单移除菜谱
  /// recipeId: 菜谱ID
  /// date: 日期（可选，默认今天）
  /// 返回: 是否移除成功
  Future<bool> removeRecipeFromMenu(String recipeId, {String? date}) async {
    String path = '${ApiConfig.todayMenuRecipes}/$recipeId';
    if (date != null) {
      path += '?date=$date';
    }
    final response = await _client.delete(path);
    return response.isSuccess;
  }
}

