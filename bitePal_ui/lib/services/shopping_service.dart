import '../config/api_config.dart';
import '../models/shopping_item.dart';
import 'http_client.dart';

/// 购物清单服务
/// 处理购物清单的增删改查
class ShoppingService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final ShoppingService _instance = ShoppingService._internal();

  /// 工厂构造函数
  factory ShoppingService() => _instance;

  /// 私有构造函数
  ShoppingService._internal();

  /// 获取购物清单列表
  /// page: 页码
  /// pageSize: 每页数量
  /// completed: 是否只显示已完成
  /// 返回: 购物清单列表和分页信息
  Future<PagedData<ShoppingList>?> getShoppingLists({
    int page = 1,
    int pageSize = 20,
    bool? completed,
  }) async {
    final response = await _client.get(
      ApiConfig.shoppingLists,
      queryParams: {
        'page': page,
        'pageSize': pageSize,
        if (completed != null) 'completed': completed,
      },
    );

    if (response.isSuccess && response.data != null) {
      final list = (response.data['list'] as List? ?? [])
          .map((e) => ShoppingList.fromJson(e))
          .toList();
      return PagedData<ShoppingList>(
        list: list,
        total: response.data['total'] ?? 0,
        page: response.data['page'] ?? page,
        pageSize: response.data['pageSize'] ?? pageSize,
      );
    }

    return null;
  }

  /// 获取当前购物清单
  /// 返回: 当前购物清单
  Future<ShoppingList?> getCurrentShoppingList() async {
    final response = await _client.get(ApiConfig.currentShoppingList);

    if (response.isSuccess && response.data != null) {
      return ShoppingList.fromJson(response.data);
    }

    return null;
  }

  /// 创建购物清单
  /// name: 清单名称
  /// items: 购物项列表
  /// 返回: 创建的购物清单
  Future<ShoppingList?> createShoppingList({
    String? name,
    List<ShoppingItem>? items,
  }) async {
    final response = await _client.post(
      ApiConfig.shoppingLists,
      data: {
        if (name != null) 'name': name,
        if (items != null) 'items': items.map((e) => e.toJson()).toList(),
      },
    );

    if (response.isSuccess && response.data != null) {
      return ShoppingList.fromJson(response.data);
    }

    return null;
  }

  /// 更新购物清单
  /// listId: 清单ID
  /// name: 清单名称
  /// items: 购物项列表
  /// 返回: 更新后的购物清单
  Future<ShoppingList?> updateShoppingList(
    String listId, {
    String? name,
    List<ShoppingItem>? items,
  }) async {
    final response = await _client.put(
      '${ApiConfig.shoppingLists}/$listId',
      data: {
        if (name != null) 'name': name,
        if (items != null) 'items': items.map((e) => e.toJson()).toList(),
      },
    );

    if (response.isSuccess && response.data != null) {
      return ShoppingList.fromJson(response.data);
    }

    return null;
  }

  /// 添加购物项
  /// listId: 清单ID
  /// name: 商品名称
  /// amount: 数量
  /// price: 价格
  /// 返回: 添加的购物项
  Future<ShoppingItem?> addShoppingItem(
    String listId, {
    required String name,
    String? amount,
    double? price,
  }) async {
    final response = await _client.post(
      '${ApiConfig.shoppingLists}/$listId/items',
      data: {
        'name': name,
        if (amount != null) 'amount': amount,
        if (price != null) 'price': price,
      },
    );

    if (response.isSuccess && response.data != null) {
      return ShoppingItem.fromJson(response.data);
    }

    return null;
  }

  /// 更新购物项
  /// listId: 清单ID
  /// itemId: 购物项ID
  /// name: 商品名称
  /// amount: 数量
  /// price: 价格
  /// checked: 是否已购买
  /// 返回: 更新后的购物项
  Future<ShoppingItem?> updateShoppingItem(
    String listId,
    String itemId, {
    String? name,
    String? amount,
    double? price,
    bool? checked,
  }) async {
    final response = await _client.put(
      '${ApiConfig.shoppingLists}/$listId/items/$itemId',
      data: {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (price != null) 'price': price,
        if (checked != null) 'checked': checked,
      },
    );

    if (response.isSuccess && response.data != null) {
      return ShoppingItem.fromJson(response.data);
    }

    return null;
  }

  /// 删除购物项
  /// listId: 清单ID
  /// itemId: 购物项ID
  /// 返回: 是否删除成功
  Future<bool> deleteShoppingItem(String listId, String itemId) async {
    final response = await _client.delete(
      '${ApiConfig.shoppingLists}/$listId/items/$itemId',
    );
    return response.isSuccess;
  }

  /// 完成购物清单
  /// listId: 清单ID
  /// 返回: 是否完成成功
  Future<bool> completeShoppingList(String listId) async {
    final response = await _client.post(
      '${ApiConfig.shoppingLists}/$listId/complete',
    );
    return response.isSuccess;
  }

  /// 分享购物清单
  /// listId: 清单ID
  /// 返回: 分享链接信息
  Future<ShareResult?> shareShoppingList(String listId) async {
    final response = await _client.post(
      '${ApiConfig.shoppingLists}/$listId/share',
    );

    if (response.isSuccess && response.data != null) {
      return ShareResult(
        shareUrl: response.data['shareUrl'] ?? '',
        shareCode: response.data['shareCode'],
      );
    }

    return null;
  }

  /// 获取购物清单详情
  /// listId: 清单ID
  /// 返回: 购物清单详情
  Future<ShoppingList?> getShoppingListDetail(String listId) async {
    final response = await _client.get('${ApiConfig.shoppingLists}/$listId');

    if (response.isSuccess && response.data != null) {
      return ShoppingList.fromJson(response.data);
    }

    return null;
  }

  /// 获取购物订单历史
  /// page: 页码
  /// pageSize: 每页数量
  /// startDate: 开始日期
  /// endDate: 结束日期
  /// 返回: 购物清单历史
  Future<PagedData<ShoppingListHistory>?> getShoppingHistory({
    int page = 1,
    int pageSize = 20,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _client.get(
      ApiConfig.shoppingHistory,
      queryParams: {
        'page': page,
        'pageSize': pageSize,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );

    if (response.isSuccess && response.data != null) {
      final list = (response.data['list'] as List? ?? [])
          .map((e) => ShoppingListHistory.fromJson(e))
          .toList();
      return PagedData<ShoppingListHistory>(
        list: list,
        total: response.data['total'] ?? 0,
        page: response.data['page'] ?? page,
        pageSize: response.data['pageSize'] ?? pageSize,
      );
    }

    return null;
  }
}

/// 分享结果
class ShareResult {
  /// 分享链接
  final String shareUrl;

  /// 分享码
  final String? shareCode;

  ShareResult({
    required this.shareUrl,
    this.shareCode,
  });
}

/// 购物清单历史项
class ShoppingListHistory {
  /// 清单ID
  final String id;

  /// 清单名称
  final String name;

  /// 总价
  final double totalPrice;

  /// 商品数量
  final int itemCount;

  /// 完成时间
  final String? completedAt;

  ShoppingListHistory({
    required this.id,
    required this.name,
    required this.totalPrice,
    required this.itemCount,
    this.completedAt,
  });

  /// 从JSON创建实例
  factory ShoppingListHistory.fromJson(Map<String, dynamic> json) {
    return ShoppingListHistory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '购物清单',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      itemCount: json['itemCount'] ?? 0,
      completedAt: json['completedAt'],
    );
  }
}

