import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

/// App设置页面
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  /// 深色模式
  bool _darkMode = false;

  /// 消息通知
  bool _notifications = true;

  /// 食材过期提醒
  bool _expiryReminder = true;

  /// 提前提醒天数
  int _reminderDays = 3;

  /// 自动添加到购物清单
  bool _autoAddShopping = false;

  /// 显示菜谱难度
  bool _showDifficulty = true;

  /// 显示烹饪时间
  bool _showCookingTime = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
      _expiryReminder = prefs.getBool('expiryReminder') ?? true;
      _reminderDays = prefs.getInt('reminderDays') ?? 3;
      _autoAddShopping = prefs.getBool('autoAddShopping') ?? false;
      _showDifficulty = prefs.getBool('showDifficulty') ?? true;
      _showCookingTime = prefs.getBool('showCookingTime') ?? true;
    });
  }

  /// 保存设置
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('App 设置'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 外观设置
            _buildSectionTitle('外观设置'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.dark_mode,
                title: '深色模式',
                subtitle: '开启后界面将使用深色主题',
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  _saveSetting('darkMode', value);
                  // 这里可以通知全局主题变化
                },
              ),
            ]),

            // 通知设置
            _buildSectionTitle('通知设置'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.notifications,
                title: '消息通知',
                subtitle: '接收应用消息推送',
                value: _notifications,
                onChanged: (value) {
                  setState(() => _notifications = value);
                  _saveSetting('notifications', value);
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.warning_amber,
                title: '食材过期提醒',
                subtitle: '食材即将过期时提醒',
                value: _expiryReminder,
                onChanged: (value) {
                  setState(() => _expiryReminder = value);
                  _saveSetting('expiryReminder', value);
                },
              ),
              if (_expiryReminder) ...[
                _buildDivider(),
                _buildSelectTile(
                  icon: Icons.schedule,
                  title: '提前提醒天数',
                  value: '$_reminderDays 天',
                  onTap: () => _showReminderDaysDialog(),
                ),
              ],
            ]),

            // 功能设置
            _buildSectionTitle('功能设置'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.shopping_cart,
                title: '自动添加到购物清单',
                subtitle: '做菜时自动将缺少的食材添加到购物清单',
                value: _autoAddShopping,
                onChanged: (value) {
                  setState(() => _autoAddShopping = value);
                  _saveSetting('autoAddShopping', value);
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.speed,
                title: '显示菜谱难度',
                subtitle: '在菜谱列表中显示难度标签',
                value: _showDifficulty,
                onChanged: (value) {
                  setState(() => _showDifficulty = value);
                  _saveSetting('showDifficulty', value);
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.timer,
                title: '显示烹饪时间',
                subtitle: '在菜谱列表中显示预计烹饪时间',
                value: _showCookingTime,
                onChanged: (value) {
                  setState(() => _showCookingTime = value);
                  _saveSetting('showCookingTime', value);
                },
              ),
            ]),

            // 数据管理
            _buildSectionTitle('数据管理'),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.cloud_upload,
                title: '备份数据',
                subtitle: '将数据备份到云端',
                onTap: () => _showBackupDialog(),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.cloud_download,
                title: '恢复数据',
                subtitle: '从云端恢复数据',
                onTap: () => _showRestoreDialog(),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.delete_outline,
                title: '清除缓存',
                subtitle: '清除本地缓存数据',
                onTap: () => _showClearCacheDialog(),
                isDestructive: false,
              ),
            ]),

            // 关于
            _buildSectionTitle('关于'),
            _buildSettingsCard([
              _buildInfoTile(
                icon: Icons.info_outline,
                title: '版本号',
                value: '1.0.0',
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.description,
                title: '用户协议',
                onTap: () => _showAgreementDialog('用户协议'),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.privacy_tip,
                title: '隐私政策',
                onTap: () => _showAgreementDialog('隐私政策'),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.feedback,
                title: '意见反馈',
                onTap: () => _showFeedbackDialog(),
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 构建分区标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  /// 构建设置卡片
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.small,
      ),
      child: Column(children: children),
    );
  }

  /// 构建分隔线
  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  /// 构建开关项
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// 构建选择项
  Widget _buildSelectTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作项
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive ? AppColors.errorLight : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? AppColors.error : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示提前提醒天数对话框
  void _showReminderDaysDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('提前提醒天数'),
        children: [1, 2, 3, 5, 7].map((days) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _reminderDays = days);
              _saveSetting('reminderDays', days);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('$days 天'),
                  const Spacer(),
                  if (_reminderDays == days)
                    Icon(Icons.check, color: AppColors.primary),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 显示备份对话框
  void _showBackupDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份功能开发中...')),
    );
  }

  /// 显示恢复对话框
  void _showRestoreDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('恢复功能开发中...')),
    );
  }

  /// 显示清除缓存对话框
  void _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除本地缓存数据吗？这不会影响您的账户数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存已清除')),
      );
    }
  }

  /// 显示协议对话框
  void _showAgreementDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            '这里是$title的内容...\n\n'
            '本应用尊重并保护所有使用服务用户的个人隐私权。\n\n'
            '为了给您提供更准确、更有个性化的服务，本应用会按照本隐私权政策的规定使用和披露您的个人信息。',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示反馈对话框
  void _showFeedbackDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('意见反馈'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '请输入您的意见或建议...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('感谢您的反馈！')),
              );
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }
}

