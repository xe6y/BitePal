import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../utils/app_theme.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAdd;
  final bool isAdded;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavorite,
    this.onAdd,
    this.isAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片区域
            Stack(
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: recipe.image != null && recipe.image!.isNotEmpty
                        ? Image.network(
                            recipe.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          )
                        : Image.asset(
                            'assets/chinese-potato-strips.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          ),
                  ),
                ),
                // 收藏按钮
                if (onFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onFavorite?.call();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            recipe.favorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: recipe.favorite
                                ? Colors.red
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // 信息区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 菜名
                  Text(
                    recipe.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      inherit: false,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 时间和难度
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          inherit: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 星级难度显示
                      _buildStarRating(_getDifficultyStars(recipe.difficulty)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 标签和添加按钮
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: _buildTags(colorScheme),
                        ),
                      ),
                      if (onAdd != null) ...[
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              onAdd?.call();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isAdded
                                    ? colorScheme.primary
                                    : colorScheme.error,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isAdded
                                                ? colorScheme.primary
                                                : colorScheme.error)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isAdded ? Icons.check : Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标签列表
  /// colorScheme: 颜色方案
  /// 返回: 标签 Widget 列表
  List<Widget> _buildTags(ColorScheme colorScheme) {
    if (recipe.tags.isEmpty) {
      return [];
    }

    return recipe.tags.asMap().entries.map((entry) {
      final index = entry.key;
      final tag = entry.value;
      final tagColorClass = index < recipe.tagColors.length
          ? recipe.tagColors[index]
          : null;

      // 解析标签颜色
      final backgroundColor = TagColorUtils.parseColor(tagColorClass);
      final textColor = TagColorUtils.getTextColor(backgroundColor);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            color: textColor,
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
        ),
      );
    }).toList();
  }

  /// 根据难度文字获取星级数值
  double _getDifficultyStars(String difficulty) {
    switch (difficulty) {
      case '简单':
        return 2.0;
      case '中等':
        return 3.0;
      case '困难':
        return 4.5;
      default:
        return 3.0;
    }
  }

  /// 构建星级评分显示
  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;

        if (rating >= starValue) {
          icon = Icons.star;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        return Icon(
          icon,
          size: 13,
          color: Colors.amber,
        );
      }),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
      ),
    );
  }
}
