import 'package:flutter/material.dart';
import '../services/shopping_service.dart';
import '../utils/app_theme.dart';
import 'order_detail_screen.dart';

/// 购物订单历史页面
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  /// 购物服务
  final ShoppingService _shoppingService = ShoppingService();

  /// 订单历史列表
  List<ShoppingListHistory> _orders = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 是否正在加载更多
  bool _isLoadingMore = false;

  /// 当前页码
  int _currentPage = 1;

  /// 每页数量
  static const int _pageSize = 20;

  /// 是否还有更多数据
  bool _hasMore = true;

  /// 总消费金额
  double _totalSpent = 0;

  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreOrders();
    }
  }

  /// 加载订单历史
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final result = await _shoppingService.getShoppingHistory(
        page: 1,
        pageSize: _pageSize,
      );

      if (result != null) {
        _orders = result.list;
        _hasMore = result.list.length >= _pageSize;
        _calculateTotal();
      }
    } catch (e) {
      debugPrint('加载订单历史失败: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 加载更多订单
  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _shoppingService.getShoppingHistory(
        page: _currentPage + 1,
        pageSize: _pageSize,
      );

      if (result != null && result.list.isNotEmpty) {
        _currentPage++;
        _orders.addAll(result.list);
        _hasMore = result.list.length >= _pageSize;
        _calculateTotal();
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('加载更多失败: $e');
    }

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  /// 计算总消费
  void _calculateTotal() {
    _totalSpent = _orders.fold(0, (sum, order) => sum + order.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('购物订单历史'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppColors.primary,
              child: Column(
                children: [
                  // 统计卡片
                  _buildStatCard(),
                  // 订单列表
                  Expanded(
                    child: _orders.isEmpty
                        ? _buildEmptyState()
                        : _buildOrderList(),
                  ),
                ],
              ),
            ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '累计消费',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¥${_totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_orders.length} 笔订单',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无订单记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成购物后订单会显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建订单列表
  Widget _buildOrderList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _orders.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildOrderItem(_orders[index]);
      },
    );
  }

  /// 构建订单项
  Widget _buildOrderItem(ShoppingListHistory order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: order.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.small,
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // 订单信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${order.itemCount} 件商品',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(order.completedAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 金额
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${order.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '未知时间';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return '昨天';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}天前';
      } else {
        return '${date.month}月${date.day}日';
      }
    } catch (e) {
      return dateStr;
    }
  }
}

