import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/today_menu.dart';
import 'menu_service.dart';
import 'recipe_service.dart';

/// 全局状态管理器
/// 使用单例模式管理已点菜品状态，支持多页面同步
class TodayMenuState extends ChangeNotifier {
  /// 单例实例
  static final TodayMenuState _instance = TodayMenuState._internal();

  /// 工厂构造函数
  factory TodayMenuState() => _instance;

  /// 私有构造函数
  TodayMenuState._internal();

  /// 菜单服务
  final MenuService _menuService = MenuService();

  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 今日菜单数据（从服务器获取，展示用）
  TodayMenu? _todayMenu;

  /// 今日菜单中的菜谱数据（展示用）
  final List<Recipe> _menuRecipes = [];

  /// 已点的菜品列表（用于点餐页面）
  final List<Recipe> _selectedMeals = [];

  /// 是否正在加载
  bool _isLoading = false;

  /// 获取今日菜单
  TodayMenu? get todayMenu => _todayMenu;

  /// 获取已点菜品列表
  List<Recipe> get selectedMeals => List.unmodifiable(_selectedMeals);

  /// 获取今日菜单中的菜谱（展示用）
  List<Recipe> get menuRecipes => List.unmodifiable(_menuRecipes);

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 检查菜谱是否已点
  /// recipeId: 菜谱ID
  /// 返回: 是否已点
  bool isSelected(String recipeId) {
    return _selectedMeals.any((recipe) => recipe.id == recipeId);
  }

  /// 加载今日菜单（展示用）
  /// 从服务器获取今日菜单数据
  Future<void> loadTodayMenu() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _todayMenu = await _menuService.getTodayMenu();
      _menuRecipes.clear();

      if (_todayMenu != null && _todayMenu!.recipes.isNotEmpty) {
        for (final menuRecipe in _todayMenu!.recipes) {
          // 获取完整菜谱数据
          try {
            final recipe = await _recipeService.getRecipeDetail(
              menuRecipe.recipeId,
            );
            if (recipe != null) {
              _menuRecipes.add(recipe);
            }
          } catch (e) {
            debugPrint('加载菜谱详情失败: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('加载今日菜单失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 添加到已点菜品
  /// recipe: 菜谱
  void addToSelected(Recipe recipe) {
    if (!_selectedMeals.any((r) => r.id == recipe.id)) {
      _selectedMeals.add(recipe);
      notifyListeners();
    }
  }

  /// 从已点菜品移除
  /// recipeId: 菜谱ID
  void removeFromSelected(String recipeId) {
    _selectedMeals.removeWhere((recipe) => recipe.id == recipeId);
    notifyListeners();
  }

  /// 切换已点状态
  /// recipe: 菜谱
  /// 返回: 操作后是否已点
  bool toggleSelected(Recipe recipe) {
    final isCurrentlySelected = _selectedMeals.any((r) => r.id == recipe.id);
    if (isCurrentlySelected) {
      removeFromSelected(recipe.id);
      return false;
    } else {
      addToSelected(recipe);
      return true;
    }
  }

  /// 清空已点菜品
  void clearSelected() {
    _selectedMeals.clear();
    notifyListeners();
  }

  /// 获取已点菜品数量
  int get selectedCount => _selectedMeals.length;

  /// 刷新今日菜单（确认点餐后调用）
  Future<void> refreshTodayMenu() async {
    await loadTodayMenu();
  }
}
