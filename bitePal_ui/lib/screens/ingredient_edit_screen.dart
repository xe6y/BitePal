import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';
import '../services/http_client.dart';
import '../config/api_config.dart';

/// 食材添加/编辑页面
class IngredientEditScreen extends StatefulWidget {
  /// 要编辑的食材（为null时为添加模式）
  final IngredientItem? ingredient;

  /// 默认存储位置
  final String? defaultStorage;

  const IngredientEditScreen({
    super.key,
    this.ingredient,
    this.defaultStorage,
  });

  @override
  State<IngredientEditScreen> createState() => _IngredientEditScreenState();
}

class _IngredientEditScreenState extends State<IngredientEditScreen> {
  /// 食材服务
  final IngredientService _ingredientService = IngredientService();

  /// 分类服务
  final IngredientCategoryService _categoryService = IngredientCategoryService();

  /// HTTP客户端
  final HttpClient _httpClient = HttpClient();

  /// 图片选择器
  final ImagePicker _imagePicker = ImagePicker();

  /// 表单键
  final _formKey = GlobalKey<FormState>();

  /// 是否编辑模式
  bool get _isEditMode => widget.ingredient != null;

  /// 是否正在保存
  bool _isSaving = false;

  /// 是否正在加载分类
  bool _isLoadingCategories = true;

  /// 分类列表
  List<IngredientCategory> _categories = [];

  /// 选中的图片文件
  File? _selectedImageFile;

  /// 上传后的图片URL
  String? _uploadedImageUrl;

  // 表单字段控制器
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _noteController;

  // 表单状态
  String _selectedStorage = 'fridge';
  String _selectedCategoryId = 'cat_other';
  String _selectedIcon = '🥬';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  DateTime _purchaseDate = DateTime.now();

  /// 常用单位列表
  final List<String> _commonUnits = ['个', '斤', '克', '千克', '毫升', '升', '包', '袋', '盒', '瓶'];

  /// 常用图标列表
  final List<String> _commonIcons = [
    '🥬', '🥕', '🍅', '🥔', '🧅', '🥒', '🌽', '🥦',
    '🥩', '🍖', '🥓', '🍗', '🐟', '🦐', '🦀', '🥚',
    '🍎', '🍊', '🍋', '🍇', '🍓', '🍑', '🥝', '🍌',
    '🥛', '🧀', '🍞', '🍚', '🧂', '🫚', '🧄', '📦',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadCategories();
  }

  /// 初始化控制器
  void _initControllers() {
    final ingredient = widget.ingredient;
    _nameController = TextEditingController(text: ingredient?.name ?? '');
    _quantityController = TextEditingController(
      text: ingredient?.quantity != null && ingredient!.quantity > 0
          ? (ingredient.quantity == ingredient.quantity.truncateToDouble()
              ? ingredient.quantity.toInt().toString()
              : ingredient.quantity.toString())
          : '',
    );
    _unitController = TextEditingController(text: ingredient?.unit ?? '个');
    _noteController = TextEditingController(text: ingredient?.note ?? '');

    if (ingredient != null) {
      _selectedStorage = ingredient.storage;
      _selectedCategoryId = ingredient.categoryId.isNotEmpty ? ingredient.categoryId : 'cat_other';
      _selectedIcon = ingredient.icon;
      _uploadedImageUrl = ingredient.thumbnail;

      if (ingredient.expiryDate != null && ingredient.expiryDate!.isNotEmpty) {
        _expiryDate = DateTime.tryParse(ingredient.expiryDate!) ?? _expiryDate;
      }
      if (ingredient.purchaseDate != null && ingredient.purchaseDate!.isNotEmpty) {
        _purchaseDate = DateTime.tryParse(ingredient.purchaseDate!) ?? _purchaseDate;
      }
    } else if (widget.defaultStorage != null) {
      _selectedStorage = widget.defaultStorage!;
    }
  }

