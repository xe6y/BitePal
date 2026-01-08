import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../services/recipe_service.dart';
import '../services/menu_service.dart';
import '../services/category_service.dart';

/// 菜谱详情页面
class RecipeDetailScreen extends StatefulWidget {
  /// 菜谱ID
  final String recipeId;

  /// 是否来自"我的菜谱"
  final bool isFromMyRecipes;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.isFromMyRecipes = false,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  /// 默认难度备选（接口异常时兜底）
  static const List<String> _fallbackDifficultyOptions = [
    '有手就行',
    '家常便饭',
    '餐厅招牌',
    '硬核挑战',
    '专业厨师',
  ];

  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 菜单服务
  final MenuService _menuService = MenuService();

  /// 分类服务
  final CategoryService _categoryService = CategoryService();

  /// 菜谱数据
  Recipe? _recipe;

  /// 是否正在加载
  bool _isLoading = true;

  /// 是否收藏
  bool _isFavorite = false;

  /// 是否编辑模式
  bool _isEditing = false;

  // 可编辑的数据
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  late TextEditingController _difficultyController;
  late List<String> _tags;
  late List<Ingredient> _ingredients;
  late List<String> _steps;

  /// 难度分类列表
  List<RecipeCategory> _difficultyCategories = [];

  // 临时输入控制器
  final Map<int, TextEditingController> _ingredientNameControllers = {};
  final Map<int, TextEditingController> _ingredientAmountControllers = {};
  final Map<int, TextEditingController> _stepControllers = {};
  final TextEditingController _newTagController = TextEditingController();
  final TextEditingController _newIngredientNameController =
      TextEditingController();
  final TextEditingController _newIngredientAmountController =
      TextEditingController();
  final TextEditingController _newStepController = TextEditingController();
  final Set<int> _hoveredTagIndices = {};

  @override
  void initState() {
    super.initState();
    _difficultyController = TextEditingController();
    _loadDifficultyOptions();
    _loadRecipeDetail();
  }

