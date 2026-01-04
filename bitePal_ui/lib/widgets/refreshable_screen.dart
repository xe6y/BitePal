import 'package:flutter/material.dart';

/// 可刷新页面接口
/// 实现此接口的页面可以在切换导航栏时自动刷新
abstract class RefreshableScreen extends StatefulWidget {
  const RefreshableScreen({super.key});
}

/// 可刷新页面状态 Mixin
/// 提供刷新功能的基础实现
mixin RefreshableScreenState<T extends RefreshableScreen> on State<T> {
  /// 刷新页面数据
  /// 子类需要重写此方法来实现具体的刷新逻辑
  Future<void> refresh() async {
    // 默认实现为空，子类需要重写
  }
}

