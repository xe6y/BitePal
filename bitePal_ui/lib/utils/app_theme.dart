import 'package:flutter/material.dart';

/// 应用设计系统 - 配色方案
class AppColors {
  // 主色调 - 温暖橙色
  static const Color primary = Color(0xFFF97316); // Orange 500
  static const Color primaryContainer = Color(0xFFFFE5D4); // 浅橙背景
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF7C2D12); // 深橙文字

  // 次要色 - 青绿色
  static const Color secondary = Color(0xFF14B8A6); // Teal 500
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Color(0xFF134E4A);

  // 语义色
  static const Color success = Color(0xFF10B981); // Green 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // 浅色模式中性色
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceContainerLight = Color(0xFFF5F5F5);
  static const Color surfaceContainerHighLight = Color(0xFFEEEEEE);
  static const Color onBackgroundLight = Color(0xFF1F2937);
  static const Color onSurfaceLight = Color(0xFF374151);
  static const Color onSurfaceVariantLight = Color(0xFF6B7280);
  static const Color outlineLight = Color(0xFFD1D5DB);

  // 深色模式中性色
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceContainerDark = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighDark = Color(0xFF363636);
  static const Color onBackgroundDark = Color(0xFFF9FAFB);
  static const Color onSurfaceDark = Color(0xFFE5E7EB);
  static const Color onSurfaceVariantDark = Color(0xFF9CA3AF);
  static const Color outlineDark = Color(0xFF4B5563);
}

/// 应用主题配置
class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      // 主色调
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      // 次要色
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      // 语义色
      error: AppColors.error,
      onError: Colors.white,
      // 表面色
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerHighest: AppColors.surfaceContainerHighLight,
      // 轮廓色
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineLight.withValues(alpha: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      // 字体配置
      fontFamily: null,
      fontFamilyFallback: const [
        '-apple-system',
        'BlinkMacSystemFont',
        'Segoe UI',
        'Roboto',
        'Helvetica Neue',
        'Arial',
        'sans-serif',
        'PingFang SC',
        'Hiragino Sans GB',
        'Microsoft YaHei',
        'WenQuanYi Micro Hei',
        'sans-serif',
      ],
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceLight,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      // AppBar 主题
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onBackgroundLight,
        titleTextStyle: TextStyle(
          color: AppColors.onBackgroundLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          inherit: false, // 明确设置 inherit，避免动画插值错误
        ),
      ),
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighLight.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.outlineLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.outlineLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            inherit: false, // 明确设置 inherit，避免动画插值错误
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.outlineLight.withValues(alpha: 0.3),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            inherit: false, // 明确设置 inherit，避免动画插值错误
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            inherit: false, // 明确设置 inherit，避免动画插值错误
          ),
        ),
      ),
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: AppColors.outlineLight.withValues(alpha: 0.1),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      // 主色调（深色模式使用更亮的橙色）
      primary: const Color(0xFFFF8A50), // 浅橙
      onPrimary: AppColors.onBackgroundDark,
      primaryContainer: AppColors.onPrimaryContainer,
      onPrimaryContainer: AppColors.primaryContainer,
      // 次要色
      secondary: const Color(0xFF5EEAD4), // 浅青
      onSecondary: AppColors.onBackgroundDark,
      secondaryContainer: AppColors.onSecondaryContainer,
      onSecondaryContainer: AppColors.secondaryContainer,
      // 语义色
      error: const Color(0xFFF87171),
      onError: Colors.white,
      // 表面色
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighDark,
      // 轮廓色
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineDark.withValues(alpha: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      // 字体配置
      fontFamily: null,
      fontFamilyFallback: const [
        '-apple-system',
        'BlinkMacSystemFont',
        'Segoe UI',
        'Roboto',
        'Helvetica Neue',
        'Arial',
        'sans-serif',
        'PingFang SC',
        'Hiragino Sans GB',
        'Microsoft YaHei',
        'WenQuanYi Micro Hei',
        'sans-serif',
      ],
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      // AppBar 主题
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onBackgroundDark,
        titleTextStyle: TextStyle(
          color: AppColors.onBackgroundDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          inherit: false, // 明确设置 inherit，避免动画插值错误
        ),
      ),
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighDark.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.outlineDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.outlineDark.withValues(alpha: 0.3),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            inherit: false, // 明确设置 inherit，避免动画插值错误
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: AppColors.outlineDark.withValues(alpha: 0.3),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            inherit: false, // 明确设置 inherit，避免动画插值错误
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            inherit: false, // 明确设置 inherit，避免动画插值错误
          ),
        ),
      ),
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: AppColors.outlineDark.withValues(alpha: 0.1),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