  /// 加载菜谱详情
  Future<void> _loadRecipeDetail() async {
    setState(() => _isLoading = true);

    try {
      final recipe = await _recipeService.getRecipeDetail(widget.recipeId);
      if (recipe != null) {
        _recipe = recipe;
        _initializeData(recipe);
      } else {
        // 使用模拟数据
        _initializeMockData();
      }
    } catch (e) {
      debugPrint('加载菜谱详情失败: $e');
      _initializeMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 从菜谱数据初始化
  void _initializeData(Recipe recipe) {
    _nameController = TextEditingController(text: recipe.name);
    _timeController = TextEditingController(text: recipe.time);
    _difficultyController.text = _ensureDifficultyValid(recipe.difficulty);
    _tags = List.from(recipe.tags);
    _ingredients = recipe.ingredients ?? [];
    _steps = recipe.steps ?? [];
    _isFavorite = recipe.favorite;
    _initializeControllers();
  }

  /// 构建难度下拉选择器
  Widget _buildDifficultyDropdown() {
    final currentDifficulty = _ensureDifficultyValid(
      _difficultyController.text,
    );
    if (_difficultyController.text != currentDifficulty) {
      _difficultyController.text = currentDifficulty;
    }
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _difficultyController.text = value;
        });
      },
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      elevation: 8,
      itemBuilder: (context) {
        return _difficultyNames().map((option) {
          final isSelected = option == currentDifficulty;
          return PopupMenuItem<String>(
            value: option,
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getDifficultyColor(option)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(option),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _getDifficultyColor(currentDifficulty),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentDifficulty,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建难度展示标签
  Widget _buildDifficultyLabel() {
    final currentDifficulty = _ensureDifficultyValid(
      _difficultyController.text,
    );
    if (_difficultyController.text != currentDifficulty) {
      _difficultyController.text = currentDifficulty;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getDifficultyColor(currentDifficulty),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        currentDifficulty,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  /// 使用模拟数据初始化
  void _initializeMockData() {
    _nameController = TextEditingController(text: "红烧肉");
    _timeController = TextEditingController(text: "45 分钟");
    _difficultyController.text = _ensureDifficultyValid("中等");
    _tags = ["清淡", "老人适合", "营养丰富"];
    _ingredients = [
      Ingredient(name: "西红柿", amount: "2个", available: true),
      Ingredient(name: "鸡蛋", amount: "3个", available: true),
      Ingredient(name: "小葱", amount: "2根", available: false),
    ];
    _steps = [
      "将西红柿洗净，切成均匀的橘瓣块。",
      "鸡蛋打入碗中，加入少许盐，搅拌均匀备用。",
      "锅中倒油烧热，倒入蛋液炒散成块，盛出备用。",
    ];
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < _ingredients.length; i++) {
      _ingredientNameControllers[i] = TextEditingController(
        text: _ingredients[i].name,
      );
      _ingredientAmountControllers[i] = TextEditingController(
        text: _ingredients[i].amount,
      );
    }
    for (int i = 0; i < _steps.length; i++) {
      _stepControllers[i] = TextEditingController(text: _steps[i]);
    }
  }

  /// 加载难度分类
  Future<void> _loadDifficultyOptions() async {
    final list = await _categoryService.getCategoriesByType('difficulty');
    if (list != null && list.isNotEmpty) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _difficultyCategories = list;
        _difficultyController.text = _ensureDifficultyValid(
          _difficultyController.text,
        );
      });
    }
  }

  /// 当前可用的难度名称列表
  List<String> _difficultyNames() {
    if (_difficultyCategories.isNotEmpty) {
      return _difficultyCategories.map((e) => e.name).toList();
    }
    return _fallbackDifficultyOptions;
  }

  /// 获取难度对应的背景色
  Color _getDifficultyColor(String difficulty) {
    final fromApi = _difficultyCategories.firstWhere(
      (e) => e.name == difficulty && (e.color?.isNotEmpty ?? false),
      orElse: () => RecipeCategory(
        id: '',
        type: '',
        name: '',
        color: null,
        icon: null,
        sortOrder: 0,
        isActive: true,
      ),
    );
    if (fromApi.name.isNotEmpty && fromApi.color != null) {
      return _parseColor(fromApi.color!) ?? const Color(0xFFE0E0E0);
    }
    return const Color(0xFFE0E0E0);
  }

  /// 解析HEX颜色
  Color? _parseColor(String hexColor) {
    try {
      final buffer = StringBuffer();
      var cleanHex = hexColor.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        buffer.write('FF');
      }
      buffer.write(cleanHex);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }

  /// 校验难度值，若不在选项内则回退到最低难度
  String _ensureDifficultyValid(String value) {
    final names = _difficultyNames();
    if (names.contains(value)) {
      return value;
    }
    return names.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _difficultyController.dispose();
    _newTagController.dispose();
    _newIngredientNameController.dispose();
    _newIngredientAmountController.dispose();
    _newStepController.dispose();
    for (var controller in _ingredientNameControllers.values) {
      controller.dispose();
    }
    for (var controller in _ingredientAmountControllers.values) {
      controller.dispose();
    }
    for (var controller in _stepControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      // 恢复原始数据
      if (_recipe != null) {
        _initializeData(_recipe!);
      } else {
        _nameController.text = "红烧肉";
        _timeController.text = "45 分钟";
        _difficultyController.text = "中等";
        _tags = ["清淡", "老人适合", "营养丰富"];
        _ingredients = [
          Ingredient(name: "西红柿", amount: "2个", available: true),
          Ingredient(name: "鸡蛋", amount: "3个", available: true),
          Ingredient(name: "小葱", amount: "2根", available: false),
        ];
        _steps = [
          "将西红柿洗净，切成均匀的橘瓣块。",
          "鸡蛋打入碗中，加入少许盐，搅拌均匀备用。",
          "锅中倒油烧热，倒入蛋液炒散成块，盛出备用。",
        ];
        _initializeControllers();
      }
    });
  }

  /// 确认编辑
  Future<void> _confirmEdit() async {
    // 构建更新后的菜谱
    final updatedRecipe = Recipe(
      id: widget.recipeId,
      name: _nameController.text,
      time: _timeController.text,
      difficulty: _difficultyController.text,
      tags: _tags,
      tagColors: _recipe?.tagColors ?? [],
      categories: _recipe?.categories ?? [],
      ingredients: _ingredients,
      steps: _steps,
      favorite: _isFavorite,
      isPublic: _recipe?.isPublic ?? false,
    );

    // 调用API保存
    final result = await _recipeService.updateRecipe(
      widget.recipeId,
      updatedRecipe,
    );

    if (result != null) {
      _recipe = result;
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功'), duration: Duration(seconds: 1)),
        );
      }
    } else {
      // 如果API失败，仍然保存本地状态
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功（本地）'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite() async {
    final newFavorite = !_isFavorite;
    final success = await _recipeService.toggleFavorite(
      widget.recipeId,
      newFavorite,
    );
    if (success) {
      setState(() => _isFavorite = newFavorite);
    } else {
      // API失败时也更新本地状态
      setState(() => _isFavorite = newFavorite);
    }
  }

