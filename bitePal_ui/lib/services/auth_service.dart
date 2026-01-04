import '../config/api_config.dart';
import '../models/user.dart';
import 'http_client.dart';

/// 认证服务
/// 处理用户登录、注册、获取用户信息等
class AuthService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final AuthService _instance = AuthService._internal();

  /// 工厂构造函数
  factory AuthService() => _instance;

  /// 私有构造函数
  AuthService._internal();

  /// 当前登录用户
  User? _currentUser;

  /// 获取当前用户
  User? get currentUser => _currentUser;

  /// 用户登录
  /// username: 用户名或手机号
  /// password: 密码
  /// 返回: 登录结果
  Future<AuthResult> login(String username, String password) async {
    final response = await _client.post(
      ApiConfig.login,
      data: {
        'username': username,
        'password': password,
      },
      needAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      // 保存Token
      final token = response.data['token'];
      if (token != null) {
        await _client.saveToken(token);
      }

      // 解析用户信息
      if (response.data['user'] != null) {
        _currentUser = User.fromJson(response.data['user']);
      }

      return AuthResult(success: true, message: '登录成功', user: _currentUser);
    }

    return AuthResult(success: false, message: response.message);
  }

  /// 用户注册
  /// username: 用户名
  /// password: 密码
  /// nickname: 昵称（可选）
  /// phone: 手机号（可选）
  /// 返回: 注册结果
  Future<AuthResult> register(
    String username,
    String password, {
    String? nickname,
    String? phone,
  }) async {
    final response = await _client.post(
      ApiConfig.register,
      data: {
        'username': username,
        'password': password,
        if (nickname != null) 'nickname': nickname,
        if (phone != null) 'phone': phone,
      },
      needAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      // 保存Token
      final token = response.data['token'];
      if (token != null) {
        await _client.saveToken(token);
      }

      // 解析用户信息
      if (response.data['user'] != null) {
        _currentUser = User.fromJson(response.data['user']);
      }

      return AuthResult(success: true, message: '注册成功', user: _currentUser);
    }

    return AuthResult(success: false, message: response.message);
  }

  /// 获取用户信息
  /// 返回: 用户信息
  Future<User?> getUserInfo() async {
    final response = await _client.get(ApiConfig.userInfo);

    if (response.isSuccess && response.data != null) {
      _currentUser = User.fromJson(response.data);
      return _currentUser;
    }

    return null;
  }

  /// 更新用户信息
  /// nickname: 新昵称（可选）
  /// avatar: 新头像URL（可选）
  /// 返回: 更新后的用户信息
  Future<User?> updateUserInfo({String? nickname, String? avatar}) async {
    final response = await _client.put(
      ApiConfig.userInfo,
      data: {
        if (nickname != null) 'nickname': nickname,
        if (avatar != null) 'avatar': avatar,
      },
    );

    if (response.isSuccess && response.data != null) {
      _currentUser = User.fromJson(response.data);
      return _currentUser;
    }

    return null;
  }

  /// 获取用户统计数据
  /// month: 月份（可选，格式：YYYY-MM）
  /// 返回: 用户统计数据
  Future<UserStats?> getUserStats({String? month}) async {
    final response = await _client.get(
      ApiConfig.userStats,
      queryParams: {
        if (month != null) 'month': month,
      },
    );

    if (response.isSuccess && response.data != null) {
      return UserStats.fromJson(response.data);
    }

    return null;
  }

  /// 退出登录
  Future<void> logout() async {
    await _client.clearToken();
    _currentUser = null;
  }

  /// 检查是否已登录
  /// 返回: 是否已登录
  Future<bool> isLoggedIn() async {
    return await _client.isLoggedIn();
  }

  /// 自动登录（检查Token并获取用户信息）
  /// 返回: 是否自动登录成功
  Future<bool> autoLogin() async {
    if (await isLoggedIn()) {
      final user = await getUserInfo();
      return user != null;
    }
    return false;
  }
}

/// 认证结果
class AuthResult {
  /// 是否成功
  final bool success;

  /// 消息
  final String message;

  /// 用户信息
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

