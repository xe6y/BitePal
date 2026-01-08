import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../services/recipe_service.dart';
import '../services/category_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/refreshable_screen.dart';
import 'recipe_detail_screen.dart';

const double _kFilterPanelHorizontalMargin = 20.0; // 筛选面板左右间距
const double _kFilterPanelTopMargin = 18.0; // 筛选面板顶部距父组件高度
const double _kFilterPanelPadding = 24.0; // 筛选面板内边距
const double _kFilterPanelRadius = 28.0; // 筛选面板圆角
const double _kFilterPanelSpacing = 18.0; // 筛选面板内组件垂直间距
const double _kFilterContentMaxHeight = 320.0; // 筛选内容最大高度
const double _kFilterTabSpacing = 12.0; // 筛选类型按钮间距
const double _kFilterTabCornerRadius = 22.0; // 筛选类型按钮圆角
const double _kFilterTabPaddingHorizontal = 18.0; // 筛选类型按钮水平内填充
const double _kFilterTabPaddingVertical = 12.0; // 筛选类型按钮垂直内填充
const double _kFilterTabBorderWidth = 1.0; // 筛选类型按钮边框宽度
const double _kFilterStatusSpacing = 6.0; // 筛选状态图标与文字间距
const double _kFilterResetButtonPaddingHorizontal = 16.0; // 重置按钮水平内填充
const double _kFilterResetButtonPaddingVertical = 8.0; // 重置按钮垂直内填充
const double _kFilterOptionSpacing = 12.0; // 筛选选项之间的间距
const double _kFilterOptionCornerRadius = 16.0; // 筛选选项圆角
const double _kFilterOptionBorderWidth = 1.0; // 筛选选项边框宽度
const Duration _kFilterTabTransitionDuration = Duration(
  milliseconds: 200,
); // 筛选类型动画时长
const List<BoxShadow> _kFilterPanelShadows = [
  BoxShadow(
    color: Color(0x28000000),
    offset: Offset(0, 22),
    blurRadius: 40,
    spreadRadius: 1,
  ),
  BoxShadow(
    color: Color(0x14ffffff),
    offset: Offset(0, -8),
    blurRadius: 30,
    spreadRadius: 0,
  ),
];
const List<BoxShadow> _kFilterTabShadows = [
  BoxShadow(
    color: Color(0x1e000000),
    offset: Offset(0, 8),
    blurRadius: 20,
    spreadRadius: 0,
  ),
  BoxShadow(
    color: Color(0x15ffffff),
    offset: Offset(0, -4),
    blurRadius: 18,
    spreadRadius: 0,
  ),
];
const List<BoxShadow> _kFilterTabActiveShadows = [
  BoxShadow(
    color: Color(0x34000000),
    offset: Offset(0, 12),
    blurRadius: 30,
    spreadRadius: 0,
  ),
  BoxShadow(
    color: Color(0x18ffffff),
    offset: Offset(0, -6),
    blurRadius: 22,
    spreadRadius: 0,
  ),
];

/// 菜谱页面
class RecipesScreen extends RefreshableScreen {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with RefreshableScreenState<RecipesScreen> {
  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 分类服务
  final CategoryService _categoryService = CategoryService();

  /// 当前选中的标签页
  String _activeTab = "my";

  /// 是否展开筛选面板
  bool _filterExpanded = false;

  /// 当前选中的筛选类型
  String? _activeFilterType;

  /// 搜索关键词
  String _searchKeyword = '';

  /// 选中的口味
  final List<String> _selectedTastes = [];

  /// 选中的难度
  final List<String> _selectedDifficulties = [];

  /// 选中的菜系
  final List<String> _selectedCuisines = [];

  /// 口味分类列表
  List<RecipeCategory> _tasteCategories = [];

  /// 难度分类列表
  List<RecipeCategory> _difficultyCategories = [];

  /// 菜系分类列表
  List<RecipeCategory> _cuisineCategories = [];

  /// 我的菜谱列表
  List<Recipe> _myRecipes = [];

  /// 网络菜谱列表
  List<Recipe> _onlineRecipes = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRecipes();
  }

  /// 加载分类数据
  Future<void> _loadCategories() async {
    try {
      final results = await Future.wait([
        _categoryService.getCategoriesByType('taste'),
        _categoryService.getCategoriesByType('difficulty'),
        _categoryService.getCategoriesByType('cuisine'),
      ]);

      if (mounted) {
        setState(() {
          _tasteCategories = results[0] ?? [];
          _difficultyCategories = results[1] ?? [];
          _cuisineCategories = results[2] ?? [];
        });
      }
    } catch (e) {
      debugPrint('加载分类失败: $e');
      // 使用默认分类作为后备
      _loadDefaultCategories();
    }
  }

