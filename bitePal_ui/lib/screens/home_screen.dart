import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';
import '../models/today_menu.dart';
import '../services/menu_service.dart';
import '../services/ingredient_service.dart';
import '../services/recipe_service.dart';
import '../utils/app_theme.dart';
import '../widgets/random_meal_dialog.dart';
import 'recipe_detail_screen.dart';
import 'profile_screen.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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

  /// 动画控制器
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _menuService.getTodayMenu(),
        _ingredientService.getExpiringIngredients(days: 3),
      ]);

      _todayMenu = results[0] as TodayMenu?;
      _expiringIngredients = results[1] as List<IngredientItem>;

      if (_todayMenu != null && _todayMenu!.recipes.isNotEmpty) {
        final recipeDetails = await Future.wait(
          _todayMenu!.recipes.map((r) => _recipeService.getRecipeDetail(r.recipeId)),
        );
        _todayRecipes = recipeDetails.whereType<Recipe>().toList();
      }
    } catch (e) {
      debugPrint('加载数据失败: $e');
      _loadMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  /// 加载模拟数据
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 头部Hero区域（包含快捷操作）
                  SliverToBoxAdapter(child: _buildHeroSection()),
                  // 今日菜单
                  SliverToBoxAdapter(child: _buildTodayMenu()),
                  // 食材提醒
                  if (_expiringIngredients.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _buildIngredientAlert()),
                    SliverToBoxAdapter(child: _buildExpiringSoon()),
                  ],
                  // 底部间距
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  /// 构建Hero区域（包含问候语、搜索框和快捷操作）
  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8A5B),
            Color(0xFFFF6B35),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部栏：问候语 + 头像
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "今天想吃点什么？",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 头像
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/cartoon-avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.warmGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 搜索框
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '搜索菜谱、食材...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onTap: () {
                    // 跳转到搜索页面
                  },
                ),
              ),
              const SizedBox(height: 20),
              // 快捷操作按钮
              Row(
                children: [
                  _buildHeroActionButton(
                    icon: Icons.shuffle_rounded,
                    label: '随便吃点',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const RandomMealDialog(),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildHeroActionButton(
                    icon: Icons.add_rounded,
                    label: '添加菜谱',
                    onTap: () {
                      // 导航到添加菜谱
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildHeroActionButton(
                    icon: Icons.calendar_month_rounded,
                    label: '周菜单',
                    onTap: () {
                      // 导航到周菜单
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建Hero区域内的操作按钮
  Widget _buildHeroActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建今日菜单
  Widget _buildTodayMenu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "今日菜单",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Text(
                      '查看全部',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayRecipes.isEmpty)
            _buildEmptyMenuCard()
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _todayRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _todayRecipes[index];
                  return Container(
                    width: 180,
                    margin: EdgeInsets.only(
                      right: index < _todayRecipes.length - 1 ? 16 : 0,
                    ),
                    child: _buildRecipeCard(recipe),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 构建空菜单卡片
  Widget _buildEmptyMenuCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "今日暂无菜单",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "点击下方按钮随机推荐或手动添加",
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('添加菜谱'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const RandomMealDialog(),
                  );
                },
                icon: const Icon(Icons.shuffle_rounded, size: 18),
                label: const Text('随机推荐'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建菜谱卡片
  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: AppColors.warmGradient,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  // 收藏按钮
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        recipe.favorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: recipe.favorite ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.onSurfaceVariantLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariantLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建食材提醒
  Widget _buildIngredientAlert() {
    final urgentCount = _expiringIngredients.where((i) => i.urgent).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warning.withValues(alpha: 0.15),
              AppColors.warning.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_expiringIngredients.length} 种食材即将过期",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (urgentCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      "其中 $urgentCount 种今天到期，建议优先使用",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariantLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建即将过期列表
  Widget _buildExpiringSoon() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "即将过期",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  '查看全部',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.small,
            ),
            child: Column(
              children: _expiringIngredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                final isLast = index == _expiringIngredients.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 图标
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: ingredient.urgent
                                  ? AppColors.errorLight
                                  : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                ingredient.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ingredient.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ingredient.amount,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariantLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 过期标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: ingredient.urgent
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ingredient.expiryText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ingredient.urgent
                                    ? AppColors.error
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 80,
                        color: AppColors.outlineLight.withValues(alpha: 0.5),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了 🌙';
    if (hour < 9) return '早上好 ☀️';
    if (hour < 12) return '上午好 🌤️';
    if (hour < 14) return '中午好 🍽️';
    if (hour < 18) return '下午好 ☕';
    if (hour < 22) return '晚上好 🌆';
    return '夜深了 🌙';
  }
}
