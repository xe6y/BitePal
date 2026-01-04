import '../config/api_config.dart';
import 'http_client.dart';

/// 家庭管理服务
/// 处理家庭的创建、加入、退出等操作
class FamilyService {
  /// HTTP客户端
  final HttpClient _client = HttpClient();

  /// 单例实例
  static final FamilyService _instance = FamilyService._internal();

  /// 工厂构造函数
  factory FamilyService() => _instance;

  /// 私有构造函数
  FamilyService._internal();

  /// 获取我的家庭信息
  /// 返回: 家庭信息，如果未加入家庭则返回null
  Future<Family?> getMyFamily() async {
    final response = await _client.get(ApiConfig.family);

    if (response.isSuccess && response.data != null) {
      return Family.fromJson(response.data);
    }

    return null;
  }

  /// 创建家庭
  /// name: 家庭名称
  /// 返回: 创建的家庭信息
  Future<Family?> createFamily(String name) async {
    final response = await _client.post(
      ApiConfig.family,
      data: {'name': name},
    );

    if (response.isSuccess && response.data != null) {
      return Family.fromJson(response.data);
    }

    return null;
  }

  /// 加入家庭
  /// inviteCode: 邀请码
  /// nickname: 在家庭中的昵称（可选）
  /// 返回: 加入的家庭信息
  Future<Family?> joinFamily(String inviteCode, {String? nickname}) async {
    final response = await _client.post(
      ApiConfig.familyJoin,
      data: {
        'inviteCode': inviteCode,
        if (nickname != null) 'nickname': nickname,
      },
    );

    if (response.isSuccess && response.data != null) {
      return Family.fromJson(response.data);
    }

    return null;
  }

  /// 退出家庭
  /// 返回: 是否成功退出
  Future<bool> leaveFamily() async {
    final response = await _client.post(ApiConfig.familyLeave);
    return response.isSuccess;
  }

  /// 刷新邀请码
  /// 返回: 新的邀请码
  Future<String?> refreshInviteCode() async {
    final response = await _client.post(ApiConfig.familyInviteCode);

    if (response.isSuccess && response.data != null) {
      return response.data['inviteCode'];
    }

    return null;
  }

  /// 更新成员信息
  /// memberId: 成员ID
  /// nickname: 新的昵称
  /// 返回: 是否更新成功
  Future<bool> updateMember(String memberId, {String? nickname}) async {
    final response = await _client.put(
      '${ApiConfig.familyMembers}/$memberId',
      data: {
        if (nickname != null) 'nickname': nickname,
      },
    );
    return response.isSuccess;
  }

  /// 移除成员
  /// memberId: 成员ID
  /// 返回: 是否移除成功
  Future<bool> removeMember(String memberId) async {
    final response = await _client.delete(
      '${ApiConfig.familyMembers}/$memberId',
    );
    return response.isSuccess;
  }
}

/// 家庭模型
class Family {
  /// 家庭ID
  final String id;

  /// 家庭名称
  final String name;

  /// 邀请码
  final String inviteCode;

  /// 是否为创建者
  final bool isOwner;

  /// 成员列表
  final List<FamilyMemberBrief> members;

  Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.isOwner,
    required this.members,
  });

  /// 从JSON创建实例
  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      isOwner: json['isOwner'] ?? false,
      members: (json['members'] as List? ?? [])
          .map((e) => FamilyMemberBrief.fromJson(e))
          .toList(),
    );
  }
}

/// 家庭成员简要信息
class FamilyMemberBrief {
  /// 成员ID
  final String id;

  /// 用户ID
  final String userId;

  /// 昵称
  final String nickname;

  /// 头像
  final String? avatar;

  /// 角色
  final String role;

  /// 是否为创建者
  bool get isOwner => role == 'owner';

  FamilyMemberBrief({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.role,
  });

  /// 从JSON创建实例
  factory FamilyMemberBrief.fromJson(Map<String, dynamic> json) {
    return FamilyMemberBrief(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'member',
    );
  }
}