  /// 加入今日菜单
  Future<void> _addToTodayMenu() async {
    final result = await _menuService.addRecipeToMenu(widget.recipeId);
    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已加入今日菜单'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('加入失败，请重试'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 加入我的菜单
  Future<void> _addToMyRecipes() async {
    final result = await _recipeService.addToMyRecipes(widget.recipeId);
    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已加入我的菜单'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('加入失败，请重试'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _addTag() {
    if (_newTagController.text.trim().isNotEmpty) {
      setState(() {
        _tags.add(_newTagController.text.trim());
        _newTagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  void _reorderTag(int fromIndex, int toIndex) {
    setState(() {
      final target = toIndex.clamp(0, _tags.length - 1);
      final tag = _tags.removeAt(fromIndex);
      _tags.insert(target, tag);
    });
  }

  Widget _buildTagChip({
    required String tag,
    required bool isHovered,
    int? index,
    bool canDelete = true,
  }) {
    return MouseRegion(
      onEnter: index != null
          ? (_) => setState(() => _hoveredTagIndices.add(index))
          : null,
      onExit: index != null
          ? (_) => setState(() => _hoveredTagIndices.remove(index))
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index != null)
                  const Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: Colors.grey,
                  ),
                if (index != null) const SizedBox(width: 4),
                Text(tag, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (canDelete && index != null)
            Positioned(
              right: -4,
              top: -6,
              child: GestureDetector(
                onTap: () => _removeTag(index),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isHovered ? 1 : 0.6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewTagInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: 170,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_circle_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _newTagController,
              decoration: const InputDecoration(
                hintText: '新标签',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _addTag(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableIngredientChip(int index) {
    final ingredient = _ingredients[index];
    _ingredientNameControllers[index] ??= TextEditingController(
      text: ingredient.name,
    );
    _ingredientAmountControllers[index] ??= TextEditingController(
      text: ingredient.amount,
    );

    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: _buildIngredientChipShell(
          child: _buildIngredientEditableBody(index),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildIngredientChipShell(
          child: _buildIngredientEditableBody(index),
        ),
      ),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) {
          final fromIndex = details.data;
          if (fromIndex != index) {
            _reorderIngredient(fromIndex, index);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildIngredientChipShell(
                child: _buildIngredientEditableBody(index),
              ),
              Positioned(
                right: -4,
                top: -6,
                child: GestureDetector(
                  onTap: () => _removeIngredient(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIngredientEditableBody(int index) {
    final ingredient = _ingredients[index];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: ingredient.available ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _ingredientNameControllers[index],
            decoration: const InputDecoration(
              hintText: '食材名称',
              border: InputBorder.none,
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _ingredients[index] = Ingredient(
                  name: value,
                  amount: _ingredients[index].amount,
                  available: _ingredients[index].available,
                );
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _ingredientAmountControllers[index],
            decoration: const InputDecoration(
              hintText: '用量',
              border: InputBorder.none,
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _ingredients[index] = Ingredient(
                  name: _ingredients[index].name,
                  amount: value,
                  available: _ingredients[index].available,
                );
              });
            },
            onSubmitted: (_) => _addIngredient(),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientDisplayChip(Ingredient ingredient) {
    return _buildIngredientChipShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: ingredient.available ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${ingredient.name} · ${ingredient.amount}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChipShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildNewIngredientChip() {
    return _buildIngredientChipShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_circle_outline, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _newIngredientNameController,
              decoration: const InputDecoration(
                hintText: '食材名称',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _newIngredientAmountController,
              decoration: const InputDecoration(
                hintText: '用量',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _addIngredient(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, size: 18),
            onPressed: _addIngredient,
            color: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableStepChip(int index) {
    _stepControllers[index] ??= TextEditingController(text: _steps[index]);

    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: _buildStepChipShell(child: _buildStepEditableBody(index)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildStepChipShell(child: _buildStepEditableBody(index)),
      ),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) {
          final fromIndex = details.data;
          if (fromIndex != index) {
            _reorderStep(fromIndex, index);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildStepChipShell(child: _buildStepEditableBody(index)),
              Positioned(
                right: -4,
                top: -6,
                child: GestureDetector(
                  onTap: () => _removeStep(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepEditableBody(int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: TextField(
            controller: _stepControllers[index],
            maxLines: null,
            decoration: const InputDecoration(
              hintText: '步骤描述',
              border: InputBorder.none,
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _steps[index] = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepDisplayChip(int index, String step) {
    return _buildStepChipShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              step,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepChipShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildNewStepChip() {
    return _buildStepChipShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${_steps.length + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: TextField(
              controller: _newStepController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '输入新步骤...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _addStep(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, size: 18),
            onPressed: _addStep,
            color: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _addIngredient() {
    if (_newIngredientNameController.text.trim().isNotEmpty &&
        _newIngredientAmountController.text.trim().isNotEmpty) {
      setState(() {
        final index = _ingredients.length;
        _ingredients.add(
          Ingredient(
            name: _newIngredientNameController.text.trim(),
            amount: _newIngredientAmountController.text.trim(),
            available: true,
          ),
        );
        _ingredientNameControllers[index] = TextEditingController(
          text: _newIngredientNameController.text.trim(),
        );
        _ingredientAmountControllers[index] = TextEditingController(
          text: _newIngredientAmountController.text.trim(),
        );
        _newIngredientNameController.clear();
        _newIngredientAmountController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      if (index < 0 || index >= _ingredients.length) {
        return;
      }
      final nameList = _ingredients.asMap().entries.map((entry) {
        return _ingredientNameControllers[entry.key] ??
            TextEditingController(text: entry.value.name);
      }).toList();
      final amountList = _ingredients.asMap().entries.map((entry) {
        return _ingredientAmountControllers[entry.key] ??
            TextEditingController(text: entry.value.amount);
      }).toList();
      final removedName = nameList.removeAt(index);
      final removedAmount = amountList.removeAt(index);
      _ingredients.removeAt(index);
      removedName.dispose();
      removedAmount.dispose();
      _ingredientNameControllers
        ..clear()
        ..addEntries(
          nameList.asMap().entries.map(
            (entry) => MapEntry(entry.key, entry.value),
          ),
        );
      _ingredientAmountControllers
        ..clear()
        ..addEntries(
          amountList.asMap().entries.map(
            (entry) => MapEntry(entry.key, entry.value),
          ),
        );
    });
  }

  void _reorderIngredient(int fromIndex, int toIndex) {
    setState(() {
      if (_ingredients.isEmpty ||
          fromIndex < 0 ||
          fromIndex >= _ingredients.length) {
        return;
      }
      final safeTo = toIndex.clamp(0, _ingredients.length - 1);
      final nameList = _ingredients.asMap().entries.map((entry) {
        return _ingredientNameControllers[entry.key] ??
            TextEditingController(text: entry.value.name);
      }).toList();
      final amountList = _ingredients.asMap().entries.map((entry) {
        return _ingredientAmountControllers[entry.key] ??
            TextEditingController(text: entry.value.amount);
      }).toList();
      final movedIngredient = _ingredients.removeAt(fromIndex);
      final movedName = nameList.removeAt(fromIndex);
      final movedAmount = amountList.removeAt(fromIndex);
      final insertIndex = fromIndex < safeTo ? safeTo - 1 : safeTo;
      _ingredients.insert(insertIndex, movedIngredient);
      nameList.insert(insertIndex, movedName);
      amountList.insert(insertIndex, movedAmount);
      _ingredientNameControllers
        ..clear()
        ..addEntries(
          nameList.asMap().entries.map(
            (entry) => MapEntry(entry.key, entry.value),
          ),
        );
      _ingredientAmountControllers
        ..clear()
        ..addEntries(
          amountList.asMap().entries.map(
            (entry) => MapEntry(entry.key, entry.value),
          ),
        );
    });
  }

  void _addStep() {
    if (_newStepController.text.trim().isNotEmpty) {
      setState(() {
        final index = _steps.length;
        _steps.add(_newStepController.text.trim());
        _stepControllers[index] = TextEditingController(
          text: _newStepController.text.trim(),
        );
        _newStepController.clear();
      });
    }
  }

  void _removeStep(int index) {
    setState(() {
      if (index < 0 || index >= _steps.length) {
        return;
      }
      final controllerList = _steps.asMap().entries.map((entry) {
        return _stepControllers[entry.key] ??
            TextEditingController(text: entry.value);
      }).toList();
      final removed = controllerList.removeAt(index);
      _steps.removeAt(index);
      removed.dispose();
      _stepControllers
        ..clear()
        ..addEntries(
          controllerList.asMap().entries.map(
            (entry) => MapEntry(entry.key, entry.value),
          ),
        );
    });
  }

  void _reorderStep(int fromIndex, int toIndex) {
    setState(() {
      if (_steps.isEmpty || fromIndex < 0 || fromIndex >= _steps.length) {
        return;
      }
      final safeTo = toIndex.clamp(0, _steps.length - 1);
      final controllerList = _steps.asMap().entries.map((entry) {
        return _stepControllers[entry.key] ??
            TextEditingController(text: entry.value);
      }).toList();
      final movedStep = _steps.removeAt(fromIndex);
      final movedController = controllerList.removeAt(fromIndex);
      final insertIndex = fromIndex < safeTo ? safeTo - 1 : safeTo;
      _steps.insert(insertIndex, movedStep);
      controllerList.insert(insertIndex, movedController);
      _stepControllers
        ..clear()
        ..addEntries(
          controllerList.asMap().entries.map(
            (entry) => MapEntry(entry.key, entry.value),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Image
          SliverAppBar(
            expandedHeight: 256,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/chinese-potato-strips.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.black),
                ),
                onPressed: () {
                  // Share
                },
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 菜品名称
                  _isEditing
                      ? TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        )
                      : Text(
                          _nameController.text,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 12),
                  // 时间和难度
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      _isEditing
                          ? Container(
                              width: 130,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _timeController,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                                decoration: const InputDecoration(
                                  hintText: '烹饪时间',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(
                              _timeController.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      _isEditing
                          ? _buildDifficultyDropdown()
                          : _buildDifficultyLabel(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "家庭偏好标签",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: _addTag,
                          tooltip: '添加标签',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._tags.asMap().entries.map((entry) {
                              final index = entry.key;
                              final tag = entry.value;
                              final isHovered = _hoveredTagIndices.contains(
                                index,
                              );
                              return LongPressDraggable<int>(
                                key: ValueKey('tag_$index'),
                                data: index,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.drag_indicator,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          tag,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _buildTagChip(
                                    tag: tag,
                                    isHovered: isHovered,
                                    index: index,
                                  ),
                                ),
                                child: DragTarget<int>(
                                  onAcceptWithDetails: (details) {
                                    final fromIndex = details.data;
                                    if (fromIndex != index) {
                                      _reorderTag(fromIndex, index);
                                    }
                                  },
                                  builder:
                                      (context, candidateData, rejectedData) {
                                        return _buildTagChip(
                                          tag: tag,
                                          isHovered: isHovered,
                                          index: index,
                                        );
                                      },
                                ),
                              );
                            }),
                            _buildNewTagInput(),
                          ],
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _tags.map((tag) {
                            return _buildTagChip(
                              tag: tag,
                              isHovered: false,
                              index: null,
                              canDelete: false,
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "食材清单",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isEditing)
                        TextButton.icon(
                          onPressed: _addIngredient,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('添加食材'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._ingredients.asMap().entries.map(
                              (entry) =>
                                  _buildEditableIngredientChip(entry.key),
                            ),
                            _buildNewIngredientChip(),
                          ],
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _ingredients.map((ingredient) {
                            return _buildIngredientDisplayChip(ingredient);
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "步骤",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isEditing)
                        TextButton.icon(
                          onPressed: _addStep,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('添加步骤'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditing
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._steps.asMap().entries.map(
                              (entry) => _buildEditableStepChip(entry.key),
                            ),
                            _buildNewStepChip(),
                          ],
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _steps.asMap().entries.map((entry) {
                            return _buildStepDisplayChip(
                              entry.key,
                              entry.value,
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 100), // Space for bottom actions
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: _isEditing
              ? Row(
                  children: [
                    // 编辑模式：取消和确认按钮
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("取消"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmEdit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("确认"),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // 红心收藏按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleFavorite,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite
                                ? Colors.red
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 根据来源显示不同的按钮
                    if (widget.isFromMyRecipes) ...[
                      // 从"我的菜谱"进入：修改食材和加入今日菜单
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _enterEditMode,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("修改食材"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addToTodayMenu,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("加入今日菜单"),
                        ),
                      ),
                    ] else ...[
                      // 从"网络菜谱"进入：加入我的菜单和加入今日菜单
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _addToMyRecipes,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("加入我的菜单"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addToTodayMenu,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("加入今日菜单"),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