  /// 加载分类列表
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      _categories = await _categoryService.getCategories();
    } catch (e) {
      debugPrint('加载分类失败: $e');
    }

    if (mounted) {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 显示图片选择对话框
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImageFile != null || (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除图片', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImageFile = null;
                    _uploadedImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 上传图片
  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null) return _uploadedImageUrl;

    try {
      final response = await _httpClient.uploadFile(
        ApiConfig.uploadImage,
        filePath: _selectedImageFile!.path,
        fieldName: 'file',
      );

      if (response.isSuccess && response.data != null) {
        return response.data['url'] as String?;
      }
    } catch (e) {
      debugPrint('上传图片失败: $e');
    }

    return null;
  }

  /// 选择日期
  Future<void> _selectDate(bool isExpiryDate) async {
    final initialDate = isExpiryDate ? _expiryDate : _purchaseDate;
    final firstDate = isExpiryDate ? DateTime.now() : DateTime(2020);
    final lastDate = isExpiryDate
        ? DateTime.now().add(const Duration(days: 365 * 2))
        : DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('zh', 'CN'),
    );

    if (pickedDate != null) {
      setState(() {
        if (isExpiryDate) {
          _expiryDate = pickedDate;
        } else {
          _purchaseDate = pickedDate;
        }
      });
    }
  }

  /// 选择图标
  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择图标',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _commonIcons.length,
                itemBuilder: (context, index) {
                  final icon = _commonIcons[index];
                  final isSelected = icon == _selectedIcon;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedIcon = icon);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存食材
  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 上传图片（如果有新选择的图片）
      String? thumbnailUrl = _uploadedImageUrl;
      if (_selectedImageFile != null) {
        thumbnailUrl = await _uploadImage();
      }

      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final unit = _unitController.text;
      final expiryDateStr = '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}';
      final purchaseDateStr = '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}';

      IngredientItem? result;

      if (_isEditMode) {
        result = await _ingredientService.updateIngredient(
          widget.ingredient!.id,
          name: _nameController.text,
          quantity: quantity,
          unit: unit,
          storage: _selectedStorage,
          categoryId: _selectedCategoryId,
          thumbnail: thumbnailUrl,
          icon: _selectedIcon,
          note: _noteController.text,
          expiryDate: expiryDateStr,
          purchaseDate: purchaseDateStr,
        );
      } else {
        result = await _ingredientService.createIngredient(
          name: _nameController.text,
          quantity: quantity,
          unit: unit,
          storage: _selectedStorage,
          categoryId: _selectedCategoryId,
          thumbnail: thumbnailUrl,
          icon: _selectedIcon,
          note: _noteController.text,
          expiryDate: expiryDateStr,
          purchaseDate: purchaseDateStr,
        );
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? '更新成功' : '添加成功')),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? '更新失败' : '添加失败')),
        );
      }
    } catch (e) {
      debugPrint('保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
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
        title: Text(_isEditMode ? '编辑食材' : '添加食材'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveIngredient,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 图片选择区域
            _buildImageSection(),
            const SizedBox(height: 24),

            // 基本信息
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // 分类和存储位置
            _buildCategorySection(),
            const SizedBox(height: 24),

            // 日期信息
            _buildDateSection(),
            const SizedBox(height: 24),

            // 备注
            _buildNoteSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// 构建图片选择区域
  Widget _buildImageSection() {
    final hasImage = _selectedImageFile != null ||
        (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '食材图片',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 图片预览
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedImageFile != null
                            ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                            : Image.network(
                                _uploadedImageUrl!.startsWith('http')
                                    ? _uploadedImageUrl!
                                    : '${ApiConfig.devBaseUrl.replaceAll('/api', '')}$_uploadedImageUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '添加图片',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // 图标选择
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('或选择图标'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showIconPicker,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(_selectedIcon, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建基本信息区域
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基本信息',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // 名称
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '食材名称 *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入食材名称';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 数量和单位
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '数量',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _commonUnits.contains(_unitController.text)
                    ? _unitController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: '单位',
                  border: OutlineInputBorder(),
                ),
                items: _commonUnits
                    .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _unitController.text = value;
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建分类区域
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类与存储',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // 食材分类
        const Text('食材分类'),
        const SizedBox(height: 8),
        _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = cat.id == _selectedCategoryId;
                  return FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.icon),
                        const SizedBox(width: 4),
                        Text(cat.name),
                      ],
                    ),
                    selectedColor: _parseColor(cat.color).withValues(alpha: 0.2),
                    checkmarkColor: _parseColor(cat.color),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategoryId = cat.id);
                      }
                    },
                  );
                }).toList(),
              ),
        const SizedBox(height: 16),

        // 存储位置
        const Text('存储位置'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'room', label: Text('常温'), icon: Icon(Icons.home_outlined)),
            ButtonSegment(value: 'fridge', label: Text('冷藏'), icon: Icon(Icons.kitchen_outlined)),
            ButtonSegment(value: 'freezer', label: Text('冷冻'), icon: Icon(Icons.ac_unit)),
          ],
          selected: {_selectedStorage},
          onSelectionChanged: (selection) {
            setState(() => _selectedStorage = selection.first);
          },
        ),
      ],
    );
  }

  /// 构建日期区域
  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '日期信息',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '购买日期',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_cart_outlined),
                  ),
                  child: Text(
                    '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(true),
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '过期日期',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(
                    '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建备注区域
  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备注',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '添加备注信息...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes),
          ),
        ),
      ],
    );
  }
}

