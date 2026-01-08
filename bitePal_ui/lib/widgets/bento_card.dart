import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Bento 卡片尺寸类型
enum BentoCardSize {
  /// 1x1 小卡片
  small,

  /// 2x1 横向卡片
  wide,

  /// 1x2 纵向卡片
  tall,

  /// 2x2 大卡片
  large,
}

/// Bento 风格卡片组件
/// 包含：统一圆角、柔和阴影、装饰图标、点击缩放动画
class BentoCard extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 点击回调
  final VoidCallback? onTap;

  /// 卡片背景色
  final Color? backgroundColor;

  /// 渐变背景
  final Gradient? gradient;

  /// 装饰图标
  final IconData? decorIcon;

  /// 装饰图标颜色
  final Color? decorIconColor;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 是否禁用点击动画
  final bool disableTapAnimation;

  /// 自定义阴影
  final List<BoxShadow>? boxShadow;

  const BentoCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.decorIcon,
    this.decorIconColor,
    this.padding,
    this.disableTapAnimation = false,
    this.boxShadow,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard>
    with SingleTickerProviderStateMixin {
  /// 动画控制器
  late AnimationController _animController;

  /// 缩放动画
  late Animation<double> _scaleAnimation;

  /// 是否按下状态
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: BentoStyle.tapAnimDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: BentoStyle.tapScale,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// 处理按下事件
  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && !widget.disableTapAnimation) {
      setState(() => _isPressed = true);
      _animController.forward();
    }
  }

  /// 处理抬起事件
  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animController.reverse();
    }
  }

  /// 处理取消事件
  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackgroundColor =
        widget.backgroundColor ?? colorScheme.surface;
    final effectiveDecorColor =
        widget.decorIconColor ?? colorScheme.onSurface.withValues(alpha: 0.06);

    Widget cardContent = Container(
      padding: widget.padding ??
          const EdgeInsets.all(BentoStyle.cardPadding),
      decoration: BoxDecoration(
        color: widget.gradient == null ? effectiveBackgroundColor : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(BentoStyle.cardRadius),
        boxShadow: widget.boxShadow ?? BentoStyle.cardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 主内容（填满整个区域）
          Positioned.fill(
            child: widget.child,
          ),
          // 装饰图标（右下角半透明）
          if (widget.decorIcon != null)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                widget.decorIcon,
                size: BentoStyle.decorIconSize,
                color: effectiveDecorColor,
              ),
            ),
        ],
      ),
    );

    // 如果有点击事件，添加动画效果
    if (widget.onTap != null) {
      cardContent = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.disableTapAnimation ? 1.0 : _scaleAnimation.value,
              child: child,
            );
          },
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Bento 卡片带标题的封装
class BentoTitledCard extends StatelessWidget {
  /// 标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 图标
  final IconData? icon;

  /// 图标背景色
  final Color? iconBackgroundColor;

  /// 图标颜色
  final Color? iconColor;

  /// 点击回调
  final VoidCallback? onTap;

  /// 卡片背景色
  final Color? backgroundColor;

  /// 渐变背景
  final Gradient? gradient;

  /// 装饰图标
  final IconData? decorIcon;

  /// 额外内容（显示在标题下方）
  final Widget? extra;

  /// 是否垂直布局
  final bool vertical;

  const BentoTitledCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBackgroundColor,
    this.iconColor,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.decorIcon,
    this.extra,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconBg =
        iconBackgroundColor ?? colorScheme.primary.withValues(alpha: 0.1);
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return BentoCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      gradient: gradient,
      decorIcon: decorIcon,
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      borderRadius:
                          BorderRadius.circular(BentoStyle.smallRadius),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 24),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (extra != null) ...[
                  const SizedBox(height: 12),
                  extra!,
                ],
              ],
            )
          : Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      borderRadius:
                          BorderRadius.circular(BentoStyle.smallRadius),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (extra != null) extra!,
              ],
            ),
    );
  }
}

/// Bento 统计卡片
class BentoStatCard extends StatelessWidget {
  /// 数值
  final String value;

  /// 标签
  final String label;

  /// 图标
  final IconData icon;

  /// 主题色
  final Color? color;

  /// 点击回调
  final VoidCallback? onTap;

  const BentoStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return BentoCard(
      onTap: onTap,
      decorIcon: icon,
      decorIconColor: effectiveColor.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: effectiveColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bento 快捷操作卡片
class BentoActionCard extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 标签
  final String label;

  /// 主题色
  final Color? color;

  /// 渐变背景
  final Gradient? gradient;

  /// 点击回调
  final VoidCallback? onTap;

  const BentoActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;
    final isGradient = gradient != null;

    return BentoCard(
      onTap: onTap,
      backgroundColor: isGradient ? null : effectiveColor.withValues(alpha: 0.08),
      gradient: gradient,
      decorIcon: icon,
      decorIconColor:
          isGradient ? Colors.white.withValues(alpha: 0.15) : effectiveColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: isGradient ? Colors.white : effectiveColor,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isGradient ? Colors.white : effectiveColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
