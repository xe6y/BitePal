import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';
import '../config/api_config.dart';
import 'ingredient_edit_screen.dart';

/// 食材详情页面
class IngredientDetailScreen extends StatefulWidget {
  /// 食材ID
  final String ingredientId;

  /// 初始食材数据（可选，用于快速展示）
  final IngredientItem? initialIngredient;

  const IngredientDetailScreen({
    super.key,
    required this.ingredientId,
    this.initialIngredient,
  });

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  /// 食材服务
  final IngredientService _ingredientService = IngredientService();

  /// 食材数据
  IngredientItem? _ingredient;

  /// 同名批次列表
  List<IngredientItem> _batches = [];

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ingredient = widget.initialIngredient;
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 加载食材详情
      final detail = await _ingredientService.getIngredientDetail(widget.ingredientId);
      if (detail != null) {
        _ingredient = detail;
        // 加载同名批次
        _batches = await _ingredientService.getIngredientBatches(detail.name);
      }
    } catch (e) {
      debugPrint('加载食材详情失败: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 删除食材
  Future<void> _deleteIngredient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${_ingredient?.name}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _ingredientService.deleteIngredient(widget.ingredientId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  /// 编辑食材
  Future<void> _editIngredient() async {
    if (_ingredient == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientEditScreen(ingredient: _ingredient),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  /// 解析颜色字符串
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ingredient?.name ?? '食材详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editIngredient,
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteIngredient,
            tooltip: '删除',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ingredient == null
              ? const Center(child: Text('食材不存在'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 头部信息
                        _buildHeader(),
                        const SizedBox(height: 16),

                        // 基本信息卡片
                        _buildInfoCard(),
                        const SizedBox(height: 16),

                        // 备注信息
                        if (_ingredient!.note.isNotEmpty) ...[
                          _buildNoteCard(),
                          const SizedBox(height: 16),
                        ],

                        // 同名批次
                        if (_batches.length > 1) ...[
                          _buildBatchesSection(),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// 构建头部信息
  Widget _buildHeader() {
    final ingredient = _ingredient!;
    final hasImage = ingredient.thumbnail.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: [
          // 缩略图或图标
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: hasImage
                  ? Image.network(
                      ingredient.thumbnail.startsWith('http')
                          ? ingredient.thumbnail
                          : '${ApiConfig.devBaseUrl.replaceAll('/api', '')}${ingredient.thumbnail}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          ingredient.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        ingredient.icon,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // 名称
          Text(
            ingredient.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 分类标签
          if (ingredient.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _parseColor(ingredient.category!.color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _parseColor(ingredient.category!.color).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ingredient.category!.icon,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ingredient.category!.name,
                    style: TextStyle(
                      color: _parseColor(ingredient.category!.color),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard() {
    final ingredient = _ingredient!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.numbers,
                label: '数量',
                value: ingredient.displayAmount,
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.kitchen,
                label: '存储位置',
                value: _getStorageText(ingredient.storage),
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: '过期时间',
                value: ingredient.expiryDate ?? '-',
                valueColor: ingredient.urgent
                    ? Colors.red
                    : ingredient.expiryDays <= 3
                        ? Colors.orange
                        : null,
                trailing: Text(
                  ingredient.expiryText,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ingredient.urgent
                        ? Colors.red
                        : ingredient.expiryDays <= 3
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (ingredient.purchaseDate != null && ingredient.purchaseDate!.isNotEmpty) ...[
                const Divider(),
                _buildInfoRow(
                  icon: Icons.shopping_cart_outlined,
                  label: '购买日期',
                  value: ingredient.purchaseDate!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          if (trailing != null)
            trailing
          else
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建备注卡片
  Widget _buildNoteCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notes,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '备注',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _ingredient!.note,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建批次列表
  Widget _buildBatchesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  '同名食材批次 (${_batches.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ..._batches.map((batch) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: batch.id == widget.ingredientId
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(batch.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  title: Text(
                    batch.displayAmount,
                    style: TextStyle(
                      fontWeight: batch.id == widget.ingredientId
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('过期: ${batch.expiryDate ?? '-'}'),
                  trailing: Text(
                    batch.expiryText,
                    style: TextStyle(
                      color: batch.urgent
                          ? Colors.red
                          : batch.expiryDays <= 3
                              ? Colors.orange
                              : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: batch.id == widget.ingredientId,
                  onTap: batch.id == widget.ingredientId
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IngredientDetailScreen(
                                ingredientId: batch.id,
                                initialIngredient: batch,
                              ),
                            ),
                          );
                        },
                ),
              )),
        ],
      ),
    );
  }

  /// 获取存储位置文本
  String _getStorageText(String storage) {
    switch (storage) {
      case 'room':
        return '常温';
      case 'fridge':
        return '冷藏';
      case 'freezer':
        return '冷冻';
      default:
        return storage;
    }
  }
}

