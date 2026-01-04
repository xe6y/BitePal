import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';

/// 食材库存页面
class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  /// 食材服务
  final IngredientService _ingredientService = IngredientService();

  /// 当前选中的分类
  String _activeCategory = "room";

  /// 是否正在加载
  bool _isLoading = true;

  /// 按分类存储的食材
  final Map<String, List<IngredientItem>> _ingredientsByCategory = {
    "room": [],
    "fridge": [],
    "freezer": [],
  };

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  /// 加载食材数据
  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);

    try {
      // 并行加载所有分类的食材
      final results = await Future.wait([
        _ingredientService.getIngredients(category: 'room'),
        _ingredientService.getIngredients(category: 'fridge'),
        _ingredientService.getIngredients(category: 'freezer'),
      ]);

      _ingredientsByCategory['room'] = results[0];
      _ingredientsByCategory['fridge'] = results[1];
      _ingredientsByCategory['freezer'] = results[2];
    } catch (e) {
      debugPrint('加载食材失败: $e');
      // 使用模拟数据
      _loadMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 加载模拟数据
  void _loadMockData() {
    _ingredientsByCategory['room'] = [
      IngredientItem(
        id: '1',
        name: "西红柿",
        amount: "2个",
        category: "room",
        icon: "🍅",
        expiryDays: 3,
        expiryText: "3天后过期",
      ),
      IngredientItem(
        id: '2',
        name: "土豆",
        amount: "5kg",
        category: "room",
        icon: "🥔",
        expiryDays: 14,
        expiryText: "14天后过期",
      ),
    ];
    _ingredientsByCategory['fridge'] = [
      IngredientItem(
        id: '3',
        name: "生菜",
        amount: "1颗",
        category: "fridge",
        icon: "🥬",
        expiryDays: 0,
        expiryText: "今天过期",
        urgent: true,
      ),
    ];
    _ingredientsByCategory['freezer'] = [];
  }

  /// 删除食材
  Future<void> _deleteIngredient(IngredientItem ingredient) async {
    final success = await _ingredientService.deleteIngredient(ingredient.id);
    if (success) {
      setState(() {
        _ingredientsByCategory[ingredient.category]?.removeWhere((i) => i.id == ingredient.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  /// 显示添加食材对话框
  void _showAddIngredientDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedIcon = '🍎';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加食材'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '食材名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: '数量',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final result = await _ingredientService.createIngredient(
                  name: nameController.text,
                  amount: amountController.text,
                  category: _activeCategory,
                  icon: selectedIcon,
                );
                if (result != null) {
                  _loadIngredients();
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'id': 'room', 'label': '常温'},
      {'id': 'fridge', 'label': '冷藏'},
      {'id': 'freezer', 'label': '冷冻'},
    ];

    final currentIngredients = _ingredientsByCategory[_activeCategory] ?? [];

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
                  const Text(
                    "食材库存",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  // 分类标签
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: categories.map((category) {
                        final isActive = _activeCategory == category['id'];
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _activeCategory = category['id'] as String);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                              child: Text(
                                category['label'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "蔬菜水果",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
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
                      child: currentIngredients.isEmpty
                          ? Center(
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
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: currentIngredients.length,
                              itemBuilder: (context, index) {
                                final ingredient = currentIngredients[index];
                                return Dismissible(
                                  key: Key(ingredient.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (_) => _deleteIngredient(ingredient),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            ingredient.icon,
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        ingredient.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(ingredient.amount),
                                      trailing: Text(
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
                                );
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
        onPressed: _showAddIngredientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
