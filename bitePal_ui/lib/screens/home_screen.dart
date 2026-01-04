import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';
import '../models/today_menu.dart';
import '../services/menu_service.dart';
import '../services/ingredient_service.dart';
import '../services/recipe_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/random_meal_dialog.dart';
import 'recipe_detail_screen.dart';
import 'profile_screen.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 菜单服务
  final MenuService _menuService = MenuService();

  /// 食材服务
  final IngredientService _ingredientService = IngredientService();

  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 今日菜单
  TodayMenu? _todayMenu;

  /// 今日菜谱列表
  List<Recipe> _todayRecipes = [];

  /// 即将过期食材列表
  List<IngredientItem> _expiringIngredients = [];

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 并行加载今日菜单和即将过期食材
      final results = await Future.wait([
        _menuService.getTodayMenu(),
        _ingredientService.getExpiringIngredients(days: 3),
      ]);

      _todayMenu = results[0] as TodayMenu?;
      _expiringIngredients = results[1] as List<IngredientItem>;

      // 根据今日菜单获取菜谱详情
      if (_todayMenu != null && _todayMenu!.recipes.isNotEmpty) {
        final recipeDetails = await Future.wait(
          _todayMenu!.recipes.map((r) => _recipeService.getRecipeDetail(r.recipeId)),
        );
        _todayRecipes = recipeDetails.whereType<Recipe>().toList();
      }
    } catch (e) {
      debugPrint('加载数据失败: $e');
      // 使用模拟数据作为后备
      _loadMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 加载模拟数据（当API不可用时）
  void _loadMockData() {
    _todayRecipes = [
      Recipe(
        id: '1',
        name: "番茄炒蛋",
        time: "15 分钟",
        difficulty: "简单",
        tags: ["常做"],
        tagColors: ["bg-blue-500"],
        favorite: false,
        categories: ["家常菜", "酸甜"],
      ),
      Recipe(
        id: '4',
        name: "红烧肉",
        time: "45 分钟",
        difficulty: "中等",
        tags: ["常做"],
        tagColors: ["bg-blue-500"],
        favorite: false,
        categories: ["川菜", "咸鲜"],
      ),
    ];

    _expiringIngredients = [
      IngredientItem(
        id: '1',
        name: "生菜",
        amount: "1颗",
        storage: "fridge",
        icon: "🥬",
        expiryDays: 0,
        expiryText: "今天",
        urgent: true,
      ),
      IngredientItem(
        id: '2',
        name: "培根",
        amount: "200g",
        storage: "fridge",
        icon: "🥓",
        expiryDays: 1,
        expiryText: "明天",
        urgent: false,
      ),
      IngredientItem(
        id: '3',
        name: "牛奶",
        amount: "500ml",
        storage: "fridge",
        icon: "🥛",
        expiryDays: 3,
        expiryText: "3天后",
        urgent: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildTodayMenu(),
                      const SizedBox(height: 24),
                      if (_expiringIngredients.isNotEmpty) ...[
                        _buildIngredientAlert(),
                        const SizedBox(height: 24),
                        _buildExpiringSoon(),
                        const SizedBox(height: 24),
                      ],
                      _buildQuickAction(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "做伴",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "你的做饭伴侣",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB84D), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/cartoon-avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建今日菜单
  Widget _buildTodayMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "今日菜单",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (_todayRecipes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "今日暂无菜单",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          // 导航到菜谱页面添加菜谱
                        },
                        child: const Text("添加菜谱"),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _todayRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _todayRecipes[index];
                  return Container(
                    width: 256,
                    margin: EdgeInsets.only(
                      right: index < _todayRecipes.length - 1 ? 16 : 0,
                    ),
                    child: RecipeCard(
                      recipe: recipe,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 构建食材提醒卡片
  Widget _buildIngredientAlert() {
    final urgentCount = _expiringIngredients.where((i) => i.urgent).length;
    final ingredientNames = _expiringIngredients.take(3).map((i) => i.name).join('、');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.amber.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber.shade500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_expiringIngredients.length} 种食材即将过期${urgentCount > 0 ? '（$urgentCount种今天）' : ''}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "建议优先使用：$ingredientNames",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // 导航到食材页面
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "查看详情",
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建即将过期列表
  Widget _buildExpiringSoon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "即将过期",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // 导航到食材页面
                },
                child: const Text("查看全部"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: _expiringIngredients.map((ingredient) {
                return ListTile(
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ingredient.urgent ? Colors.red : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(ingredient.name),
                  subtitle: Text(ingredient.amount),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ingredient.urgent ? Colors.red.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ingredient.expiryText,
                      style: TextStyle(
                        color: ingredient.urgent ? Colors.red.shade700 : Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快捷操作
  Widget _buildQuickAction() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const RandomMealDialog(),
            );
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("随便吃点", style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
