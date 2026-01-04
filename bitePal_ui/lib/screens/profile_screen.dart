import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'recipes_screen.dart';
import 'meals_screen.dart';
import 'ingredients_screen.dart';
import 'shopping_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'family_members_screen.dart';
import 'app_settings_screen.dart';

/// 个人中心页面
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// 认证服务
  final AuthService _authService = AuthService();

  /// 用户信息
  User? _user;

  /// 用户统计
  UserStats? _stats;

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 加载用户数据
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // 并行加载用户信息和统计
      final results = await Future.wait([
        _authService.getUserInfo(),
        _authService.getUserStats(),
      ]);

      _user = results[0] as User?;
      _stats = results[1] as UserStats?;
    } catch (e) {
      debugPrint('加载用户数据失败: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 退出登录
  Future<void> _handleLogout() async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        // 返回到登录页并清除所有路由
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              onLoginSuccess: () {
                // 登录成功后重新进入应用
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const _AppReloader()),
                  (route) => false,
                );
              },
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsItems = [
      {
        'icon': Icons.shopping_cart,
        'label': '购物订单历史',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
          );
        },
      },
      {
        'icon': Icons.people,
        'label': '家庭成员偏好',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FamilyMembersScreen()),
          );
        },
      },
      {
        'icon': Icons.settings,
        'label': 'App 设置',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppSettingsScreen()),
          );
        },
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 返回按钮
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_back,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '返回',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 用户信息区域
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 用户信息
                            Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFFFB84D), Color(0xFFFF6B35)],
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: _user?.avatar != null
                                        ? Image.network(
                                            _user!.avatar!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildDefaultAvatar(),
                                          )
                                        : Image.asset(
                                            'assets/cartoon-avatar.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildDefaultAvatar(),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _user?.nickname ?? _user?.username ?? '未登录',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${_user?.userId ?? '---'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // 统计卡片
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    icon: Icons.check_circle,
                                    iconColor: Colors.blue,
                                    value: '${_stats?.monthlyCookingCount ?? 0} 次',
                                    label: '本月做饭',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    icon: Icons.trending_down,
                                    iconColor: Colors.green,
                                    value: '${((_stats?.wasteReductionRate ?? 0) * 100).toInt()} %',
                                    label: '食材浪费减少',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // 家庭设置标题
                            Text(
                              '家庭设置',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 设置列表
                            Card(
                              child: Column(
                                children: settingsItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return InkWell(
                                    onTap: item['onTap'] as VoidCallback,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: index < settingsItems.length - 1
                                              ? BorderSide(
                                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  width: 1,
                                                )
                                              : BorderSide.none,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                item['icon'] as IconData,
                                                size: 20,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                item['label'] as String,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 退出登录按钮
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _handleLogout,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.error,
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '退出登录',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      color: Colors.white,
      size: 40,
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 应用重载器 - 退出登录后重新初始化应用
class _AppReloader extends StatelessWidget {
  const _AppReloader();

  @override
  Widget build(BuildContext context) {
    // 使用 runApp 重启整个应用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 简单的方式：直接返回主入口
      runApp(const _RestartedApp());
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// 重启后的应用
class _RestartedApp extends StatelessWidget {
  const _RestartedApp();

  @override
  Widget build(BuildContext context) {
    // 导入 main.dart 的 MyApp
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _AuthWrapperSimple(),
    );
  }
}

/// 简化的认证包装器
class _AuthWrapperSimple extends StatefulWidget {
  const _AuthWrapperSimple();

  @override
  State<_AuthWrapperSimple> createState() => _AuthWrapperSimpleState();
}

class _AuthWrapperSimpleState extends State<_AuthWrapperSimple> {
  bool _isAuthenticated = false;

  void _setAuthenticated() {
    setState(() => _isAuthenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return _SimpleMainScreen(onLogout: () {
        setState(() => _isAuthenticated = false);
      });
    }
    return LoginScreen(onLoginSuccess: _setAuthenticated);
  }
}

/// 简化的主页面
class _SimpleMainScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const _SimpleMainScreen({required this.onLogout});

  @override
  State<_SimpleMainScreen> createState() => _SimpleMainScreenState();
}

class _SimpleMainScreenState extends State<_SimpleMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const RecipesScreen(),
      const MealsScreen(),
      const IngredientsScreen(),
      const ShoppingScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
