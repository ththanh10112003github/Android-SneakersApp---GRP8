import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailcontroller = TextEditingController();
  final namecontroller = TextEditingController();
  final passwordcontroller = TextEditingController();
  final phonecontroller = TextEditingController();
  final addresscontroller = TextEditingController();
  final ValueNotifier<bool> _obsecurepassword = ValueNotifier<bool>(true);

  FirebaseAuth authenticate = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance.collection('User Data');

  @override
  Widget build(BuildContext context) {
    //  final utilsProvider = Provider.of<GeneralUtils>(context);
    double screenheight = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: InkWell(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.loginScreen);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Padding(
                padding: EdgeInsets.only(top: screenheight * .02),
                child: const Text(
                  'Tạo Tài Khoản',
                  style: TextStyling.headingstyle,
                ),
              ),
            )),
            const Center(
              child: Text(
                'Hãy cùng nhau tạo tài khoản',
                style: TextStyling.subheading,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: screenheight * 0.08,
                left: screenwidth * 0.08,
              ),
              child: const Text(
                'Tên của bạn',
                style: TextStyling.formtextstyle,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: screenwidth * 0.04,
                right: screenwidth * 0.04,
                top: screenheight * 0.01,
              ),
              child: TextFormField(
                controller: namecontroller,
                decoration: InputDecoration(
                  hintText: 'Nhập Họ Tên',
                  hintStyle: TextStyling.hinttext,
                  filled: true,
                  fillColor: const Color(0xffF7F7F9),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: screenheight * 0.03,
                left: screenwidth * 0.08,
              ),
              child: const Text(
                'Địa chỉ Email',
                style: TextStyling.formtextstyle,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: screenwidth * 0.04,
                right: screenwidth * 0.04,
                top: screenheight * 0.01,
              ),
              child: TextFormField(
                controller: emailcontroller,
                decoration: InputDecoration(
                  hintText: 'xyz@gmail.com',
                  hintStyle: TextStyling.hinttext,
                  filled: true,
                  fillColor: const Color(0xffF7F7F9),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: screenheight * 0.03,
                left: screenwidth * 0.08,
              ),
              child: const Text(
                'Số điện thoại',
                style: TextStyling.formtextstyle,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: screenwidth * 0.04,
                right: screenwidth * 0.04,
                top: screenheight * 0.01,
              ),
              child: TextFormField(
                controller: phonecontroller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại',
                  hintStyle: TextStyling.hinttext,
                  filled: true,
                  fillColor: const Color(0xffF7F7F9),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: screenheight * 0.03,
                left: screenwidth * 0.08,
              ),
              child: const Text(
                'Địa chỉ',
                style: TextStyling.formtextstyle,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: screenwidth * 0.04,
                right: screenwidth * 0.04,
                top: screenheight * 0.01,
              ),
              child: TextFormField(
                controller: addresscontroller,
                decoration: InputDecoration(
                  hintText: 'Nhập địa chỉ',
                  hintStyle: TextStyling.hinttext,
                  filled: true,
                  fillColor: const Color(0xffF7F7F9),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  top: screenheight * 0.03, left: screenwidth * 0.08),
              child: const Text(
                'Mật khẩu',
                style: TextStyling.formtextstyle,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: screenwidth * 0.04,
                right: screenwidth * 0.04,
                top: screenheight * 0.01,
              ),
              child: ValueListenableBuilder(
                valueListenable: _obsecurepassword,
                builder: (context, value, child) => TextFormField(
                  obscureText: _obsecurepassword.value,
                  controller: passwordcontroller,
                  decoration: InputDecoration(
                    suffixIcon: InkWell(
                      onTap: () {
                        _obsecurepassword.value = !_obsecurepassword.value;
                      },
                      child: _obsecurepassword.value
                          ? const Icon(Icons.visibility_off_sharp)
                          : const Icon(Icons.visibility),
                    ),
                    hintText: 'Nhập mật khẩu',
                    hintStyle: TextStyling.hinttext,
                    filled: true,
                    fillColor: const Color(0xffF7F7F9),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                child: TextFormField(
                  controller: passwordcontroller,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu',
                    hintStyle: TextStyling.hinttext,
                    filled: true,
                    fillColor: const Color(0xffF7F7F9),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ),
            Consumer<GeneralUtils>(
              builder: ((context, value1, child) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: screenheight * 0.03,
                      left: 16,
                      right: 16,
                    ),
                    child: RoundButtonTwo(
                      loading: value1.load,
                      onpress: () async {
                        value1.showloading(true);
                        await authenticate
                            .createUserWithEmailAndPassword(
                                email: emailcontroller.text.toString(),
                                password: passwordcontroller.text.toString())
                            .then((value) {
                          final userid =
                              authenticate.currentUser!.uid.toString();
                          db.doc(userid).set({
                            'id': userid,
                            'Full name': namecontroller.text.toString(),
                            'Email': emailcontroller.text.toString(),
                            'phone': phonecontroller.text.toString(),
                            'address': addresscontroller.text.toString(),
                            'image': '',
                          });
                          value1.showloading(false);

                          value1.showsuccessflushbar(
                              'Đăng ký thành công!', context);
                          Navigator.pushNamed(context, RouteNames.loginScreen);
                        }).onError((error, stackTrace) {
                          value1.showloading(false);

                          value1.showerrorflushbar(error.toString(), context);
                        });
                      },
                      title: 'Đăng Ký',
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
