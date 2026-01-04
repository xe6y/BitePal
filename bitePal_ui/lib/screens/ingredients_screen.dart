import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';
import '../config/api_config.dart';
import '../widgets/refreshable_screen.dart';
import 'ingredient_detail_screen.dart';
import 'ingredient_edit_screen.dart';
import 'ingredient_category_screen.dart';

/// 食材库存页面
class IngredientsScreen extends RefreshableScreen {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> with RefreshableScreenState<IngredientsScreen> {
  /// 食材服务
  final IngredientService _ingredientService = IngredientService();

  /// 当前选中的存储位置
  String _activeStorage = "fridge";

  /// 是否正在加载
  bool _isLoading = true;

  /// 分组食材数据
  List<IngredientGroup> _groups = [];

  /// 折叠状态（按分类ID存储）
  final Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  @override
  Future<void> refresh() async {
    await _loadIngredients();
  }

  /// 加载食材数据
  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);

    try {
      // 加载分组数据
      _groups = await _ingredientService.getIngredientsGrouped(storage: _activeStorage);

      // 默认展开所有分组
      for (var group in _groups) {
        _expandedState[group.category.id] ??= true;
      }
    } catch (e) {
      debugPrint('加载食材失败: $e');
      _loadMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 加载模拟数据
  void _loadMockData() {
    _groups = [
      IngredientGroup(
        category: IngredientCategory(
          id: 'cat_vegetable',
          name: '蔬菜',
          icon: '🥬',
          color: '#43A047',
          sortOrder: 2,
          isSystem: true,
        ),
        ingredients: [
          IngredientItem(
            id: '1',
            name: "西红柿",
            quantity: 2,
            unit: "个",
            amount: "2个",
            storage: "fridge",
            categoryId: "cat_vegetable",
            icon: "🍅",
            expiryDays: 3,
            expiryText: "3天后过期",
          ),
          IngredientItem(
            id: '2',
            name: "土豆",
            quantity: 5,
            unit: "斤",
            amount: "5斤",
            storage: "room",
            categoryId: "cat_vegetable",
            icon: "🥔",
            expiryDays: 14,
            expiryText: "14天后过期",
          ),
        ],
        count: 2,
      ),
      IngredientGroup(
        category: IngredientCategory(
          id: 'cat_meat',
          name: '肉类',
          icon: '🥩',
          color: '#E53935',
          sortOrder: 1,
          isSystem: true,
        ),
        ingredients: [
          IngredientItem(
            id: '3',
            name: "猪肉",
            quantity: 1,
            unit: "斤",
            amount: "1斤",
            storage: "fridge",
            categoryId: "cat_meat",
            icon: "🥩",
            expiryDays: 0,
            expiryText: "今天过期",
            urgent: true,
          ),
        ],
        count: 1,
      ),
    ];
  }

  /// 删除食材
  Future<void> _deleteIngredient(IngredientItem ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${ingredient.name}"吗？'),
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
      final success = await _ingredientService.deleteIngredient(ingredient.id);
      if (success) {
        _loadIngredients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功'), duration: Duration(seconds: 1)),
          );
        }
      }
    }
  }

  /// 打开添加食材页面
  Future<void> _openAddIngredient() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientEditScreen(defaultStorage: _activeStorage),
      ),
    );

    if (result == true) {
      _loadIngredients();
    }
  }

  /// 打开食材详情页面
  Future<void> _openIngredientDetail(IngredientItem ingredient) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientDetailScreen(
          ingredientId: ingredient.id,
          initialIngredient: ingredient,
        ),
      ),
    );

    if (result == true) {
      _loadIngredients();
    }
  }

  /// 打开分类管理页面
  Future<void> _openCategoryManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IngredientCategoryScreen(),
      ),
    );
    _loadIngredients();
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
    final storages = [
      {'id': 'room', 'label': '常温', 'icon': Icons.home_outlined},
      {'id': 'fridge', 'label': '冷藏', 'icon': Icons.kitchen_outlined},
      {'id': 'freezer', 'label': '冷冻', 'icon': Icons.ac_unit},
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "食材库存",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.category_outlined),
                        onPressed: _openCategoryManagement,
                        tooltip: '分类管理',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 存储位置标签
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: storages.map((storage) {
                        final isActive = _activeStorage == storage['id'];
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _activeStorage = storage['id'] as String);
                              _loadIngredients();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive ? Theme.of(context).cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    storage['icon'] as IconData,
                                    size: 18,
                                    color: isActive
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    storage['label'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                      color: isActive
                                          ? Theme.of(context).colorScheme.onSurface
                                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // 食材列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadIngredients,
                      child: _groups.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _groups.length,
                              itemBuilder: (context, index) {
                                return _buildCategoryGroup(_groups[index]);
                              },
                            ),
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "ingredients_fab",
        onPressed: _openAddIngredient,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kitchen,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "暂无食材",
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openAddIngredient,
            icon: const Icon(Icons.add),
            label: const Text('添加食材'),
          ),
        ],
      ),
    );
  }

  /// 构建分类分组
  Widget _buildCategoryGroup(IngredientGroup group) {
    final isExpanded = _expandedState[group.category.id] ?? true;
    final categoryColor = _parseColor(group.category.color);

    return Column(
      children: [
        // 分类标题（可折叠）
        InkWell(
          onTap: () {
            setState(() {
              _expandedState[group.category.id] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                // 分类图标和名称
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(group.category.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        group.category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 数量标签
                Text(
                  '${group.count}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                // 展开/折叠图标
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),

        // 食材列表（可折叠）
        if (isExpanded)
          ...group.ingredients.map((ingredient) => _buildIngredientItem(ingredient)),

        const SizedBox(height: 8),
      ],
    );
  }

  /// 构建食材项
  Widget _buildIngredientItem(IngredientItem ingredient) {
    final hasImage = ingredient.thumbnail.isNotEmpty;

    return Dismissible(
      key: Key(ingredient.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除"${ingredient.name}"吗？'),
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
      },
      onDismissed: (_) => _deleteIngredient(ingredient),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: () => _openIngredientDetail(ingredient),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Image.network(
                      ingredient.thumbnail.startsWith('http')
                          ? ingredient.thumbnail
                          : '${ApiConfig.devBaseUrl.replaceAll('/api', '')}${ingredient.thumbnail}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(ingredient.icon, style: const TextStyle(fontSize: 28)),
                      ),
                    )
                  : Center(
                      child: Text(ingredient.icon, style: const TextStyle(fontSize: 28)),
                    ),
            ),
          ),
          title: Text(
            ingredient.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Text(ingredient.displayAmount),
              if (ingredient.note.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ingredient.urgent
                  ? Colors.red.withValues(alpha: 0.1)
                  : ingredient.expiryDays <= 3
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ingredient.expiryText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ingredient.urgent
                    ? Colors.red.shade600
                    : ingredient.expiryDays <= 3
                        ? Colors.orange.shade600
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
