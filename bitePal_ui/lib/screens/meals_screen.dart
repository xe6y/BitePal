import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/meal_order.dart';
import '../models/today_menu.dart';
import '../services/meal_service.dart';
import '../services/menu_service.dart';
import '../services/recipe_service.dart';
import '../services/http_client.dart';
import '../widgets/recipe_card.dart';
import '../utils/app_constants.dart';
import 'recipe_detail_screen.dart';

/// 家庭点餐页面
class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  /// 点餐服务
  final MealService _mealService = MealService();

  /// 菜单服务
  final MenuService _menuService = MenuService();

  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 是否展开筛选面板
  bool _filterExpanded = false;

  /// 是否正在加载
  bool _isLoading = true;

  /// 选中的口味
  final List<String> _selectedTastes = [];


  /// 选中的菜系
  final List<String> _selectedCuisines = [];

  /// 已点的菜品列表
  final List<Recipe> _selectedMeals = [];

  /// 菜谱列表
  List<Recipe> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  /// 加载菜谱数据
  /// 只显示家庭菜单和收藏的菜谱
  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);

    try {
      // 并行获取今日菜单和收藏的菜谱
      final results = await Future.wait([
        _menuService.getTodayMenu(),
        _recipeService.getMyRecipes(favorite: true),
      ]);

      final todayMenu = results[0] as TodayMenu?;
      final favoriteRecipesResult = results[1] as PagedData<Recipe>?;

      final List<Recipe> allRecipes = [];

      // 添加今日菜单中的菜谱
      if (todayMenu != null && todayMenu.recipes.isNotEmpty) {
        final menuRecipeIds = todayMenu.recipes.map((r) => r.recipeId).toList();
        for (final recipeId in menuRecipeIds) {
          try {
            final recipe = await _recipeService.getRecipeDetail(recipeId);
            if (recipe != null) {
              allRecipes.add(recipe);
            }
          } catch (e) {
            debugPrint('加载菜单菜谱详情失败: $e');
          }
        }
      }

      // 添加收藏的菜谱
      if (favoriteRecipesResult != null && favoriteRecipesResult.list.isNotEmpty) {
        allRecipes.addAll(favoriteRecipesResult.list);
      }

      // 根据筛选条件过滤
      List<Recipe> filteredRecipes = allRecipes;

      if (_selectedTastes.isNotEmpty) {
        filteredRecipes = filteredRecipes.where((recipe) {
          return _selectedTastes.any((taste) => recipe.categories.contains(taste));
        }).toList();
      }

      if (_selectedCuisines.isNotEmpty) {
        filteredRecipes = filteredRecipes.where((recipe) {
          return _selectedCuisines.any((cuisine) => recipe.categories.contains(cuisine));
        }).toList();
      }

      // 去重（根据 ID）
      final Map<String, Recipe> uniqueRecipes = {};
      for (final recipe in filteredRecipes) {
        if (!uniqueRecipes.containsKey(recipe.id)) {
          uniqueRecipes[recipe.id] = recipe;
        }
      }

      _recipes = uniqueRecipes.values.toList();
    } catch (e) {
      debugPrint('加载菜谱失败: $e');
      _loadMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 加载模拟数据
  void _loadMockData() {
    _recipes = [
      Recipe(
        id: '1',
        name: "番茄炒蛋",
        time: "15分钟",
        difficulty: "简单",
        tags: ["食材充足", "低热量"],
        tagColors: ["bg-green-500", "bg-green-500"],
        favorite: false,
        categories: ["酸", "甜"],
      ),
      Recipe(
        id: '2',
        name: "麻婆豆腐",
        time: "45分钟",
        difficulty: "中等",
        tags: ["中热量"],
        tagColors: ["bg-amber-500"],
        favorite: false,
        categories: ["麻", "辣"],
      ),
      Recipe(
        id: '3',
        name: "清蒸鲈鱼",
        image: "/images/image.png",
        time: "25分钟",
        difficulty: "简单",
        tags: ["食材充足", "低热量"],
        tagColors: ["bg-green-500", "bg-green-500"],
        favorite: false,
        categories: ["粤菜", "清淡"],
      ),
      Recipe(
        id: '4',
        name: "红烧肉",
        image: "/images/image.png",
        time: "45分钟",
        difficulty: "中等",
        tags: ["食材充足", "高热量"],
        tagColors: ["bg-green-500", "bg-red-500"],
        favorite: false,
        categories: ["甜"],
      ),
    ];
  }

  /// 确认点餐
  Future<void> _confirmOrder() async {
    if (_selectedMeals.isEmpty) return;

    final orderRecipes = _selectedMeals
        .map((r) => OrderRecipe(recipeId: r.id, recipeName: r.name))
        .toList();

    final order = await _mealService.createMealOrder(orderRecipes);
    if (order != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已提交 ${_selectedMeals.length} 道菜品'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _selectedMeals.clear());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(theme, colorScheme),
            if (_filterExpanded) _buildFilterSection(theme, colorScheme),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadRecipes,
                      child: _buildRecipeGrid(theme),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedMeals.isNotEmpty ? _buildModernFAB(colorScheme) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// 构建头部区域
  Widget _buildHeaderSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingXL,
        AppConstants.spacingXL,
        AppConstants.spacingXL,
        AppConstants.spacingL,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "家庭点餐",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.2,
              inherit: false,
            ),
          ),
          SizedBox(height: AppConstants.spacingXL),
          Row(
            children: [
              Expanded(child: _buildSearchField(theme, colorScheme)),
              SizedBox(width: AppConstants.spacingL),
              _buildFilterButton(theme, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchField(ThemeData theme, ColorScheme colorScheme) {
    return TextField(
      decoration: InputDecoration(
        hintText: "搜索菜名...",
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: AppConstants.textSizeL,
          textBaseline: TextBaseline.alphabetic,
          inherit: false,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          size: 20,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXL,
          vertical: AppConstants.spacingL,
        ),
      ),
      style: TextStyle(
        fontSize: AppConstants.textSizeL,
        color: colorScheme.onSurface,
        textBaseline: TextBaseline.alphabetic,
        inherit: false,
      ),
      onSubmitted: (value) => _loadRecipes(),
    );
  }

  /// 构建筛选按钮
  Widget _buildFilterButton(ThemeData theme, ColorScheme colorScheme) {
    return Material(
      color: _filterExpanded ? colorScheme.primaryContainer : colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (!mounted) return;
          setState(() => _filterExpanded = !_filterExpanded);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: Icon(
            Icons.tune_rounded,
            color: _filterExpanded ? colorScheme.onPrimaryContainer : colorScheme.onPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }

  /// 构建筛选区域
  Widget _buildFilterSection(ThemeData theme, ColorScheme colorScheme) {
    if (!_filterExpanded) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          AppConstants.spacingXL,
          0,
          AppConstants.spacingXL,
          AppConstants.spacingL,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterChipSection(theme, colorScheme, "口味", ["酸", "甜", "苦", "麻", "辣"], _selectedTastes, (taste) {
                if (!mounted) return;
                setState(() {
                  if (_selectedTastes.contains(taste)) {
                    _selectedTastes.remove(taste);
                  } else {
                    _selectedTastes.add(taste);
                  }
                });
                _loadRecipes();
              }),
              SizedBox(height: AppConstants.spacingXL),
              _buildFilterChipSection(theme, colorScheme, "菜系", ["川菜", "粤菜", "鲁菜", "西餐"], _selectedCuisines, (cuisine) {
                if (!mounted) return;
                setState(() {
                  if (_selectedCuisines.contains(cuisine)) {
                    _selectedCuisines.remove(cuisine);
                  } else {
                    _selectedCuisines.add(cuisine);
                  }
                });
                _loadRecipes();
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建菜品网格
  Widget _buildRecipeGrid(ThemeData theme) {
    if (_recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "暂无菜品",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingXL),
      child: GridView.builder(
        padding: EdgeInsets.only(
          top: AppConstants.spacingL,
          bottom: AppConstants.spacingXXL + 20,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.spacingXL,
          mainAxisSpacing: AppConstants.spacingXL,
          childAspectRatio: 0.65,
        ),
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          final isAdded = _selectedMeals.any((meal) => meal.id == recipe.id);
          return RecipeCard(
            recipe: recipe,
            isAdded: isAdded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
                ),
              );
            },
            onAdd: () {
              if (!mounted) return;
              setState(() {
                if (!isAdded) {
                  // 添加到点餐单
                  _selectedMeals.add(recipe);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已添加 ${recipe.name}'),
                        duration: AppConstants.snackBarDuration,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } else {
                  // 从点餐单移除
                  _selectedMeals.removeWhere((meal) => meal.id == recipe.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已移除 ${recipe.name}'),
                        duration: AppConstants.snackBarDuration,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              });
            },
          );
        },
      ),
    );
  }

  /// 构建现代化的FAB
  Widget _buildModernFAB(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (mounted) _showMealListDialog();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacingXL,
              vertical: AppConstants.spacingL,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded, color: colorScheme.onPrimary, size: 22),
                SizedBox(width: AppConstants.spacingM),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingM, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedMeals.length}',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: AppConstants.textSizeS,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      inherit: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示点餐清单对话框
  void _showMealListDialog() {
    if (!mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              final currentMeals = List<Recipe>.from(_selectedMeals);
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: AppConstants.spacingL),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        AppConstants.spacingXL,
                        AppConstants.spacingXL,
                        AppConstants.spacingXL,
                        AppConstants.spacingL,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '已点菜品',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              inherit: false,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingL,
                              vertical: AppConstants.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '共 ${currentMeals.length} 道',
                              style: TextStyle(
                                fontSize: AppConstants.textSizeM,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                                inherit: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: currentMeals.isEmpty
                          ? _buildEmptyState(theme, colorScheme)
                          : ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.all(AppConstants.spacingXL),
                              itemCount: currentMeals.length,
                              itemBuilder: (context, index) {
                                final meal = currentMeals[index];
                                return _buildMealListItem(theme, colorScheme, meal, index, setModalState);
                              },
                            ),
                    ),
                    if (currentMeals.isNotEmpty) _buildBottomActionBar(theme, colorScheme),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacingXXL),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: AppConstants.spacingXL),
          Text(
            '还没有点任何菜品',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              inherit: false,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建菜品列表项
  Widget _buildMealListItem(
    ThemeData theme,
    ColorScheme colorScheme,
    Recipe meal,
    int index,
    StateSetter setModalState,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXL,
          vertical: AppConstants.spacingM,
        ),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/chinese-potato-strips.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.restaurant_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        title: Text(
          meal.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: AppConstants.spacingXS),
          child: Text(
            '${meal.time} · ${meal.difficulty}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              inherit: false,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        trailing: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!mounted) return;
              setState(() {
                if (index < _selectedMeals.length) {
                  _selectedMeals.removeAt(index);
                }
              });
              setModalState(() {});
              if (_selectedMeals.isEmpty && mounted) {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(AppConstants.spacingM),
              child: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActionBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingXL,
        AppConstants.spacingL,
        AppConstants.spacingXL,
        AppConstants.spacingXL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (!mounted) return;
                setState(() => _selectedMeals.clear());
                if (mounted) Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppConstants.spacingL),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Text(
                '清空清单',
                style: TextStyle(
                  fontSize: AppConstants.textSizeL,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  inherit: false,
                ),
              ),
            ),
          ),
          SizedBox(width: AppConstants.spacingL),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: AppConstants.spacingL),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                '确认点餐',
                style: TextStyle(
                  fontSize: AppConstants.textSizeL,
                  fontWeight: FontWeight.w700,
                  inherit: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选芯片区块
  Widget _buildFilterChipSection(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    List<String> options,
    List<String> selected,
    Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            letterSpacing: 0.2,
            inherit: false,
          ),
        ),
        SizedBox(height: AppConstants.spacingL),
        Wrap(
          spacing: AppConstants.spacingM,
          runSpacing: AppConstants.spacingM,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onToggle(option),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                    vertical: AppConstants.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeM,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      inherit: false,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
