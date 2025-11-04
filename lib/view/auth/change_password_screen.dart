import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ValueNotifier<bool> _obscureCurrentPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _obscureNewPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _obscureConfirmPassword = ValueNotifier<bool>(true);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _obscureCurrentPassword.dispose();
    _obscureNewPassword.dispose();
    _obscureConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final utilsProvider = Provider.of<GeneralUtils>(context, listen: false);
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        GeneralUtils().showerrorflushbar(
          'Người dùng chưa đăng nhập',
          context,
        );
      }
      return;
    }

    if (user.email == null) {
      if (mounted) {
        GeneralUtils().showerrorflushbar(
          'Không tìm thấy email người dùng',
          context,
        );
      }
      return;
    }

    // Kiểm tra xem user có đăng nhập bằng email/password không
    final providers = user.providerData;
    final hasEmailPassword = providers.any((provider) => provider.providerId == 'password');
    
    if (!hasEmailPassword) {
      if (mounted) {
        GeneralUtils().showerrorflushbar(
          'Tài khoản này không hỗ trợ đổi mật khẩu. Chỉ tài khoản đăng nhập bằng email/mật khẩu mới có thể đổi mật khẩu.',
          context,
        );
      }
      return;
    }

    try {
      utilsProvider.showloading(true);

      // Re-authenticate user với mật khẩu hiện tại
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      debugPrint('Đang xác thực lại với email: ${user.email}');
      
      final userCredential = await user.reauthenticateWithCredential(credential);
      debugPrint('Xác thực lại thành công');

      // Update password
      debugPrint('Đang cập nhật mật khẩu mới...');
      await userCredential.user!.updatePassword(_newPasswordController.text.trim());
      debugPrint('Cập nhật mật khẩu thành công');

      utilsProvider.showloading(false);

      if (mounted) {
        GeneralUtils().showsuccessflushbar(
          'Đổi mật khẩu thành công!',
          context,
        );
        // Clear form
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        // Đợi một chút để user thấy thông báo thành công
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      utilsProvider.showloading(false);
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      
      String errorMessage = 'Đã xảy ra lỗi';
      
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Mật khẩu hiện tại không đúng. Vui lòng kiểm tra lại.';
          break;
        case 'user-mismatch':
          errorMessage = 'Thông tin người dùng không khớp. Vui lòng đăng nhập lại.';
          break;
        case 'user-not-found':
          errorMessage = 'Không tìm thấy tài khoản người dùng.';
          break;
        case 'invalid-credential':
          errorMessage = 'Thông tin đăng nhập không hợp lệ. Vui lòng kiểm tra lại mật khẩu hiện tại.';
          break;
        case 'weak-password':
          errorMessage = 'Mật khẩu mới quá yếu. Vui lòng sử dụng mật khẩu có ít nhất 6 ký tự và kết hợp chữ, số.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Vui lòng đăng nhập lại để thay đổi mật khẩu. Tính năng này yêu cầu xác thực gần đây.';
          break;
        case 'too-many-requests':
          errorMessage = 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
          break;
        case 'network-request-failed':
          errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
          break;
        default:
          errorMessage = e.message ?? 'Đã xảy ra lỗi: ${e.code}';
          debugPrint('Lỗi không xác định: ${e.code} - ${e.message}');
      }

      if (mounted) {
        GeneralUtils().showerrorflushbar(errorMessage, context);
      }
    } catch (e, stackTrace) {
      utilsProvider.showloading(false);
      debugPrint('Lỗi không mong muốn: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        GeneralUtils().showerrorflushbar(
          'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại sau.\nChi tiết: ${e.toString()}',
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff2B2B2B),
          ),
        ),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            fontFamily: 'Raleway-SemiBold',
            color: Color(0xff2B2B2B),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Current Password
                const Text(
                  'Mật khẩu hiện tại',
                  style: TextStyling.formtextstyle,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _obscureCurrentPassword,
                  builder: (context, obscure, _) {
                    return TextFormField(
                      controller: _currentPasswordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu hiện tại',
                        hintStyle: TextStyling.hinttext,
                        filled: true,
                        fillColor: const Color(0xffF7F7F9),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xff6A6A6A),
                          ),
                          onPressed: () {
                            _obscureCurrentPassword.value =
                                !_obscureCurrentPassword.value;
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu hiện tại';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // New Password
                const Text(
                  'Mật khẩu mới',
                  style: TextStyling.formtextstyle,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _obscureNewPassword,
                  builder: (context, obscure, _) {
                    return TextFormField(
                      controller: _newPasswordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu mới',
                        hintStyle: TextStyling.hinttext,
                        filled: true,
                        fillColor: const Color(0xffF7F7F9),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xff6A6A6A),
                          ),
                          onPressed: () {
                            _obscureNewPassword.value =
                                !_obscureNewPassword.value;
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu mới';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        if (value == _currentPasswordController.text.trim()) {
                          return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Confirm Password
                const Text(
                  'Xác nhận mật khẩu mới',
                  style: TextStyling.formtextstyle,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _obscureConfirmPassword,
                  builder: (context, obscure, _) {
                    return TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'Nhập lại mật khẩu mới',
                        hintStyle: TextStyling.hinttext,
                        filled: true,
                        fillColor: const Color(0xffF7F7F9),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xff6A6A6A),
                          ),
                          onPressed: () {
                            _obscureConfirmPassword.value =
                                !_obscureConfirmPassword.value;
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu mới';
                        }
                        if (value != _newPasswordController.text.trim()) {
                          return 'Mật khẩu xác nhận không khớp';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                Consumer<GeneralUtils>(
                  builder: (context, utilsProvider, child) {
                    return RoundButtonTwo(
                      loading: utilsProvider.load,
                      onpress: _changePassword,
                      title: 'Đổi mật khẩu',
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Security Tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffF7F7F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColor.backgroundColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColor.backgroundColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lưu ý bảo mật',
                              style: TextStyle(
                                fontFamily: 'Raleway-SemiBold',
                                fontSize: 14,
                                color: Color(0xff2B2B2B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mật khẩu phải có ít nhất 6 ký tự. Để bảo mật tốt hơn, hãy sử dụng kết hợp chữ hoa, chữ thường, số và ký tự đặc biệt.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
