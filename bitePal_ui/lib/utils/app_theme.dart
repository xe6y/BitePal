import 'package:flutter/material.dart';

/// ============================================
/// Bento Grid 设计系统
/// ============================================

/// Bento 风格设计常量
class BentoStyle {
  BentoStyle._();

  /// 统一圆角 - 28px
  static const double cardRadius = 28.0;

  /// 小圆角 - 用于内部元素
  static const double smallRadius = 16.0;

  /// 内边距
  static const double cardPadding = 20.0;

  /// 网格间距
  static const double gridSpacing = 16.0;

  /// 背景色 - 极浅米白色
  static const Color backgroundColor = Color(0xFFF8F9FA);

  /// Bento 卡片柔和阴影
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  /// Bento 卡片悬浮阴影（点击态）
  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ];

  /// 装饰图标透明度
  static const double decorIconOpacity = 0.08;

  /// 装饰图标大小
  static const double decorIconSize = 80.0;

  /// 动画时长 - 点击缩放
  static const Duration tapAnimDuration = Duration(milliseconds: 150);

  /// 点击缩放比例
  static const double tapScale = 0.97;
}

/// 应用设计系统 - 配色方案
class AppColors {
  // 主色调 - 温暖橙色渐变
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8A5B);
  static const Color primaryDark = Color(0xFFE85A2A);
  static const Color primaryContainer = Color(0xFFFFF0EB);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF7C2D12);

  // 次要色 - 清新薄荷绿
  static const Color secondary = Color(0xFF00BFA5);
  static const Color secondaryLight = Color(0xFF5DF2D6);
  static const Color secondaryContainer = Color(0xFFE0FFF9);
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Color(0xFF00695C);

  // 强调色 - 活力紫
  static const Color accent = Color(0xFF7C4DFF);
  static const Color accentLight = Color(0xFFB47CFF);

  // 语义色
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFAB00);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFFF1744);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2979FF);
  static const Color infoLight = Color(0xFFE3F2FD);

  // 浅色模式中性色 - Bento 风格背景
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceContainerLight = Color(0xFFF1F3F4);
  static const Color surfaceContainerHighLight = Color(0xFFE8EAED);
  static const Color onBackgroundLight = Color(0xFF1A1A2E);
  static const Color onSurfaceLight = Color(0xFF2D3436);
  static const Color onSurfaceVariantLight = Color(0xFF636E72);
  static const Color outlineLight = Color(0xFFDFE6E9);

  // 深色模式中性色
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceContainerDark = Color(0xFF262626);
  static const Color surfaceContainerHighDark = Color(0xFF333333);
  static const Color onBackgroundDark = Color(0xFFF5F5F5);
  static const Color onSurfaceDark = Color(0xFFE0E0E0);
  static const Color onSurfaceVariantDark = Color(0xFF9E9E9E);
  static const Color outlineDark = Color(0xFF424242);

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A5B), Color(0xFFFF6B35), Color(0xFFE85A2A)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5DF2D6), Color(0xFF00BFA5)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB47CFF), Color(0xFF7C4DFF)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE259), Color(0xFFFFA751)],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );
}

/// 应用间距常量
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// 应用圆角常量
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 100;
}

/// 应用阴影
class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

