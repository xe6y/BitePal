import 'package:flutter/material.dart';
import '../models/recipe_category.dart';
import '../services/category_service.dart';

/// 分类选择组件
/// 用于在菜谱编辑页面中选择分类
class CategorySelector extends StatefulWidget {
  /// 分类类型（taste/cuisine/difficulty/meal_type）
  final String categoryType;

  /// 标题
  final String title;

  /// 初始选中的分类名称列表
  final List<String> initialSelected;

  /// 是否允许多选
  final bool multiSelect;

  /// 选择变化回调
  final Function(List<String>) onChanged;

  const CategorySelector({
    super.key,
    required this.categoryType,
    required this.title,
    this.initialSelected = const [],
    this.multiSelect = true,
    required this.onChanged,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  /// 分类服务
  final CategoryService _categoryService = CategoryService();

  /// 分类列表
  List<RecipeCategory> _categories = [];

  /// 选中的分类名称
  List<String> _selectedNames = [];

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedNames = List.from(widget.initialSelected);
    _loadCategories();
  }

  /// 加载分类数据
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final categories =
          await _categoryService.getCategoriesByType(widget.categoryType);
      if (categories != null && mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载分类失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 切换分类选择
  void _toggleCategory(String categoryName) {
    setState(() {
      if (widget.multiSelect) {
        // 多选模式
        if (_selectedNames.contains(categoryName)) {
          _selectedNames.remove(categoryName);
        } else {
          _selectedNames.add(categoryName);
        }
      } else {
        // 单选模式
        if (_selectedNames.contains(categoryName)) {
          _selectedNames.clear();
        } else {
          _selectedNames = [categoryName];
        }
      }
    });

    widget.onChanged(_selectedNames);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (!widget.multiSelect) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '单选',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_categories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '暂无分类选项',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedNames.contains(category.name);
              return FilterChip(
                label: Text(category.name),
                selected: isSelected,
                onSelected: (value) => _toggleCategory(category.name),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
      ],
    );
  }
}

