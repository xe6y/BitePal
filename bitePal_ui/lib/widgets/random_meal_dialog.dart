import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../screens/recipe_detail_screen.dart';

/// 随机推荐对话框
class RandomMealDialog extends StatefulWidget {
  const RandomMealDialog({super.key});

  @override
  State<RandomMealDialog> createState() => _RandomMealDialogState();
}

class _RandomMealDialogState extends State<RandomMealDialog> {
  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 推荐结果
  Recipe? _recommendedRecipe;

  /// 推荐理由
  String? _reason;

  /// 是否正在加载
  bool _isLoading = false;

  /// 推荐选项
  final List<Map<String, dynamic>> _options = [
    {
      'icon': Icons.inventory_2,
      'title': '使用库存优先',
      'description': '智能匹配家中现有食材',
      'color': Colors.blue,
      'mode': 'inventory',
    },
    {
      'icon': Icons.restaurant,
      'title': '完全随机',
      'description': '探索意想不到的美味',
      'color': Colors.green,
      'mode': 'random',
    },
    {
      'icon': Icons.access_time,
      'title': '快手菜 (≤20分钟)',
      'description': '简单便捷，立刻开吃',
      'color': Colors.amber,
      'mode': 'quick',
    },
  ];

  /// 获取随机推荐
  Future<void> _getRandomRecipe(String mode) async {
    setState(() => _isLoading = true);

    try {
      final result = await _recipeService.randomRecipe(
        mode: mode,
        maxTime: mode == 'quick' ? 20 : null,
      );

      if (result != null && result.recipe != null) {
        _recommendedRecipe = result.recipe;
        _reason = result.reason;
      } else {
        // 使用模拟数据
        _recommendedRecipe = Recipe(
          id: '1',
          name: mode == 'quick' ? '番茄炒蛋' : '红烧肉',
          time: mode == 'quick' ? '15分钟' : '45分钟',
          difficulty: mode == 'quick' ? '简单' : '中等',
          tags: ['推荐'],
          tagColors: ['bg-blue-500'],
          categories: ['家常菜'],
        );
        _reason = mode == 'inventory'
            ? '根据您的库存，推荐这道菜'
            : mode == 'quick'
                ? '快速简单，非常适合'
                : '今天试试这道菜吧';
      }
    } catch (e) {
      debugPrint('获取推荐失败: $e');
      // 使用模拟数据
      _recommendedRecipe = Recipe(
        id: '1',
        name: '番茄炒蛋',
        time: '15分钟',
        difficulty: '简单',
        tags: ['推荐'],
        tagColors: ['bg-blue-500'],
        categories: ['家常菜'],
      );
      _reason = '今天就做这道菜吧！';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 显示推荐结果
    if (_recommendedRecipe != null) {
      return _buildResultDialog(context);
    }

    // 显示选项
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '正在为您推荐...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '今天想吃点什么?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '让我们为你做个决定吧',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._options.map((option) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _getRandomRecipe(option['mode'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: (option['color'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  option['icon'] as IconData,
                                  color: option['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option['description'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  /// 构建结果对话框
  Widget _buildResultDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              '为您推荐',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _recommendedRecipe!.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _recommendedRecipe!.time,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.trending_up, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _recommendedRecipe!.difficulty,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            if (_reason != null && _reason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _reason!,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _recommendedRecipe = null;
                        _reason = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('再换一个'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(
                            recipeId: _recommendedRecipe!.id,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('就它了'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
