import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// 启动页面
/// 用于检查认证状态，自动跳转到登录或主页
class SplashScreen extends StatefulWidget {
  /// 已登录时的回调
  final VoidCallback onAuthenticated;

  /// 未登录时的回调
  final VoidCallback onUnauthenticated;

  const SplashScreen({
    super.key,
    required this.onAuthenticated,
    required this.onUnauthenticated,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  /// 认证服务
  final AuthService _authService = AuthService();

  /// 动画控制器
  late AnimationController _animationController;

  /// 缩放动画
  late Animation<double> _scaleAnimation;

  /// 透明度动画
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    // 启动动画
    _animationController.forward();

    // 检查认证状态
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 检查认证状态
  Future<void> _checkAuthStatus() async {
    // 等待动画完成
    await Future.delayed(const Duration(milliseconds: 2000));

    try {
      // 尝试自动登录
      final isLoggedIn = await _authService.autoLogin();

      if (mounted) {
        if (isLoggedIn) {
          widget.onAuthenticated();
        } else {
          widget.onUnauthenticated();
        }
      }
    } catch (e) {
      debugPrint('自动登录失败: $e');
      if (mounted) {
        widget.onUnauthenticated();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB84D), Color(0xFFFF6B35)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFFFF6B35),
                        size: 60,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 应用名称
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: const Column(
                      children: [
                        Text(
                          '做伴',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '你的做饭伴侣',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 加载指示器
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

