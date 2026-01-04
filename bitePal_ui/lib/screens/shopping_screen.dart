import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';
import '../widgets/refreshable_screen.dart';
import '../widgets/edit_item_dialog.dart';

/// 购物清单页面
class ShoppingScreen extends RefreshableScreen {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> with RefreshableScreenState<ShoppingScreen> {
  /// 购物清单服务
  final ShoppingService _shoppingService = ShoppingService();

  /// 当前购物清单
  ShoppingList? _currentList;

  /// 购物项列表
  List<ShoppingItem> _items = [];

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  @override
  Future<void> refresh() async {
    await _loadShoppingList();
  }

  /// 加载购物清单
  Future<void> _loadShoppingList() async {
    setState(() => _isLoading = true);

    try {
      final list = await _shoppingService.getCurrentShoppingList();
      if (list != null) {
        _currentList = list;
        _items = list.items;
      } else {
        // 使用模拟数据
        _loadMockData();
      }
    } catch (e) {
      debugPrint('加载购物清单失败: $e');
      _loadMockData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 加载模拟数据
  void _loadMockData() {
    _items = [
      ShoppingItem(id: '1', name: "西红柿", amount: "2个", price: 4.5),
      ShoppingItem(id: '2', name: "土豆", amount: "3个", price: 3.2),
      ShoppingItem(id: '3', name: "牛排", amount: "2块", price: 89),
    ];
  }

  /// 切换购物项状态
  Future<void> _toggleItem(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items[index];
    final newChecked = !item.checked;

    // 如果有真实的清单ID，调用API更新
    if (_currentList != null) {
      await _shoppingService.updateShoppingItem(
        _currentList!.id,
        id,
        checked: newChecked,
      );
    }

    setState(() {
      _items[index] = item.copyWith(checked: newChecked);
    });
  }

  /// 编辑购物项
  void _editItem(ShoppingItem item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(
        item: item,
        onSave: (updatedItem) async {
          // 如果有真实的清单ID，调用API更新
          if (_currentList != null) {
            await _shoppingService.updateShoppingItem(
              _currentList!.id,
              item.id,
              name: updatedItem.name,
              amount: updatedItem.amount,
              price: updatedItem.price,
            );
          }

          setState(() {
            _items = _items.map((i) => i.id == updatedItem.id ? updatedItem : i).toList();
          });
        },
      ),
    );
  }

  /// 删除购物项
  Future<void> _deleteItem(ShoppingItem item) async {
    if (_currentList != null) {
      await _shoppingService.deleteShoppingItem(_currentList!.id, item.id);
    }

    setState(() {
      _items.removeWhere((i) => i.id == item.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除'), duration: Duration(seconds: 1)),
      );
    }
  }

  /// 完成购物
  Future<void> _completeShoppingList() async {
    if (_currentList != null) {
      await _shoppingService.completeShoppingList(_currentList!.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('购物清单已完成'), duration: Duration(seconds: 1)),
      );
    }
  }

  /// 分享购物清单
  Future<void> _shareShoppingList() async {
    if (_currentList != null) {
      final result = await _shoppingService.shareShoppingList(_currentList!.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享链接: ${result.shareUrl}'), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  /// 显示添加购物项对话框
  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加商品'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '商品名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: '数量',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '预估价格',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
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
                final price = double.tryParse(priceController.text) ?? 0;

                // 如果有真实的清单ID，调用API添加
                if (_currentList != null) {
                  await _shoppingService.addShoppingItem(
                    _currentList!.id,
                    name: nameController.text,
                    amount: amountController.text,
                    price: price,
                  );
                  _loadShoppingList();
                } else {
                  // 本地添加
                  setState(() {
                    _items.add(ShoppingItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      amount: amountController.text,
                      price: price,
                    ));
                  });
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

  /// 计算总价
  double get _total {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "购物清单",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _showAddItemDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: _shareShoppingList,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 购物项列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadShoppingList,
                      child: _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "购物清单为空",
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _showAddItemDialog,
                                    child: const Text("添加商品"),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Dismissible(
                                  key: Key(item.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (_) => _deleteItem(item),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: IconButton(
                                        icon: Icon(
                                          item.checked ? Icons.check_circle : Icons.circle_outlined,
                                          color: item.checked
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                        ),
                                        onPressed: () => _toggleItem(item.id),
                                      ),
                                      title: Text(
                                        item.name,
                                        style: TextStyle(
                                          decoration: item.checked ? TextDecoration.lineThrough : null,
                                          color: item.checked
                                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                                              : null,
                                        ),
                                      ),
                                      subtitle: Text(item.amount),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "¥${item.price.toStringAsFixed(1)}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              decoration: item.checked ? TextDecoration.lineThrough : null,
                                              color: item.checked
                                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                                                  : null,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            onPressed: () => _editItem(item),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
            // 底部总计和结账
            if (_items.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "预计总计",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          "¥ ${_total.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _completeShoppingList,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          "购买结束",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
