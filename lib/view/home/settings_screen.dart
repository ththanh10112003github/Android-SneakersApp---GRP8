import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
    });
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() {
      _pushNotificationsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', value);
    
    if (mounted) {
      final utilsProvider = Provider.of<GeneralUtils>(context, listen: false);
      if (value) {
        GeneralUtils().showsuccessflushbar(
          'Thông báo đẩy đã được bật',
          context,
        );
      } else {
        GeneralUtils().showsuccessflushbar(
          'Thông báo đẩy đã được tắt',
          context,
        );
      }
    }
  }

  Future<void> _showAboutDialog() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Giới thiệu ứng dụng',
              style: TextStyle(
                fontFamily: 'Raleway-SemiBold',
                fontSize: 20,
                color: Color(0xff2B2B2B),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sneakers App',
                  style: TextStyle(
                    fontFamily: 'Raleway-Bold',
                    fontSize: 18,
                    color: Color(0xff2B2B2B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phiên bản: $version ($buildNumber)',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xff707B81),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ứng dụng mua sắm giày sneakers hàng đầu.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xff707B81),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Đóng',
                  style: TextStyle(
                    fontFamily: 'Raleway-Medium',
                    color: AppColor.backgroundColor,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _clearCache() async {
    if (mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Xóa cache',
              style: TextStyle(
                fontFamily: 'Raleway-SemiBold',
                fontSize: 20,
                color: Color(0xff2B2B2B),
              ),
            ),
            content: const Text(
              'Bạn có chắc chắn muốn xóa cache? Hành động này không thể hoàn tác.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xff707B81),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Hủy',
                  style: TextStyle(
                    fontFamily: 'Raleway-Medium',
                    color: Color(0xff707B81),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Xóa',
                  style: TextStyle(
                    fontFamily: 'Raleway-Medium',
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        setState(() {
          _isLoading = true;
        });

        try {
          final prefs = await SharedPreferences.getInstance();
          // Xóa các key không quan trọng, giữ lại settings và favorites
          // Có thể xóa các key cache khác nếu có
          await prefs.remove('cache_key'); // Thay bằng key thực tế nếu có
          
          // Có thể thêm các key khác để xóa
          // await prefs.remove('other_cache_key');
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            GeneralUtils().showsuccessflushbar(
              'Đã xóa cache thành công',
              context,
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            GeneralUtils().showerrorflushbar(
              'Không thể xóa cache: ${e.toString()}',
              context,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            fontFamily: 'Raleway-SemiBold',
            color: Color(0xff2B2B2B),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColor.backgroundColor,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông báo đẩy
                    _buildSectionTitle('Thông báo'),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Thông báo đẩy',
                      subtitle: 'Nhận thông báo về đơn hàng và khuyến mãi',
                      value: _pushNotificationsEnabled,
                      onChanged: _togglePushNotifications,
                      icon: Icons.notifications_outlined,
                    ),
                    const SizedBox(height: 24),

                    // Ứng dụng
                    _buildSectionTitle('Ứng dụng'),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      title: 'Giới thiệu ứng dụng',
                      subtitle: 'Phiên bản và thông tin ứng dụng',
                      icon: Icons.info_outline,
                      onTap: _showAboutDialog,
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      title: 'Xóa cache',
                      subtitle: 'Xóa dữ liệu tạm thời của ứng dụng',
                      icon: Icons.delete_outline,
                      onTap: _clearCache,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Raleway-SemiBold',
        fontSize: 16,
        color: Color(0xff2B2B2B),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xff6A6A6A),
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Raleway-Medium',
            fontSize: 16,
            color: Color(0xff2B2B2B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xff707B81),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColor.backgroundColor,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xff6A6A6A),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Raleway-Medium',
            fontSize: 16,
            color: isDestructive ? Colors.red : const Color(0xff2B2B2B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xff707B81),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xff6A6A6A),
        ),
        onTap: onTap,
      ),
    );
  }
}

