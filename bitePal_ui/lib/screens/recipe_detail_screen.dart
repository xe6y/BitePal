import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../services/recipe_service.dart';
import '../services/menu_service.dart';
import '../services/category_service.dart';
import '../services/today_menu_state.dart';

/// 菜谱详情页面
class RecipeDetailScreen extends StatefulWidget {
  /// 菜谱ID（创建模式时可为空）
  final String? recipeId;

  /// 是否来自"我的菜谱"
  final bool isFromMyRecipes;

  /// 是否为创建新菜谱模式
  final bool isCreateMode;

  const RecipeDetailScreen({
    super.key,
    this.recipeId,
    this.isFromMyRecipes = false,
    this.isCreateMode = false,
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

  /// 今日菜单状态管理器
  final TodayMenuState _todayMenuState = TodayMenuState();

  /// 菜谱数据
  Recipe? _recipe;

  /// 是否正在加载
  bool _isLoading = true;

  /// 是否收藏
  bool _isFavorite = false;

  /// 是否编辑模式
  bool _isEditing = false;

  /// 是否是"添加到我的菜谱"的编辑模式
  bool _isAddToMyRecipesMode = false;

  /// 是否已点（在已点菜品中）
  bool _isInSelectedMeals = false;

  /// 是否正在处理操作
  bool _isProcessing = false;

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

    // 根据模式初始化
    if (widget.isCreateMode) {
      _initializeCreateMode();
    } else {
      _loadRecipeDetail();
      _initSelectedMealsState();
      _todayMenuState.addListener(_onSelectedMealsStateChanged);
    }
  }

  /// 初始化创建模式
  void _initializeCreateMode() {
    _nameController = TextEditingController(text: '');
    _timeController = TextEditingController(text: '');
    _difficultyController.text = '';
    _tags = [];
    _ingredients = [];
    _steps = [];
    _isEditing = true;
    _isLoading = false;
  }

  /// 初始化已点菜品状态
  void _initSelectedMealsState() {
    if (mounted && widget.recipeId != null) {
      setState(() {
        _isInSelectedMeals = _todayMenuState.isSelected(widget.recipeId!);
      });
    }
  }

  /// 已点菜品状态变化回调
  void _onSelectedMealsStateChanged() {
    if (mounted && widget.recipeId != null) {
      setState(() {
        _isInSelectedMeals = _todayMenuState.isSelected(widget.recipeId!);
      });
    }
  }

  /// 加载菜谱详情
  Future<void> _loadRecipeDetail() async {
    if (widget.recipeId == null) {
      _initializeMockData();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final recipe = await _recipeService.getRecipeDetail(widget.recipeId!);
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
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Theme.of(context).cardColor,
      elevation: 4,
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
      itemBuilder: (context) {
        return _difficultyNames().map((option) {
          final isSelected = option == currentDifficulty;
          return PopupMenuItem<String>(
            value: option,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(option),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.check,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getDifficultyColor(currentDifficulty),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentDifficulty,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDifficultyColor(currentDifficulty),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        currentDifficulty,
        style: TextStyle(
          fontSize: 12,
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
    _todayMenuState.removeListener(_onSelectedMealsStateChanged);
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
    // 创建模式下取消直接返回上一页
    if (widget.isCreateMode) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isEditing = false;
      // 恢复原始数据
      if (_recipe != null) {
        _initializeData(_recipe!);
      }
    });
  }

  /// 确认编辑
  Future<void> _confirmEdit() async {
    // 验证必填字段
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入菜谱名称'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 构建菜谱数据
    final recipeData = Recipe(
      id: widget.isCreateMode ? '' : (widget.recipeId ?? ''),
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

    // 根据模式调用不同的 API
    if (widget.isCreateMode) {
      // 创建新菜谱
      final result = await _recipeService.createRecipe(recipeData);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('菜谱创建成功'),
              duration: Duration(seconds: 1),
            ),
          );
          // 返回上一页并通知刷新
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('创建失败，请重试'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } else {
      // 更新现有菜谱
      final result = await _recipeService.updateRecipe(
        widget.recipeId!,
        recipeData,
      );

      if (result != null) {
        _recipe = result;
        setState(() => _isEditing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存成功'),
              duration: Duration(seconds: 1),
            ),
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
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite() async {
    // 创建模式下只更新本地状态
    if (widget.isCreateMode || widget.recipeId == null) {
      setState(() => _isFavorite = !_isFavorite);
      return;
    }

    final newFavorite = !_isFavorite;
    final success = await _recipeService.toggleFavorite(
      widget.recipeId!,
      newFavorite,
    );
    if (success) {
      setState(() => _isFavorite = newFavorite);
    } else {
      // API失败时也更新本地状态
      setState(() => _isFavorite = newFavorite);
    }
  }

  /// 切换已点菜品状态（加入/移除）
  void _toggleSelectedMeals() {
    if (_isProcessing || _recipe == null) return;

    setState(() => _isProcessing = true);

    try {
      final isNowSelected = _todayMenuState.toggleSelected(_recipe!);

      if (mounted) {
        setState(() {
          _isInSelectedMeals = isNowSelected;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNowSelected ? '已加入已点菜品' : '已从已点菜品移除'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('操作失败，请重试'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 进入"加入我的菜谱"编辑模式
  void _enterAddToMyRecipesMode() {
    setState(() {
      _isEditing = true;
      _isAddToMyRecipesMode = true;
    });
  }

  /// 确认添加到我的菜谱
  Future<void> _confirmAddToMyRecipes() async {
    // 构建新菜谱数据
    final newRecipe = Recipe(
      id: '', // 新菜谱ID由后端生成
      name: _nameController.text,
      time: _timeController.text,
      difficulty: _difficultyController.text,
      tags: _tags,
      tagColors: _recipe?.tagColors ?? [],
      categories: _recipe?.categories ?? [],
      ingredients: _ingredients,
      steps: _steps,
      favorite: _isFavorite,
      isPublic: false, // 我的菜谱默认私有
    );

    // 调用API创建菜谱
    final result = await _recipeService.createRecipe(newRecipe);

    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已加入我的菜谱'),
            duration: Duration(seconds: 1),
          ),
        );
        // 返回上一页
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('加入失败，请重试'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 取消添加到我的菜谱
  void _cancelAddToMyRecipes() {
    setState(() {
      _isEditing = false;
      _isAddToMyRecipesMode = false;
      // 恢复原始数据
      if (_recipe != null) {
        _initializeData(_recipe!);
      }
    });
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除菜谱'),
        content: Text('确定要删除"${_nameController.text}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRecipe();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 删除菜谱
  Future<void> _deleteRecipe() async {
    if (_isProcessing || widget.recipeId == null) return;

    setState(() => _isProcessing = true);

    try {
      final success = await _recipeService.deleteRecipe(widget.recipeId!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('菜谱已删除'),
              duration: Duration(seconds: 1),
            ),
          );
          // 返回上一页并通知刷新
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除失败，请重试'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('删除菜谱失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除失败，请重试'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              tag,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      width: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _newTagController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: '新标签',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          child: TextField(
            controller: _ingredientNameControllers[index],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '食材',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
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
        const Text(' · ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        SizedBox(
          width: 50,
          child: TextField(
            controller: _ingredientAmountControllers[index],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '用量',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
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
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientDisplayChip(Ingredient ingredient) {
    return _buildIngredientChipShell(
      child: Text(
        '${ingredient.name} · ${ingredient.amount}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildIngredientChipShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
          SizedBox(
            width: 70,
            child: TextField(
              controller: _newIngredientNameController,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '食材',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Text(' · ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _newIngredientAmountController,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '用量',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _addIngredient(),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _addIngredient,
            child: Icon(
              Icons.check_circle,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
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
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
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
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextField(
            controller: _stepControllers[index],
            maxLines: null,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText: '步骤描述',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
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
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${_steps.length + 1}',
                style: TextStyle(
                  fontSize: 12,
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
            constraints: const BoxConstraints(maxWidth: 200),
            child: TextField(
              controller: _newStepController,
              maxLines: null,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: '输入新步骤...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _addStep(),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _addStep,
            child: Icon(
              Icons.check_circle,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  break;
                case 'delete':
                  _showDeleteConfirmDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('分享'),
                  ],
                ),
              ),
              if (!widget.isCreateMode)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('删除菜谱', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 顶部图片
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              child: Image.asset(
                'assets/chinese-potato-strips.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 菜品名称
                _isEditing
                    ? TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      )
                    : Text(
                        _nameController.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 8),
                // 时间和难度
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    _isEditing
                        ? Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _timeController,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                              decoration: const InputDecoration(
                                hintText: '时长',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          )
                        : Text(
                            _timeController.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    _isEditing ? _buildDifficultyDropdown() : _buildDifficultyLabel(),
                  ],
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "家庭偏好标签",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (_isEditing)
                TextButton.icon(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isEditing
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._tags.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tag = entry.value;
                      final isHovered = _hoveredTagIndices.contains(index);
                      return LongPressDraggable<int>(
                        key: ValueKey('tag_$index'),
                        data: index,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
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
                          builder: (context, candidateData, rejectedData) {
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "食材清单",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (_isEditing)
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isEditing
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._ingredients.asMap().entries.map(
                      (entry) => _buildEditableIngredientChip(entry.key),
                    ),
                    _buildNewIngredientChip(),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ingredients.map((ingredient) {
                    return _buildIngredientDisplayChip(ingredient);
                  }).toList(),
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "步骤",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (_isEditing)
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isEditing
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                    return _buildStepDisplayChip(entry.key, entry.value);
                  }).toList(),
                ),
                const SizedBox(height: 100), // Space for bottom actions
              ],
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
                        onPressed: _isAddToMyRecipesMode
                            ? _cancelAddToMyRecipes
                            : _cancelEdit,
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
                        onPressed: _isAddToMyRecipesMode
                            ? _confirmAddToMyRecipes
                            : _confirmEdit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_isAddToMyRecipesMode ? "确认加入" : "确认"),
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
                      // 从"我的菜谱"进入：修改食材和加入/移除已点菜品
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
                          onPressed: _isProcessing
                              ? null
                              : _toggleSelectedMeals,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: _isInSelectedMeals
                                ? Theme.of(context).colorScheme.secondary
                                : null,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isInSelectedMeals ? "已点" : "加入已点菜品"),
                        ),
                      ),
                    ] else ...[
                      // 从"网络菜谱"进入：加入我的菜谱和加入/移除已点菜品
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _enterAddToMyRecipesMode,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("加入我的菜谱"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : _toggleSelectedMeals,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: _isInSelectedMeals
                                ? Theme.of(context).colorScheme.secondary
                                : null,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isInSelectedMeals ? "已点" : "加入已点菜品"),
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
