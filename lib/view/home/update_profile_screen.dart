import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/address_picker.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:ecommerce_app/view/auth/change_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// Constants for spacing and sizing
class UpdateProfileConstants {
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

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({
    super.key,
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController emailcontroller;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  final db = FirebaseFirestore.instance.collection("User Data");
  final id = FirebaseAuth.instance.currentUser!.uid;
  
  String? _userImage;
  bool _isLoading = true;
  FullAddress? _currentAddress;

  @override
  void initState() {
    super.initState();
    emailcontroller = TextEditingController(text: widget.email);
    nameController = TextEditingController(text: widget.name);
    phoneController = TextEditingController();
    
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final doc = await db.doc(id).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          phoneController.text = data['phone'] ?? '';
          _userImage = data['image']?.toString();
          
          // Load structured address nếu có, nếu không thì load từ address string cũ
          if (data['provinceCode'] != null || data['provinceName'] != null) {
            _currentAddress = FullAddress.fromMap(data);
          } else if (data['address'] != null && data['address'].toString().isNotEmpty) {
            // Backward compatibility: convert old string address to FullAddress
            _currentAddress = FullAddress.fromString(data['address'].toString());
          } else {
            _currentAddress = FullAddress();
          }
          
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _currentAddress = FullAddress();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    emailcontroller.dispose();
    nameController.dispose();
    phoneController.dispose();
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: UpdateProfileConstants.labelSpacing),
        child: Text(
          label,
          style: TextStyling.formtextstyle,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: 'Poppins-Medium',
          fontSize: 14,
          color: enabled ? const Color(0xff2B2B2B) : const Color(0xff707B81),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyling.hinttext,
          prefixIcon: Icon(
            icon,
            color: const Color(0xff6A6A6A),
            size: 20,
          ),
          suffixIcon: enabled
              ? null
              : const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Color(0xff6A6A6A),
                ),
          filled: true,
          fillColor: const Color(0xffF7F7F9),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColor.backgroundColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
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
            Expanded(
              child: Text(
                'Nhấn để đổi mật khẩu',
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

  @override
  Widget build(BuildContext context) {
    final utilsProvider = Provider.of<GeneralUtils>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
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
      drawer: null,
      endDrawer: null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColor.backgroundColor,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UpdateProfileConstants.horizontalPadding,
                ),
                child: Column(
                  children: [
                  // StreamBuilder chỉ dùng cho avatar để cập nhật khi upload ảnh
                  StreamBuilder<DocumentSnapshot>(
                    stream: db.doc(id).snapshots(),
                    builder: (context, snapshot) {
                      String? currentImage;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        currentImage = data['image']?.toString();
                      } else {
                        currentImage = _userImage;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: UpdateProfileConstants.topPadding * 2,
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColor.backgroundColor,
                                        width: UpdateProfileConstants.avatarBorderWidth,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: (currentImage == null || currentImage.isEmpty)
                                        ? Container(
                                            height: UpdateProfileConstants.avatarSizeWithImage,
                                            width: UpdateProfileConstants.avatarSizeWithImage,
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
                                            height: UpdateProfileConstants.avatarSizeWithImage,
                                            width: UpdateProfileConstants.avatarSizeWithImage,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                            ),
                                            child: ClipOval(
                                              child: Image.network(
                                                currentImage,
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
                                                debugPrint(error.toString());
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
                            const SizedBox(height: UpdateProfileConstants.labelSpacing),
                            const Text(
                              'Nhấn vào icon camera để thay đổi ảnh',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xff707B81),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: UpdateProfileConstants.fieldSpacing * 2),
                  // Form Fields
                  _buildFieldLabel('Tên của bạn'),
                  _buildFormField(
                    controller: nameController,
                    icon: Icons.person_outline,
                    hintText: 'Nhập tên của bạn',
                  ),
                  SizedBox(height: UpdateProfileConstants.fieldSpacing),
                  _buildFieldLabel('Email'),
                  _buildFormField(
                    controller: emailcontroller,
                    icon: Icons.email_outlined,
                    hintText: 'Nhập email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: UpdateProfileConstants.fieldSpacing),
                  _buildFieldLabel('Số điện thoại'),
                  _buildFormField(
                    controller: phoneController,
                    icon: Icons.phone_outlined,
                    hintText: 'Nhập số điện thoại',
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: UpdateProfileConstants.fieldSpacing),
                  _buildFieldLabel('Địa chỉ'),
                  AddressPicker(
                    initialAddress: _currentAddress,
                    onAddressChanged: (address) {
                      setState(() {
                        _currentAddress = address;
                      });
                    },
                    detailAddressHint: 'Số nhà, tên đường...',
                  ),
                  SizedBox(height: UpdateProfileConstants.fieldSpacing),
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
                  SizedBox(height: UpdateProfileConstants.fieldSpacing),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UpdateProfileConstants.buttonPadding,
                      vertical: UpdateProfileConstants.buttonPadding,
                    ),
                    child: RoundButtonTwo(
                      loading: utilsProvider.load,
                      onpress: () {
                        if (emailcontroller.text.isNotEmpty &&
                            nameController.text.isNotEmpty) {
                          utilsProvider.showloading(true);

                          // Prepare update data
                          final updateData = <String, dynamic>{
                            'Email': emailcontroller.text.toString(),
                            'Full name': nameController.text.toString(),
                            'phone': phoneController.text.toString(),
                          };

                          // Add structured address if available
                          if (_currentAddress != null) {
                            final addressMap = _currentAddress!.toMap();
                            updateData.addAll(addressMap);
                            // Also keep backward compatibility with 'address' field
                            updateData['address'] = _currentAddress!.fullAddressString;
                          }

                          db.doc(id).update(updateData).then((value) {
                            utilsProvider.showloading(false);
                            if (mounted && Navigator.canPop(context)) {
                              GeneralUtils()
                                  .showsuccessflushbar('Profile Updated!', context);
                              // Đợi một chút để flushbar hiển thị rồi mới pop
                              Future.delayed(const Duration(milliseconds: 1500), () {
                                if (mounted && Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              });
                            }
                          }).catchError((error) {
                            utilsProvider.showloading(false);
                            if (mounted) {
                              GeneralUtils()
                                  .showerrorflushbar('Lỗi cập nhật: $error', context);
                            }
                          });
                        }
                      },
                      title: 'Xác Nhận',
                    ),
                  ),
                  SizedBox(height: UpdateProfileConstants.bottomSpacing),
                  ],
                ),
              ),
            ),
    );
  }
}
