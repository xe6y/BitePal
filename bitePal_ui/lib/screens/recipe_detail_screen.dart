import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/menu_service.dart';

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
  /// 菜谱服务
  final RecipeService _recipeService = RecipeService();

  /// 菜单服务
  final MenuService _menuService = MenuService();

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

  @override
  void initState() {
    super.initState();
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
    _difficultyController = TextEditingController(text: recipe.difficulty);
    _tags = List.from(recipe.tags);
    _ingredients = recipe.ingredients ?? [];
    _steps = recipe.steps ?? [];
    _isFavorite = recipe.favorite;
    _initializeControllers();
  }

  /// 使用模拟数据初始化
  void _initializeMockData() {
    _nameController = TextEditingController(text: "红烧肉");
    _timeController = TextEditingController(text: "45 分钟");
    _difficultyController = TextEditingController(text: "中等");
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
    final result = await _recipeService.updateRecipe(widget.recipeId, updatedRecipe);

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
          const SnackBar(content: Text('保存成功（本地）'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite() async {
    final newFavorite = !_isFavorite;
    final success = await _recipeService.toggleFavorite(widget.recipeId, newFavorite);
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
          const SnackBar(content: Text('已加入今日菜单'), duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入失败，请重试'), duration: Duration(seconds: 1)),
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
          const SnackBar(content: Text('已加入我的菜单'), duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入失败，请重试'), duration: Duration(seconds: 1)),
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
      _ingredients.removeAt(index);
      _ingredientNameControllers[index]?.dispose();
      _ingredientAmountControllers[index]?.dispose();
      _ingredientNameControllers.remove(index);
      _ingredientAmountControllers.remove(index);
      // 重新索引
      final newControllers = <int, TextEditingController>{};
      final newAmountControllers = <int, TextEditingController>{};
      for (int i = 0; i < _ingredients.length; i++) {
        newControllers[i] =
            _ingredientNameControllers[i] ?? TextEditingController();
        newAmountControllers[i] =
            _ingredientAmountControllers[i] ?? TextEditingController();
      }
      _ingredientNameControllers.clear();
      _ingredientAmountControllers.clear();
      _ingredientNameControllers.addAll(newControllers);
      _ingredientAmountControllers.addAll(newAmountControllers);
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
      _steps.removeAt(index);
      _stepControllers[index]?.dispose();
      _stepControllers.remove(index);
      // 重新索引
      final newControllers = <int, TextEditingController>{};
      for (int i = 0; i < _steps.length; i++) {
        newControllers[i] = _stepControllers[i] ?? TextEditingController();
      }
      _stepControllers.clear();
      _stepControllers.addAll(newControllers);
    });
  }

  Widget _buildStepItem(int index) {
    // 确保控制器存在
    if (!_stepControllers.containsKey(index)) {
      _stepControllers[index] = TextEditingController(text: _steps[index]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
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
          const SizedBox(width: 8),
          const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _stepControllers[index],
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _steps[index] = value;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _removeStep(index),
            color: Colors.red,
          ),
        ],
      ),
    );
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
                          ? SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _timeController,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
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
                          ? SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _difficultyController,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(
                              _difficultyController.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
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
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ..._tags.asMap().entries.map((entry) {
                                final index = entry.key;
                                final tag = entry.value;
                                return LongPressDraggable<String>(
                                  key: ValueKey('tag_$index'),
                                  data: tag,
                                  feedback: Material(
                                    child: Chip(
                                      label: Text(tag),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: Chip(
                                      label: Text(tag),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      onDeleted: () => _removeTag(index),
                                    ),
                                  ),
                                  child: DragTarget<String>(
                                    onAcceptWithDetails: (details) {
                                      final draggedTag = details.data;
                                      if (draggedTag != tag) {
                                        setState(() {
                                          final draggedIndex = _tags.indexOf(
                                            draggedTag,
                                          );
                                          final targetIndex = index;
                                          _tags.removeAt(draggedIndex);
                                          _tags.insert(
                                            draggedIndex < targetIndex
                                                ? targetIndex - 1
                                                : targetIndex,
                                            draggedTag,
                                          );
                                        });
                                      }
                                    },
                                    builder:
                                        (context, candidateData, rejectedData) {
                                          return Chip(
                                            label: Text(tag),
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            onDeleted: () => _removeTag(index),
                                            deleteIcon: const Icon(
                                              Icons.drag_handle,
                                              size: 18,
                                            ),
                                          );
                                        },
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _newTagController,
                                  decoration: InputDecoration(
                                    hintText: '新标签',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _addTag(),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) {
                            return Chip(
                              key: ValueKey(tag),
                              label: Text(tag),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
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
                  Card(
                    child: Column(
                      children: [
                        ..._ingredients.asMap().entries.map((entry) {
                          final index = entry.key;
                          final ingredient = entry.value;
                          return ListTile(
                            leading: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: ingredient.available
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: _isEditing
                                ? TextField(
                                    controller:
                                        _ingredientNameControllers[index],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _ingredients[index] = Ingredient(
                                          name: value,
                                          amount: _ingredients[index].amount,
                                          available:
                                              _ingredients[index].available,
                                        );
                                      });
                                    },
                                  )
                                : Text(ingredient.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isEditing
                                    ? SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller:
                                              _ingredientAmountControllers[index],
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _ingredients[index] = Ingredient(
                                                name: _ingredients[index].name,
                                                amount: value,
                                                available: _ingredients[index]
                                                    .available,
                                              );
                                            });
                                          },
                                        ),
                                      )
                                    : Text(
                                        ingredient.amount,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                if (_isEditing)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    onPressed: () => _removeIngredient(index),
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                          );
                        }),
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _newIngredientNameController,
                                    decoration: InputDecoration(
                                      hintText: '食材名称',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _newIngredientAmountController,
                                    decoration: InputDecoration(
                                      hintText: '用量',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) => _addIngredient(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle),
                                  onPressed: _addIngredient,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
                      ? Column(
                          children: _steps.asMap().entries.map((entry) {
                            final index = entry.key;
                            return LongPressDraggable<int>(
                              key: ValueKey('step_$index'),
                              data: index,
                              feedback: Material(
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 32,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.drag_handle,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _steps[index],
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _buildStepItem(index),
                              ),
                              child: DragTarget<int>(
                                onAcceptWithDetails: (details) {
                                  final draggedIndex = details.data;
                                  if (draggedIndex != index) {
                                    setState(() {
                                      // 移动步骤
                                      final movedStep = _steps.removeAt(
                                        draggedIndex,
                                      );
                                      _steps.insert(
                                        draggedIndex < index
                                            ? index - 1
                                            : index,
                                        movedStep,
                                      );
                                      // 移动对应的控制器
                                      final movedController = _stepControllers
                                          .remove(draggedIndex);
                                      if (movedController != null) {
                                        // 重新构建控制器映射
                                        final newControllers =
                                            <int, TextEditingController>{};
                                        for (
                                          int i = 0;
                                          i < _steps.length;
                                          i++
                                        ) {
                                          if (i ==
                                              (draggedIndex < index
                                                  ? index - 1
                                                  : index)) {
                                            newControllers[i] = movedController;
                                          } else if (i < draggedIndex &&
                                              i < index) {
                                            newControllers[i] =
                                                _stepControllers[i] ??
                                                TextEditingController(
                                                  text: _steps[i],
                                                );
                                          } else if (i >= draggedIndex &&
                                              i < index) {
                                            newControllers[i] =
                                                _stepControllers[i + 1] ??
                                                TextEditingController(
                                                  text: _steps[i],
                                                );
                                          } else if (i > index &&
                                              i <= draggedIndex) {
                                            newControllers[i] =
                                                _stepControllers[i - 1] ??
                                                TextEditingController(
                                                  text: _steps[i],
                                                );
                                          } else {
                                            newControllers[i] =
                                                _stepControllers[i] ??
                                                TextEditingController(
                                                  text: _steps[i],
                                                );
                                          }
                                        }
                                        _stepControllers.clear();
                                        _stepControllers.addAll(newControllers);
                                      } else {
                                        // 如果没有控制器，重新初始化
                                        _initializeControllers();
                                      }
                                    });
                                  }
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                      return _buildStepItem(index);
                                    },
                              ),
                            );
                          }).toList(),
                        )
                      : Column(
                          children: _steps.asMap().entries.map((entry) {
                            final index = entry.key;
                            final step = entry.value;
                            return Padding(
                              key: ValueKey('step_$index'),
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${_steps.length + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _newStepController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: '输入新步骤...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              onSubmitted: (_) => _addStep(),
                            ),
                          ),
                        ],
                      ),
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
