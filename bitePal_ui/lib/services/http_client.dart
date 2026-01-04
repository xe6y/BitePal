import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// HTTP客户端封装
/// 提供统一的网络请求方法，自动处理Token和错误
class HttpClient {
  /// 单例实例
  static final HttpClient _instance = HttpClient._internal();

  /// 工厂构造函数
  factory HttpClient() => _instance;

  /// 私有构造函数
  HttpClient._internal();

  /// 存储Token的键名
  static const String _tokenKey = 'auth_token';

  /// 获取存储的Token
  /// 返回: Token字符串，如果不存在则返回null
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 保存Token
  /// token: 要保存的Token字符串
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// 清除Token（退出登录时调用）
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// 检查是否已登录
  /// 返回: 是否已登录
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 构建请求头
  /// needAuth: 是否需要认证
  /// 返回: 请求头Map
  Future<Map<String, String>> _buildHeaders({bool needAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// 构建完整URL
  /// path: API路径
  /// queryParams: 查询参数
  /// 返回: 完整URL
  Uri _buildUrl(String path, {Map<String, dynamic>? queryParams}) {
    final url = '${ApiConfig.baseUrl}$path';
    if (queryParams != null && queryParams.isNotEmpty) {
      // 过滤掉null值并转换为字符串
      final filteredParams = queryParams.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value.toString()))
          .fold<Map<String, String>>({}, (map, e) {
            map[e.key] = e.value;
            return map;
          });
      return Uri.parse(url).replace(queryParameters: filteredParams);
    }
    return Uri.parse(url);
  }

  /// 处理响应
  /// response: HTTP响应
  /// 返回: 解析后的响应数据
  ApiResponse _handleResponse(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return ApiResponse(
      code: body['code'] ?? response.statusCode,
      message: body['message'] ?? '',
      data: body['data'],
    );
  }

  /// GET请求
  /// path: API路径
  /// queryParams: 查询参数
  /// needAuth: 是否需要认证
  /// 返回: API响应
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool needAuth = true,
  }) async {
    try {
      final url = _buildUrl(path, queryParams: queryParams);
      final headers = await _buildHeaders(needAuth: needAuth);

      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: ApiConfig.connectTimeout));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(code: -1, message: '网络请求失败：$e', data: null);
    }
  }

  /// POST请求
  /// path: API路径
  /// data: 请求体数据
  /// needAuth: 是否需要认证
  /// 返回: API响应
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? data,
    bool needAuth = true,
  }) async {
    try {
      final url = _buildUrl(path);
      final headers = await _buildHeaders(needAuth: needAuth);

      final response = await http
          .post(
            url,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(Duration(seconds: ApiConfig.connectTimeout));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(code: -1, message: '网络请求失败：$e', data: null);
    }
  }

  /// PUT请求
  /// path: API路径
  /// data: 请求体数据
  /// needAuth: 是否需要认证
  /// 返回: API响应
  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? data,
    bool needAuth = true,
  }) async {
    try {
      final url = _buildUrl(path);
      final headers = await _buildHeaders(needAuth: needAuth);

      final response = await http
          .put(
            url,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(Duration(seconds: ApiConfig.connectTimeout));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(code: -1, message: '网络请求失败：$e', data: null);
    }
  }

  /// DELETE请求
  /// path: API路径
  /// needAuth: 是否需要认证
  /// 返回: API响应
  Future<ApiResponse> delete(String path, {bool needAuth = true}) async {
    try {
      final url = _buildUrl(path);
      final headers = await _buildHeaders(needAuth: needAuth);

      final response = await http
          .delete(url, headers: headers)
          .timeout(Duration(seconds: ApiConfig.connectTimeout));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(code: -1, message: '网络请求失败：$e', data: null);
    }
  }
}

/// API响应结构
class ApiResponse {
  /// 响应状态码
  final int code;

  /// 响应消息
  final String message;

  /// 响应数据
  final dynamic data;

  ApiResponse({required this.code, required this.message, this.data});

  /// 是否成功
  bool get isSuccess => code == 200;

  /// 是否未授权（Token过期或无效）
  bool get isUnauthorized => code == 401;
}

/// 分页响应结构
class PagedData<T> {
  /// 数据列表
  final List<T> list;

  /// 总数
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  final int pageSize;

  PagedData({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  /// 是否有更多数据
  bool get hasMore => page * pageSize < total;
}
