import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/meals_screen.dart';
import 'screens/ingredients_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/bottom_nav.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

/// 应用根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '做伴',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // 本地化配置
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 简体中文
        Locale('en', 'US'), // 英文
      ],
      locale: const Locale('zh', 'CN'), // 默认使用中文
      home: const AuthWrapper(),
    );
  }
}

/// 认证包装器
/// 管理认证状态并显示相应页面
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  /// 认证状态：null=检查中, true=已登录, false=未登录
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
  }

  /// 设置为已认证状态
  void _setAuthenticated() {
    setState(() => _isAuthenticated = true);
  }

  /// 设置为未认证状态
  void _setUnauthenticated() {
    setState(() => _isAuthenticated = false);
  }

  /// 退出登录
  void logout() {
    setState(() => _isAuthenticated = false);
  }

  @override
  Widget build(BuildContext context) {
    // 检查中 - 显示启动页
    if (_isAuthenticated == null) {
      return SplashScreen(
        onAuthenticated: _setAuthenticated,
        onUnauthenticated: _setUnauthenticated,
      );
    }

    // 未登录 - 显示登录页
    if (_isAuthenticated == false) {
      return LoginScreen(onLoginSuccess: _setAuthenticated);
    }

    // 已登录 - 显示主页
    return MainScreen(onLogout: logout);
  }
}

/// 主页面
class MainScreen extends StatefulWidget {
  /// 退出登录回调
  final VoidCallback onLogout;

  const MainScreen({super.key, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// 当前选中的页面索引
  int _currentIndex = 0;

  /// 页面列表的 GlobalKey（用于访问页面状态）
  final List<GlobalKey<State<StatefulWidget>>> _screenKeys = [
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
  ];

  /// 页面列表
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _screenKeys[0]),
      RecipesScreen(key: _screenKeys[1]),
      MealsScreen(key: _screenKeys[2]),
      IngredientsScreen(key: _screenKeys[3]),
      ShoppingScreen(key: _screenKeys[4]),
    ];
  }

  /// 刷新指定索引的页面
  void _refreshPage(int index) {
    final state = _screenKeys[index].currentState;
    if (state == null) return;

    // 尝试调用刷新方法（如果页面实现了 RefreshableScreenState mixin）
    try {
      // 使用 dynamic 调用，如果方法不存在会抛出异常
      (state as dynamic).refresh();
    } catch (e) {
      // 如果页面没有实现 refresh 方法，忽略错误
      debugPrint('页面 $index 未实现 refresh 方法: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          
          // 切换页面时刷新数据（延迟执行，确保页面已切换）
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _refreshPage(index);
          });
        },
      ),
    );
  }
}
