import '../config/api_config.dart';
import '../models/recipe.dart';
import 'http_client.dart';

/// 菜谱服务
/// 处理菜谱的增删改查、收藏、随机推荐等
class RecipeService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final RecipeService _instance = RecipeService._internal();

  /// 工厂构造函数
  factory RecipeService() => _instance;

  /// 私有构造函数
  RecipeService._internal();

  /// 获取我的菜谱列表
  /// page: 页码
  /// pageSize: 每页数量
  /// keyword: 搜索关键词
  /// tastes: 口味筛选
  /// difficulty: 难度筛选
  /// cuisines: 菜系筛选
  /// favorite: 是否只显示收藏
  /// 返回: 菜谱列表和分页信息
  Future<PagedData<Recipe>?> getMyRecipes({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    String? tastes,
    String? difficulty,
    String? cuisines,
    bool? favorite,
  }) async {
    final response = await _client.get(
      ApiConfig.myRecipes,
      queryParams: {
        'page': page,
        'pageSize': pageSize,
        if (keyword != null) 'keyword': keyword,
        if (tastes != null) 'tastes': tastes,
        if (difficulty != null) 'difficulty': difficulty,
        if (cuisines != null) 'cuisines': cuisines,
        if (favorite != null) 'favorite': favorite,
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

  /// 获取网络菜谱列表
  /// page: 页码
  /// pageSize: 每页数量
  /// keyword: 搜索关键词
  /// 返回: 菜谱列表和分页信息
  Future<PagedData<Recipe>?> getPublicRecipes({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    String? tastes,
    String? difficulty,
    String? cuisines,
  }) async {
    final response = await _client.get(
      ApiConfig.publicRecipes,
      queryParams: {
        'page': page,
        'pageSize': pageSize,
        if (keyword != null) 'keyword': keyword,
        if (tastes != null) 'tastes': tastes,
        if (difficulty != null) 'difficulty': difficulty,
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

  /// 获取菜谱详情
  /// recipeId: 菜谱ID
  /// 返回: 菜谱详情
  Future<Recipe?> getRecipeDetail(String recipeId) async {
    final response = await _client.get('${ApiConfig.recipes}/$recipeId');

    if (response.isSuccess && response.data != null) {
      return Recipe.fromJson(response.data);
    }

    return null;
  }

  /// 创建菜谱
  /// recipe: 菜谱数据
  /// 返回: 创建后的菜谱
  Future<Recipe?> createRecipe(Recipe recipe) async {
    final response = await _client.post(
      ApiConfig.recipes,
      data: recipe.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      return Recipe.fromJson(response.data);
    }

    return null;
  }

  /// 更新菜谱
  /// recipeId: 菜谱ID
  /// recipe: 菜谱数据
  /// 返回: 更新后的菜谱
  Future<Recipe?> updateRecipe(String recipeId, Recipe recipe) async {
    final response = await _client.put(
      '${ApiConfig.recipes}/$recipeId',
      data: recipe.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      return Recipe.fromJson(response.data);
    }

    return null;
  }

  /// 删除菜谱
  /// recipeId: 菜谱ID
  /// 返回: 是否删除成功
  Future<bool> deleteRecipe(String recipeId) async {
    final response = await _client.delete('${ApiConfig.recipes}/$recipeId');
    return response.isSuccess;
  }

  /// 收藏/取消收藏菜谱
  /// recipeId: 菜谱ID
  /// favorite: 是否收藏
  /// 返回: 是否操作成功
  Future<bool> toggleFavorite(String recipeId, bool favorite) async {
    final response = await _client.post(
      '${ApiConfig.recipes}/$recipeId/favorite',
      data: {'favorite': favorite},
    );
    return response.isSuccess;
  }

  /// 加入我的菜单（从网络菜谱复制）
  /// recipeId: 菜谱ID
  /// 返回: 复制后的菜谱
  Future<Recipe?> addToMyRecipes(String recipeId) async {
    final response = await _client.post(
      '${ApiConfig.recipes}/$recipeId/add-to-my',
    );

    if (response.isSuccess && response.data != null) {
      return Recipe.fromJson(response.data);
    }

    return null;
  }

  /// 随机推荐菜品
  /// mode: 推荐模式（inventory/random/quick）
  /// maxTime: 最大制作时间（分钟，quick模式时使用）
  /// 返回: 推荐的菜谱和理由
  Future<RandomRecipeResult?> randomRecipe({
    String mode = 'random',
    int? maxTime,
  }) async {
    final response = await _client.post(
      ApiConfig.randomRecipe,
      data: {
        'mode': mode,
        if (maxTime != null) 'maxTime': maxTime,
      },
    );

    if (response.isSuccess && response.data != null) {
      Recipe? recipe;
      if (response.data['recipe'] != null) {
        recipe = Recipe.fromJson(response.data['recipe']);
      }
      return RandomRecipeResult(
        recipe: recipe,
        reason: response.data['reason'] ?? '',
      );
    }

    return null;
  }
}

/// 随机推荐结果
class RandomRecipeResult {
  /// 推荐的菜谱
  final Recipe? recipe;

  /// 推荐理由
  final String reason;

  RandomRecipeResult({
    this.recipe,
    required this.reason,
  });
}

