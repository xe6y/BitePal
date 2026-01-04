import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../utils/app_theme.dart';

/// 订单详情页面
class OrderDetailScreen extends StatefulWidget {
  /// 订单ID
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  /// 购物服务
  final ShoppingService _shoppingService = ShoppingService();

  /// 购物清单详情
  ShoppingList? _shoppingList;

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  /// 加载订单详情
  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    try {
      final result = await _shoppingService.getShoppingListDetail(widget.orderId);
      _shoppingList = result;
    } catch (e) {
      debugPrint('加载订单详情失败: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('订单详情'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shoppingList == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            '加载失败',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadDetail,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    final list = _shoppingList!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 订单信息卡片
          _buildOrderInfoCard(list),
          // 商品列表
          _buildItemsList(list),
          // 费用明细
          _buildPriceSummary(list),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建订单信息卡片
  Widget _buildOrderInfoCard(ShoppingList list) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '已完成',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      list.name,
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
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // 订单信息行
          _buildInfoRow('订单编号', list.id.substring(0, 8).toUpperCase()),
          const SizedBox(height: 12),
          _buildInfoRow('完成时间', _formatDateTime(list.completedAt)),
          const SizedBox(height: 12),
          _buildInfoRow('商品数量', '${list.items.length} 件'),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建商品列表
  Widget _buildItemsList(ShoppingList list) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_basket,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '购物明细',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final item = list.items[index];
              return _buildItemRow(item);
            },
          ),
        ],
      ),
    );
  }

  /// 构建商品行
  Widget _buildItemRow(ShoppingItem item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 勾选图标
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: item.checked ? AppColors.success : AppColors.surfaceContainerLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.checked ? Icons.check : Icons.remove,
              size: 16,
              color: item.checked ? Colors.white : AppColors.onSurfaceVariantLight,
            ),
          ),
          const SizedBox(width: 12),
          // 商品名称和数量
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: item.checked ? TextDecoration.lineThrough : null,
                    color: item.checked
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
                if (item.amount.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.amount,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 价格
          Text(
            '¥${item.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: item.checked
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建费用明细
  Widget _buildPriceSummary(ShoppingList list) {
    // 计算已购买和未购买的金额
    double purchasedTotal = 0;
    double unpurchasedTotal = 0;
    for (final item in list.items) {
      if (item.checked) {
        purchasedTotal += item.price;
      } else {
        unpurchasedTotal += item.price;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          _buildPriceRow('已购买商品', purchasedTotal),
          if (unpurchasedTotal > 0) ...[
            const SizedBox(height: 12),
            _buildPriceRow('未购买商品', unpurchasedTotal, isSecondary: true),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '订单总额',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '¥${list.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建价格行
  Widget _buildPriceRow(String label, double price, {bool isSecondary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSecondary
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '¥${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isSecondary
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                : null,
          ),
        ),
      ],
    );
  }

  /// 格式化日期时间
  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '未知时间';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}年${date.month}月${date.day}日 '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

