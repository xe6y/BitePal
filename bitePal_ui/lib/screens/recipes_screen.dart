import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/refreshable_screen.dart';
import 'recipe_detail_screen.dart';

/// 菜谱页面
class RecipesScreen extends RefreshableScreen {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with RefreshableScreenState<RecipesScreen> {
  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 当前选中的标签页
  String _activeTab = "my";

  /// 是否展开筛选面板
  bool _filterExpanded = false;

  /// 搜索关键词
  String _searchKeyword = '';

  /// 选中的口味
  final List<String> _selectedTastes = [];

  /// 选中的难度
  final List<String> _selectedDifficulty = [];

  /// 选中的菜系
  final List<String> _selectedCuisines = [];

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
    _loadRecipes();
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
      final tastes = _selectedTastes.isNotEmpty ? _selectedTastes.join(',') : null;
      final difficulty = _selectedDifficulty.isNotEmpty ? _selectedDifficulty.join(',') : null;
      final cuisines = _selectedCuisines.isNotEmpty ? _selectedCuisines.join(',') : null;

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
    final success = await _recipeService.toggleFavorite(recipe.id, !recipe.favorite);
    if (success) {
      setState(() {
        final index = _activeTab == "my"
            ? _myRecipes.indexWhere((r) => r.id == recipe.id)
            : _onlineRecipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          if (_activeTab == "my") {
            _myRecipes[index] = _myRecipes[index].copyWith(favorite: !recipe.favorite);
          } else {
            _onlineRecipes[index] = _onlineRecipes[index].copyWith(favorite: !recipe.favorite);
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadRecipes,
                      child: _buildRecipeGrid(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "recipes_fab",
        onPressed: () {
          // 添加菜谱
        },
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
                child: _buildTabButton(
                  "网络菜谱",
                  _activeTab == "online",
                  () {
                    setState(() => _activeTab = "online");
                    _loadRecipes();
                  },
                  enabled: true,
                ),
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
          // 筛选面板
          if (_filterExpanded) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(
                      "口味",
                      ["清淡", "咸鲜", "酸甜", "麻辣", "酸辣"],
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
                    ),
                    const SizedBox(height: 16),
                    _buildFilterSection(
                      "难度",
                      ["简单", "中等", "困难"],
                      _selectedDifficulty,
                      (difficulty) {
                        setState(() {
                          if (_selectedDifficulty.contains(difficulty)) {
                            _selectedDifficulty.remove(difficulty);
                          } else {
                            _selectedDifficulty.add(difficulty);
                          }
                        });
                        _loadRecipes();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFilterSection(
                      "菜系",
                      ["家常菜", "川菜", "粤菜", "浙菜", "湘菜"],
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _activeTab == "my" ? "暂无菜谱，快去添加吧！" : "暂无网络菜谱",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(
                    recipeId: recipe.id,
                    isFromMyRecipes: _activeTab == "my",
                  ),
                ),
              );
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

  /// 构建筛选区块
  Widget _buildFilterSection(
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) => onToggle(option),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
            );
          }).toList(),
        ),
      ],
    );
  }
}
