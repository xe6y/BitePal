import '../config/api_config.dart';
import '../models/recipe_category.dart';
import 'http_client.dart';

/// 菜谱分类服务
/// 处理菜谱分类的查询和管理
class CategoryService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final CategoryService _instance = CategoryService._internal();

  /// 工厂构造函数
  factory CategoryService() => _instance;

  /// 私有构造函数
  CategoryService._internal();

  /// 获取所有菜谱分类
  /// type: 分类类型（可选）
  /// 返回: 分类列表
  Future<List<RecipeCategory>?> getRecipeCategories({String? type}) async {
    final response = await _client.get(
      ApiConfig.recipeCategories,
      queryParams: {
        if (type != null) 'type': type,
      },
    );

    if (response.isSuccess && response.data != null) {
      final list = (response.data as List? ?? [])
          .map((e) => RecipeCategory.fromJson(e))
          .toList();
      return list;
    }

    return null;
  }

  /// 按类型获取菜谱分类
  /// type: 分类类型（taste/cuisine/difficulty/meal_type）
  /// 返回: 分类列表
  Future<List<RecipeCategory>?> getCategoriesByType(String type) async {
    final response = await _client.get('${ApiConfig.recipeCategories}/$type');

    if (response.isSuccess && response.data != null) {
      final list = (response.data as List? ?? [])
          .map((e) => RecipeCategory.fromJson(e))
          .toList();
      return list;
    }

    return null;
  }

  /// 创建分类
  /// category: 分类数据
  /// 返回: 创建后的分类
  Future<RecipeCategory?> createCategory(RecipeCategory category) async {
    final response = await _client.post(
      ApiConfig.recipeCategories,
      data: category.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      return RecipeCategory.fromJson(response.data);
    }

    return null;
  }

  /// 更新分类
  /// categoryId: 分类ID
  /// category: 分类数据
  /// 返回: 更新后的分类
  Future<RecipeCategory?> updateCategory(
    String categoryId,
    RecipeCategory category,
  ) async {
    final response = await _client.put(
      '${ApiConfig.recipeCategories}/$categoryId',
      data: category.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      return RecipeCategory.fromJson(response.data);
    }

    return null;
  }

  /// 删除分类
  /// categoryId: 分类ID
  /// 返回: 是否删除成功
  Future<bool> deleteCategory(String categoryId) async {
    final response = await _client.delete(
      '${ApiConfig.recipeCategories}/$categoryId',
    );
    return response.isSuccess;
  }
}