/// 应用主题配置
class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.accent,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerHighest: AppColors.surfaceContainerHighLight,
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineLight.withValues(alpha: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: null,
      fontFamilyFallback: const [
        'PingFang SC',
        'Hiragino Sans GB',
        'Microsoft YaHei',
        '-apple-system',
        'BlinkMacSystemFont',
        'Segoe UI',
        'Roboto',
        'sans-serif',
      ],
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceLight,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      // AppBar 主题
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onBackgroundLight,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onBackgroundLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: AppColors.onSurfaceVariantLight.withValues(alpha: 0.6),
        ),
      ),
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      // 浮动按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      // 芯片主题
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLight,
        selectedColor: AppColors.primaryContainer,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: AppColors.outlineLight.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      // 列表瓦片主题
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      // 底部导航主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariantLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      // SnackBar主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.onBackgroundLight,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onBackgroundDark,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onBackgroundDark,
      secondaryContainer: AppColors.onSecondaryContainer,
      onSecondaryContainer: AppColors.secondaryContainer,
      tertiary: AppColors.accentLight,
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineDark.withValues(alpha: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: null,
      fontFamilyFallback: const [
        'PingFang SC',
        'Hiragino Sans GB',
        'Microsoft YaHei',
        '-apple-system',
        'BlinkMacSystemFont',
        'Segoe UI',
        'Roboto',
        'sans-serif',
      ],
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onBackgroundDark,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onBackgroundDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerDark,
        selectedColor: AppColors.primaryDark,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineDark.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.onSurfaceVariantDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighDark,
        contentTextStyle: const TextStyle(color: AppColors.onSurfaceDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// 标签颜色工具类
/// 用于解析颜色字符串（支持 hex 格式和 Tailwind CSS 类名）
class TagColorUtils {
  /// Tailwind CSS 颜色映射表
  static const Map<String, Color> _tailwindColorMap = {
    // 绿色系
    'bg-green-500': Color(0xFF10B981),
    'bg-green-400': Color(0xFF34D399),
    'bg-green-600': Color(0xFF059669),
    'bg-green-300': Color(0xFF6EE7B7),
    // 红色系
    'bg-red-500': Color(0xFFEF4444),
    'bg-red-400': Color(0xFFF87171),
    'bg-red-600': Color(0xFFDC2626),
    'bg-red-300': Color(0xFFFCA5A5),
    // 蓝色系
    'bg-blue-500': Color(0xFF3B82F6),
    'bg-blue-400': Color(0xFF60A5FA),
    'bg-blue-600': Color(0xFF2563EB),
    'bg-blue-300': Color(0xFF93C5FD),
    // 黄色/琥珀色系
    'bg-amber-500': Color(0xFFF59E0B),
    'bg-amber-400': Color(0xFFFBBF24),
    'bg-amber-600': Color(0xFFD97706),
    'bg-amber-300': Color(0xFFFCD34D),
    'bg-yellow-500': Color(0xFFEAB308),
    'bg-yellow-400': Color(0xFFFACC15),
    'bg-yellow-600': Color(0xFFCA8A04),
    // 紫色系
    'bg-purple-500': Color(0xFFA855F7),
    'bg-purple-400': Color(0xFFC084FC),
    'bg-purple-600': Color(0xFF9333EA),
    // 粉色系
    'bg-pink-500': Color(0xFFEC4899),
    'bg-pink-400': Color(0xFFF472B6),
    'bg-pink-600': Color(0xFFDB2777),
    // 橙色系
    'bg-orange-500': Color(0xFFF97316),
    'bg-orange-400': Color(0xFFFB923C),
    'bg-orange-600': Color(0xFFEA580C),
    // 青色系
    'bg-cyan-500': Color(0xFF06B6D4),
    'bg-cyan-400': Color(0xFF22D3EE),
    'bg-cyan-600': Color(0xFF0891B2),
    // 灰色系
    'bg-gray-500': Color(0xFF6B7280),
    'bg-gray-400': Color(0xFF9CA3AF),
    'bg-gray-600': Color(0xFF4B5563),
  };

  /// 解析颜色字符串
  /// 支持以下格式：
  /// - hex 格式：#FF5722、#4CAF50
  /// - Tailwind CSS 类名：bg-green-500、bg-red-500
  /// colorStr: 颜色字符串
  /// 返回: 对应的 Flutter Color，如果无法解析则返回默认灰色
  static Color parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return Colors.grey.shade400;
    }

    // 尝试解析 hex 格式（如 #FF5722 或 FF5722）
    if (colorStr.startsWith('#') || _isHexColor(colorStr)) {
      try {
        final hexStr = colorStr.replaceFirst('#', '');
        // 处理 6 位和 8 位 hex 颜色
        if (hexStr.length == 6) {
          return Color(int.parse('0xFF$hexStr'));
        } else if (hexStr.length == 8) {
          return Color(int.parse('0x$hexStr'));
        }
      } catch (e) {
        // 解析失败，继续尝试其他格式
      }
    }

    // 尝试从 Tailwind 映射表查找
    final tailwindColor = _tailwindColorMap[colorStr];
    if (tailwindColor != null) {
      return tailwindColor;
    }

    // 如果都找不到，返回默认灰色
    return Colors.grey.shade400;
  }

  /// 判断字符串是否为有效的 hex 颜色（不带 # 前缀）
  /// str: 待检测字符串
  /// 返回: 是否为有效的 hex 颜色
  static bool _isHexColor(String str) {
    if (str.length != 6 && str.length != 8) return false;
    return RegExp(r'^[0-9A-Fa-f]+$').hasMatch(str);
  }

  /// 根据颜色获取合适的文字颜色（白色或黑色）
  /// backgroundColor: 背景颜色
  /// 返回: 适合的文字颜色
  static Color getTextColor(Color backgroundColor) {
    // 计算亮度
    final luminance = backgroundColor.computeLuminance();
    // 如果亮度大于 0.5，使用黑色文字，否则使用白色文字
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
