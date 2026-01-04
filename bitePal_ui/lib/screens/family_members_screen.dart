import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/family_service.dart';
import '../utils/app_theme.dart';

/// 家庭成员管理页面
class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  /// 家庭服务
  final FamilyService _familyService = FamilyService();

  /// 家庭信息
  Family? _family;

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  /// 加载家庭信息
  Future<void> _loadFamily() async {
    setState(() => _isLoading = true);

    try {
      final result = await _familyService.getMyFamily();
      _family = result;
    } catch (e) {
      debugPrint('加载家庭信息失败: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 创建家庭
  Future<void> _createFamily() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建家庭'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '家庭名称',
            hintText: '例如：温馨小窝',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final family = await _familyService.createFamily(nameController.text);
      if (family != null) {
        setState(() => _family = family);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('家庭创建成功！')),
          );
        }
      }
    }
    nameController.dispose();
  }

  /// 加入家庭
  Future<void> _joinFamily() async {
    final codeController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入家庭'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请输入家庭邀请码',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: '邀请码',
                hintText: '6位邀请码',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('加入'),
          ),
        ],
      ),
    );

    if (result == true && codeController.text.isNotEmpty) {
      final family = await _familyService.joinFamily(codeController.text);
      if (family != null) {
        setState(() => _family = family);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('加入家庭成功！')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('邀请码无效，请检查后重试')),
          );
        }
      }
    }
    codeController.dispose();
  }

  /// 退出家庭
  Future<void> _leaveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出家庭'),
        content: Text(_family!.isOwner
            ? '您是家庭创建者，退出后家庭将被解散。确定要退出吗？'
            : '确定要退出当前家庭吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _familyService.leaveFamily();
      if (success) {
        setState(() => _family = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已退出家庭')),
          );
        }
      }
    }
  }

  /// 复制邀请码
  void _copyInviteCode() {
    if (_family == null) return;
    Clipboard.setData(ClipboardData(text: _family!.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('邀请码已复制到剪贴板')),
    );
  }

  /// 刷新邀请码
  Future<void> _refreshInviteCode() async {
    final newCode = await _familyService.refreshInviteCode();
    if (newCode != null) {
      await _loadFamily();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('邀请码已刷新')),
        );
      }
    }
  }

  /// 移除成员
  Future<void> _removeMember(FamilyMemberBrief member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除成员'),
        content: Text('确定要移除 ${member.nickname} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _familyService.removeMember(member.id);
      if (success) {
        await _loadFamily();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('成员已移除')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('家庭成员'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFamily,
              color: AppColors.primary,
              child: _family == null ? _buildNoFamilyState() : _buildFamilyContent(),
            ),
    );
  }

  /// 构建无家庭状态
  Widget _buildNoFamilyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '还没有加入家庭',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '创建或加入一个家庭，与家人共享菜谱',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _joinFamily,
                        icon: const Icon(Icons.group_add),
                        label: const Text('加入家庭'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createFamily,
                        icon: const Icon(Icons.add_home),
                        label: const Text('创建家庭'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建家庭内容
  Widget _buildFamilyContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 家庭信息卡片
          _buildFamilyInfoCard(),
          // 邀请码卡片
          _buildInviteCodeCard(),
          // 成员列表
          _buildMembersList(),
          // 退出按钮
          _buildLeaveButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建家庭信息卡片
  Widget _buildFamilyInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _family!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_family!.members.length} 位成员',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_family!.isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '创建者',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建邀请码卡片
  Widget _buildInviteCodeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.vpn_key,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '邀请码',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _family!.inviteCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _copyInviteCode,
                icon: const Icon(Icons.copy),
                tooltip: '复制',
              ),
              if (_family!.isOwner)
                IconButton(
                  onPressed: _refreshInviteCode,
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '分享此邀请码给家人，即可加入家庭',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成员列表
  Widget _buildMembersList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '家庭成员',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _family!.members.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final member = _family!.members[index];
              return _buildMemberItem(member);
            },
          ),
        ],
      ),
    );
  }

  /// 构建成员项
  Widget _buildMemberItem(FamilyMemberBrief member) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: member.avatar != null ? NetworkImage(member.avatar!) : null,
            child: member.avatar == null
                ? Text(
                    member.nickname.isNotEmpty ? member.nickname[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (member.isOwner) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '创建者',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // 操作按钮
          if (_family!.isOwner && !member.isOwner)
            IconButton(
              onPressed: () => _removeMember(member),
              icon: Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
              ),
              tooltip: '移除',
            ),
        ],
      ),
    );
  }

  /// 构建退出按钮
  Widget _buildLeaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _leaveFamily,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(_family!.isOwner ? '解散家庭' : '退出家庭'),
        ),
      ),
    );
  }
}

