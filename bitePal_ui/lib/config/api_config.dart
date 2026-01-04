/// API配置文件
/// 包含后端服务器地址等配置信息

class ApiConfig {
  /// 开发环境API地址
  static const String devBaseUrl = 'http://localhost:8080/api';

  /// 测试环境API地址
  static const String testBaseUrl = 'https://api-test.bitepal.com/api';

  /// 生产环境API地址
  static const String prodBaseUrl = 'https://api.bitepal.com/api';

  /// 当前使用的API地址（根据环境切换）
  static const String baseUrl = devBaseUrl;

  /// 请求超时时间（秒）
  static const int connectTimeout = 30;

  /// 响应超时时间（秒）
  static const int receiveTimeout = 30;

  // ==================== 认证接口 ====================
  /// 登录接口
  static const String login = '/auth/login';

  /// 注册接口
  static const String register = '/auth/register';

  // ==================== 用户接口 ====================
  /// 获取/更新用户信息
  static const String userInfo = '/user/info';

  /// 获取用户统计数据
  static const String userStats = '/user/stats';

  /// 获取/更新家庭成员偏好
  static const String userPreferences = '/user/preferences';

  // ==================== 菜谱接口 ====================
  /// 我的菜谱列表
  static const String myRecipes = '/recipes/my';

  /// 网络菜谱列表
  static const String publicRecipes = '/recipes/public';

  /// 菜谱详情/创建/更新/删除
  static const String recipes = '/recipes';

  /// 随机推荐菜品
  static const String randomRecipe = '/recipes/random';

  // ==================== 今日菜单接口 ====================
  /// 今日菜单
  static const String todayMenu = '/today-menu';

  /// 今日菜单菜谱操作
  static const String todayMenuRecipes = '/today-menu/recipes';

  // ==================== 点餐接口 ====================
  /// 点餐菜品列表
  static const String mealRecipes = '/meals/recipes';

  /// 点餐订单
  static const String mealOrders = '/meals/orders';

  // ==================== 食材接口 ====================
  /// 食材列表
  static const String ingredients = '/ingredients';

  /// 即将过期食材
  static const String expiringIngredients = '/ingredients/expiring';

  // ==================== 购物清单接口 ====================
  /// 购物清单列表
  static const String shoppingLists = '/shopping-lists';

  /// 当前购物清单
  static const String currentShoppingList = '/shopping-lists/current';

  /// 购物清单历史
  static const String shoppingHistory = '/shopping-lists/history';

  // ==================== 文件上传接口 ====================
  /// 图片上传
  static const String uploadImage = '/upload/image';
}
