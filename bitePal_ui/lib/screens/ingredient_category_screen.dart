import 'package:flutter/material.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';

/// 食材分类管理页面
class IngredientCategoryScreen extends StatefulWidget {
  const IngredientCategoryScreen({super.key});

  @override
  State<IngredientCategoryScreen> createState() => _IngredientCategoryScreenState();
}

class _IngredientCategoryScreenState extends State<IngredientCategoryScreen> {
  /// 分类服务
  final IngredientCategoryService _categoryService = IngredientCategoryService();

  /// 分类列表
  List<IngredientCategory> _categories = [];

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// 加载分类数据
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      _categories = await _categoryService.getCategories();
    } catch (e) {
      debugPrint('加载分类失败: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 添加分类
  Future<void> _addCategory() async {
    final result = await _showCategoryDialog();
    if (result != null) {
      final category = await _categoryService.createCategory(
        name: result['name']!,
        icon: result['icon'] ?? '📦',
        color: result['color'] ?? '#9E9E9E',
      );

      if (category != null) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('添加成功')),
          );
        }
      }
    }
  }

  /// 编辑分类
  Future<void> _editCategory(IngredientCategory category) async {
    if (category.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('系统预设分类不可编辑')),
      );
      return;
    }

    final result = await _showCategoryDialog(
      initialName: category.name,
      initialIcon: category.icon,
      initialColor: category.color,
    );

    if (result != null) {
      final updated = await _categoryService.updateCategory(
        category.id,
        name: result['name'],
        icon: result['icon'],
        color: result['color'],
      );

      if (updated != null) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('更新成功')),
          );
        }
      }
    }
  }

  /// 删除分类
  Future<void> _deleteCategory(IngredientCategory category) async {
    if (category.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('系统预设分类不可删除')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${category.name}"吗？如果该分类下有食材，将无法删除。'),
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
      final success = await _categoryService.deleteCategory(category.id);
      if (success) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败，该分类下可能还有食材')),
        );
      }
    }
  }

  /// 显示分类编辑对话框
  Future<Map<String, String>?> _showCategoryDialog({
    String? initialName,
    String? initialIcon,
    String? initialColor,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    String selectedIcon = initialIcon ?? '📦';
    String selectedColor = initialColor ?? '#9E9E9E';

    final icons = [
      '🥩', '🍖', '🥓', '🍗', '🐟', '🦐', '🦀', '🥚',
      '🥬', '🥕', '🍅', '🥔', '🧅', '🥒', '🌽', '🥦',
      '🍎', '🍊', '🍋', '🍇', '🍓', '🍑', '🥝', '🍌',
      '🥛', '🧀', '🍞', '🍚', '🧂', '🫚', '🧄', '📦',
    ];

    final colors = [
      '#E53935', '#D81B60', '#8E24AA', '#5E35B1',
      '#3949AB', '#1E88E5', '#039BE5', '#00ACC1',
      '#00897B', '#43A047', '#7CB342', '#C0CA33',
      '#FDD835', '#FFB300', '#FB8C00', '#F4511E',
      '#8D6E63', '#757575', '#546E7A', '#9E9E9E',
    ];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(initialName != null ? '编辑分类' : '添加分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名称输入
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '分类名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 图标选择
                const Text('选择图标'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return InkWell(
                      onTap: () {
                        setDialogState(() => selectedIcon = icon);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 颜色选择
                const Text('选择颜色'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = color == selectedColor;
                    final colorValue = Color(int.parse(color.replaceFirst('#', '0xFF')));
                    return InkWell(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorValue,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: colorValue.withValues(alpha: 0.5), blurRadius: 8)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入分类名称')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'name': nameController.text,
                  'icon': selectedIcon,
                  'color': selectedColor,
                });
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
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
    // 分离系统分类和用户分类
    final systemCategories = _categories.where((c) => c.isSystem).toList();
    final userCategories = _categories.where((c) => !c.isSystem).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 用户自定义分类
                  if (userCategories.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            '我的分类',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            '${userCategories.length}个',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...userCategories.map((cat) => _buildCategoryItem(cat, canEdit: true)),
                    const SizedBox(height: 24),
                  ],

                  // 系统预设分类
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.settings_outlined, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '系统分类',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${systemCategories.length}个',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...systemCategories.map((cat) => _buildCategoryItem(cat, canEdit: false)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建分类项
  Widget _buildCategoryItem(IngredientCategory category, {required bool canEdit}) {
    final color = _parseColor(category.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(category.icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.isSystem ? '系统预设' : '自定义',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        trailing: canEdit
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCategory(category);
                  } else if (value == 'delete') {
                    _deleteCategory(category);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : Icon(
                Icons.lock_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
        onTap: canEdit ? () => _editCategory(category) : null,
      ),
    );
  }
}

