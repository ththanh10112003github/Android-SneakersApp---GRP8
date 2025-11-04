import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:ecommerce_app/view/auth/change_password_screen.dart';
import 'package:ecommerce_app/view/home/update_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// Constants for spacing and sizing
class ProfileConstants {
  static const double avatarSize = 100.0;
  static const double avatarSizeWithImage = 105.0;
  static const double avatarBorderWidth = 3.0;
  static const double topPadding = 16.0;
  static const double horizontalPadding = 16.0;
  static const double fieldSpacing = 16.0;
  static const double labelSpacing = 8.0;
  static const double buttonPadding = 16.0;
  static const double bottomSpacing = 24.0;
}

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final db = FirebaseFirestore.instance.collection("User Data");
  final id = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final utilsProvider = Provider.of<GeneralUtils>(context, listen: false);
    
    return StreamBuilder<DocumentSnapshot>(
      stream: db.doc(id).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              leading: const SizedBox.shrink(),
              title: const Text(
                'Hồ sơ',
                style: TextStyle(
                  fontFamily: 'Raleway-SemiBold',
                  color: Color(0xff2B2B2B),
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColor.backgroundColor,
              ),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              leading: const SizedBox.shrink(),
              title: const Text(
                'Hồ sơ',
                style: TextStyle(
                  fontFamily: 'Raleway-SemiBold',
                  color: Color(0xff2B2B2B),
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đã xảy ra lỗi',
                    style: TextStyle(
                      fontFamily: 'Raleway-SemiBold',
                      fontSize: 18,
                      color: Color(0xff2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xff707B81),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.backgroundColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Success state
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              leading: const SizedBox.shrink(),
              title: const Text(
                'Hồ sơ',
                style: TextStyle(
                  fontFamily: 'Raleway-SemiBold',
                  color: Color(0xff2B2B2B),
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            body: const Center(
              child: Text(
                'Không tìm thấy thông tin người dùng',
                style: TextStyle(
                  fontFamily: 'Raleway-Medium',
                  fontSize: 16,
                  color: Color(0xff707B81),
                ),
              ),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final userName = userData['Full name'] ?? '';
        final userEmail = userData['Email'] ?? '';
        final userPhone = userData['phone'] ?? '';
        final userAddress = userData['address'] ?? '';
        final userImage = userData['image']?.toString() ?? '';

        return Scaffold(
          appBar: AppBar(
            leading: const SizedBox.shrink(),
            title: const Text(
              'Hồ sơ',
              style: TextStyle(
                fontFamily: 'Raleway-SemiBold',
                color: Color(0xff2B2B2B),
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xff2B2B2B),
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateProfileScreen(
                        name: userName,
                        email: userEmail,
                      ),
                    ),
                  );
                },
                tooltip: 'Chỉnh sửa thông tin',
              ),
              const SizedBox(width: 8),
            ],
          ),
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ProfileConstants.horizontalPadding,
              ),
              child: Column(
                children: [
                  SizedBox(height: ProfileConstants.topPadding),
                  // Avatar Section with edit option
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColor.backgroundColor,
                              width: ProfileConstants.avatarBorderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: userImage.isEmpty
                              ? Container(
                                  height: ProfileConstants.avatarSizeWithImage,
                                  width: ProfileConstants.avatarSizeWithImage,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xffF7F7F9),
                                  ),
                                  child: ClipOval(
                                    child: SvgPicture.asset(
                                      'images/default_profile.svg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: ProfileConstants.avatarSizeWithImage,
                                  width: ProfileConstants.avatarSizeWithImage,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      userImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColor.backgroundColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              await utilsProvider.getgalleryimage();
                              await utilsProvider.uploadimage();
                              await utilsProvider.uploadtoFirestore().onError(
                                (error, stackTrace) {
                                  if (mounted) {
                                    GeneralUtils().showerrorflushbar(
                                      'Không thể tải ảnh: ${error.toString()}',
                                      context,
                                    );
                                  }
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColor.backgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ProfileConstants.labelSpacing),
                  const Text(
                    'Nhấn để thay đổi ảnh đại diện',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xff707B81),
                    ),
                  ),
                  SizedBox(height: ProfileConstants.fieldSpacing * 2),

                  // Name Field
                  _buildFieldLabel('Tên của bạn'),
                  _buildReadOnlyField(
                    value: userName,
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: ProfileConstants.fieldSpacing),

                  // Email Field
                  _buildFieldLabel('Email'),
                  _buildReadOnlyField(
                    value: userEmail,
                    icon: Icons.email_outlined,
                  ),
                  SizedBox(height: ProfileConstants.fieldSpacing),

                  // Phone Field
                  _buildFieldLabel('Số điện thoại'),
                  _buildReadOnlyField(
                    value: userPhone.isEmpty ? 'Chưa cập nhật' : userPhone,
                    icon: Icons.phone_outlined,
                    isEmpty: userPhone.isEmpty,
                  ),
                  SizedBox(height: ProfileConstants.fieldSpacing),

                  // Address Field
                  _buildFieldLabel('Địa chỉ'),
                  _buildReadOnlyField(
                    value: userAddress.isEmpty ? 'Chưa cập nhật' : userAddress,
                    icon: Icons.location_on_outlined,
                    isEmpty: userAddress.isEmpty,
                  ),
                  SizedBox(height: ProfileConstants.fieldSpacing),

                  // Password Field
                  _buildFieldLabel('Bảo mật'),
                  _buildPasswordField(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: ProfileConstants.bottomSpacing),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: ProfileConstants.labelSpacing),
        child: Text(
          label,
          style: TextStyling.formtextstyle,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required IconData icon,
    bool isEmpty = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F9),
        borderRadius: BorderRadius.circular(12),
        border: isEmpty
            ? Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isEmpty
                ? Colors.orange.withOpacity(0.7)
                : const Color(0xff6A6A6A),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins-Medium',
                fontSize: 14,
                color: isEmpty
                    ? Colors.orange.withOpacity(0.8)
                    : const Color(0xff2B2B2B),
              ),
            ),
          ),
          Icon(
            Icons.lock_outline,
            size: 16,
            color: Colors.grey.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xffF7F7F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline,
              color: Color(0xff6A6A6A),
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mật khẩu',
                style: TextStyling.hinttext,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xff6A6A6A),
            ),
          ],
        ),
      ),
    );
  }
}