  /// 加载默认分类（作为后备）
  void _loadDefaultCategories() {
    _tasteCategories = [
      RecipeCategory(
        id: '1',
        type: 'taste',
        name: '清淡',
        sortOrder: 1,
        isActive: true,
      ),
      RecipeCategory(
        id: '2',
        type: 'taste',
        name: '咸鲜',
        sortOrder: 2,
        isActive: true,
      ),
      RecipeCategory(
        id: '3',
        type: 'taste',
        name: '酸',
        sortOrder: 3,
        isActive: true,
      ),
      RecipeCategory(
        id: '4',
        type: 'taste',
        name: '甜',
        sortOrder: 4,
        isActive: true,
      ),
      RecipeCategory(
        id: '5',
        type: 'taste',
        name: '麻',
        sortOrder: 5,
        isActive: true,
      ),
      RecipeCategory(
        id: '6',
        type: 'taste',
        name: '辣',
        sortOrder: 6,
        isActive: true,
      ),
    ];
    _difficultyCategories = [
      RecipeCategory(
        id: '1',
        type: 'difficulty',
        name: '简单',
        sortOrder: 1,
        isActive: true,
      ),
      RecipeCategory(
        id: '2',
        type: 'difficulty',
        name: '中等',
        sortOrder: 2,
        isActive: true,
      ),
      RecipeCategory(
        id: '3',
        type: 'difficulty',
        name: '困难',
        sortOrder: 3,
        isActive: true,
      ),
    ];
    _cuisineCategories = [
      RecipeCategory(
        id: '1',
        type: 'cuisine',
        name: '家常菜',
        sortOrder: 1,
        isActive: true,
      ),
      RecipeCategory(
        id: '2',
        type: 'cuisine',
        name: '川菜',
        sortOrder: 2,
        isActive: true,
      ),
      RecipeCategory(
        id: '3',
        type: 'cuisine',
        name: '粤菜',
        sortOrder: 3,
        isActive: true,
      ),
      RecipeCategory(
        id: '4',
        type: 'cuisine',
        name: '浙菜',
        sortOrder: 4,
        isActive: true,
      ),
      RecipeCategory(
        id: '5',
        type: 'cuisine',
        name: '湘菜',
        sortOrder: 5,
        isActive: true,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> refresh() async {
    await _loadRecipes();
  }

  /// 加载菜谱数据
  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);

    try {
      // 构建筛选参数
      final tastes = _selectedTastes.isNotEmpty
          ? _selectedTastes.join(',')
          : null;
      final difficulty = _selectedDifficulties.isNotEmpty
          ? _selectedDifficulties.join(',')
          : null;
      final cuisines = _selectedCuisines.isNotEmpty
          ? _selectedCuisines.join(',')
          : null;

      if (_activeTab == "my") {
        final result = await _recipeService.getMyRecipes(
          keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
          tastes: tastes,
          difficulty: difficulty,
          cuisines: cuisines,
        );
        if (result != null) {
          _myRecipes = result.list;
        }
      } else {
        final result = await _recipeService.getPublicRecipes(
          keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
          tastes: tastes,
          difficulty: difficulty,
          cuisines: cuisines,
        );
        if (result != null) {
          _onlineRecipes = result.list;
        }
      }
    } catch (e) {
      debugPrint('加载菜谱失败: $e');
      // 使用模拟数据作为后备
      _loadMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 加载模拟数据
  void _loadMockData() {
    _myRecipes = [
      Recipe(
        id: '1',
        name: "番茄炒蛋",
        time: "15分钟",
        difficulty: "简单",
        tags: ["常做"],
        tagColors: ["bg-blue-500"],
        favorite: true,
        categories: ["家常菜", "酸甜"],
      ),
      Recipe(
        id: '4',
        name: "红烧肉",
        image: "/images/image.png",
        time: "45分钟",
        difficulty: "中等",
        tags: ["常做"],
        tagColors: ["bg-blue-500", "bg-pink-500"],
        favorite: false,
        categories: ["川菜", "咸鲜"],
      ),
      Recipe(
        id: '3',
        name: "清蒸鲈鱼",
        image: "/images/image.png",
        time: "25分钟",
        difficulty: "简单",
        tags: ["常做"],
        tagColors: ["bg-blue-500"],
        favorite: true,
        categories: ["粤菜", "清淡"],
      ),
      Recipe(
        id: '6',
        name: "酸辣土豆丝",
        time: "10分钟",
        difficulty: "简单",
        tags: ["常做"],
        tagColors: ["bg-blue-500", "bg-pink-500"],
        favorite: true,
        categories: ["家常菜", "酸辣"],
      ),
    ];

    _onlineRecipes = [
      Recipe(
        id: '101',
        name: "宫保鸡丁",
        image: "/images/image.png",
        time: "30分钟",
        difficulty: "中等",
        tags: ["热门", "川菜"],
        tagColors: ["bg-red-500", "bg-orange-500"],
        favorite: false,
        categories: ["川菜", "麻辣"],
      ),
      Recipe(
        id: '102',
        name: "糖醋里脊",
        image: "/images/image.png",
        time: "25分钟",
        difficulty: "中等",
        tags: ["热门", "酸甜"],
        tagColors: ["bg-red-500", "bg-yellow-500"],
        favorite: false,
        categories: ["鲁菜", "酸甜"],
      ),
      Recipe(
        id: '103',
        name: "麻婆豆腐",
        image: "/images/image.png",
        time: "20分钟",
        difficulty: "简单",
        tags: ["素食", "下饭"],
        tagColors: ["bg-green-500", "bg-blue-500"],
        favorite: false,
        categories: ["川菜", "麻辣"],
      ),
    ];
  }

  /// 获取当前显示的菜谱列表
  List<Recipe> get _currentRecipes {
    return _activeTab == "my" ? _myRecipes : _onlineRecipes;
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(Recipe recipe) async {
    final success = await _recipeService.toggleFavorite(
      recipe.id,
      !recipe.favorite,
    );
    if (success) {
      setState(() {
        final index = _activeTab == "my"
            ? _myRecipes.indexWhere((r) => r.id == recipe.id)
            : _onlineRecipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          if (_activeTab == "my") {
            _myRecipes[index] = _myRecipes[index].copyWith(
              favorite: !recipe.favorite,
            );
          } else {
            _onlineRecipes[index] = _onlineRecipes[index].copyWith(
              favorite: !recipe.favorite,
            );
          }
        }
      });
    }
  }

  /// 搜索菜谱
  void _onSearch(String keyword) {
    _searchKeyword = keyword;
    _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  // 主内容区域
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadRecipes,
                          child: _buildRecipeGrid(),
                        ),
                  // 筛选浮动面板（在搜索栏下方浮动）
                  if (_filterExpanded) _buildFloatingFilterPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "recipes_fab",
        onPressed: () async {
          // 跳转到创建菜谱页面
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecipeDetailScreen(
                isCreateMode: true,
              ),
            ),
          );
          // 如果创建成功，刷新列表
          if (result == true) {
            _loadRecipes();
          }
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "菜谱",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // 标签切换
          Row(
            children: [
              Expanded(
                child: _buildTabButton("我的菜谱", _activeTab == "my", () {
                  setState(() => _activeTab = "my");
                  _loadRecipes();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTabButton("网络菜谱", _activeTab == "online", () {
                  setState(() => _activeTab = "online");
                  _loadRecipes();
                }, enabled: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 搜索和筛选
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "搜索菜谱...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _onSearch,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white),
                  onPressed: () {
                    setState(() => _filterExpanded = !_filterExpanded);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建浮动筛选面板
  Widget _buildFloatingFilterPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          // 点击背景关闭筛选面板
          setState(() {
            _filterExpanded = false;
            _activeFilterType = null;
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _kFilterPanelHorizontalMargin,
                _kFilterPanelTopMargin,
                _kFilterPanelHorizontalMargin,
                0,
              ),
              child: GestureDetector(
                onTap: () {}, // 阻止点击事件传递到背景
                child: _buildFilterPanel(colorScheme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建筛选面板容器
  Widget _buildFilterPanel(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(_kFilterPanelRadius),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
          width: _kFilterOptionBorderWidth,
        ),
        boxShadow: _kFilterPanelShadows,
      ),
      padding: const EdgeInsets.all(_kFilterPanelPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterPanelHeader(),
          if (_activeFilterType != null) ...[
            const SizedBox(height: _kFilterPanelSpacing),
            Container(
              constraints: const BoxConstraints(
                maxHeight: _kFilterContentMaxHeight,
              ),
              child: SingleChildScrollView(child: _buildFilterContent()),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建筛选面板标题和类型布局
  Widget _buildFilterPanelHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '筛选',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTastes.clear();
                  _selectedDifficulties.clear();
                  _selectedCuisines.clear();
                });
                _loadRecipes();
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: _kFilterResetButtonPaddingHorizontal,
                  vertical: _kFilterResetButtonPaddingVertical,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: const Text('重置'),
            ),
          ],
        ),
        const SizedBox(height: _kFilterTabSpacing),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterTypeTab('taste', '口味', _selectedTastes.isNotEmpty),
              const SizedBox(width: _kFilterTabSpacing),
              _buildFilterTypeTab(
                'difficulty',
                '难度',
                _selectedDifficulties.isNotEmpty,
              ),
              const SizedBox(width: _kFilterTabSpacing),
              _buildFilterTypeTab(
                'cuisine',
                '菜系',
                _selectedCuisines.isNotEmpty,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建筛选类型标签
  Widget _buildFilterTypeTab(String type, String label, bool hasSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = _activeFilterType == type;

    return InkWell(
      borderRadius: BorderRadius.circular(_kFilterTabCornerRadius),
      onTap: () {
        setState(() {
          if (_activeFilterType == type) {
            _activeFilterType = null;
          } else {
            _activeFilterType = type;
          }
        });
      },
      child: AnimatedContainer(
        duration: _kFilterTabTransitionDuration,
        padding: const EdgeInsets.symmetric(
          horizontal: _kFilterTabPaddingHorizontal,
          vertical: _kFilterTabPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : hasSelected
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(_kFilterTabCornerRadius),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : colorScheme.onSurface.withValues(alpha: 0.08),
            width: _kFilterTabBorderWidth,
          ),
          boxShadow: isActive ? _kFilterTabActiveShadows : _kFilterTabShadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? colorScheme.onPrimary
                    : hasSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: hasSelected || isActive
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
            if (hasSelected) ...[
              const SizedBox(width: _kFilterStatusSpacing),
              Icon(
                Icons.check_circle,
                size: 18,
                color: isActive ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建筛选内容
  Widget _buildFilterContent() {
    final colorScheme = Theme.of(context).colorScheme;

    switch (_activeFilterType) {
      case 'taste':
        return _buildFilterOptionGrid(
          _tasteCategories.map((category) => category.name).toList(),
          _selectedTastes,
          (taste) {
            setState(() {
              if (_selectedTastes.contains(taste)) {
                _selectedTastes.remove(taste);
              } else {
                _selectedTastes.add(taste);
              }
            });
            _loadRecipes();
          },
          colorScheme,
        );
      case 'difficulty':
        return _buildFilterOptionGrid(
          _difficultyCategories.map((category) => category.name).toList(),
          _selectedDifficulties,
          (difficulty) {
            setState(() {
              if (_selectedDifficulties.contains(difficulty)) {
                _selectedDifficulties.remove(difficulty);
              } else {
                _selectedDifficulties.add(difficulty);
              }
            });
            _loadRecipes();
          },
          colorScheme,
        );
      case 'cuisine':
        return _buildFilterOptionGrid(
          _cuisineCategories.map((category) => category.name).toList(),
          _selectedCuisines,
          (cuisine) {
            setState(() {
              if (_selectedCuisines.contains(cuisine)) {
                _selectedCuisines.remove(cuisine);
              } else {
                _selectedCuisines.add(cuisine);
              }
            });
            _loadRecipes();
          },
          colorScheme,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建筛选选项网格
  Widget _buildFilterOptionGrid(
    List<String> options,
    List<String> selected,
    Function(String) onToggle,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: _kFilterOptionSpacing,
      runSpacing: _kFilterOptionSpacing,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_kFilterOptionCornerRadius),
            onTap: () => onToggle(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.2,
                      ),
                borderRadius: BorderRadius.circular(_kFilterOptionCornerRadius),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.08),
                  width: _kFilterOptionBorderWidth,
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建菜谱网格
  Widget _buildRecipeGrid() {
    if (_currentRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _activeTab == "my" ? "暂无菜谱，快去添加吧！" : "暂无网络菜谱",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _currentRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _currentRecipes[index];
          return RecipeCard(
            recipe: recipe,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(
                    recipeId: recipe.id,
                    isFromMyRecipes: _activeTab == "my",
                  ),
                ),
              );
              // 如果返回值为 true，刷新列表
              if (result == true) {
                _loadRecipes();
              }
            },
            onFavorite: () => _toggleFavorite(recipe),
          );
        },
      ),
    );
  }

  /// 构建标签按钮
  Widget _buildTabButton(
    String label,
    bool isActive,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: isActive
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
