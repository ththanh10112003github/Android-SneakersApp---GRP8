import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailcontroller = TextEditingController();
  final passwordcontroller = TextEditingController();
  final ValueNotifier<bool> _obsecurepassword = ValueNotifier<bool>(true);

  final FirebaseAuth auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance.collection('User Data');

  @override
  Widget build(BuildContext context) {
    debugPrint('build');
    double screenheight = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: InkWell(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.pageViewScreen);
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
                  'Welcome Back!',
                  style: TextStyling.headingstyle,
                ),
              ),
            )),
            const Center(
              child: Text(
                'Chào mừng bạn trở lại, chúng tôi nhớ bạn lắm!',
                textAlign: TextAlign.center,
                style: TextStyling.subheading,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  top: screenheight * 0.08, left: screenwidth * 0.08),
              child: const Text(
                'Địa Email',
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
                  top: screenheight * 0.03, left: screenwidth * 0.08),
              child: const Text(
                'Mật Khẩu',
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
                builder: (context, value, child) {
                  return TextFormField(
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
                  );
                },
              ),
            ),
            Consumer<GeneralUtils>(
              builder: ((
                context,
                value1,
                child,
              ) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: screenheight * 0.038,
                    ),
                    child: RoundButtonTwo(
                      loading: value1.load,
                      onpress: () async {
                        if (emailcontroller.text == "admin@gmail.com" &&
                            passwordcontroller.text == "admin") {
                          Navigator.pushNamed(
                              context, RouteNames.adminHomeScreen);
                          return;
                        }
                        value1.showloading(true);
                        await auth
                            .signInWithEmailAndPassword(
                                email: emailcontroller.text.toString(),
                                password: passwordcontroller.text.toString())
                            .then((value) {
                          value1.showsuccessflushbar(
                            'Đăng nhập thành công',
                            context,
                          );

                          Navigator.pushNamed(context, RouteNames.navbarscreen);
                          value1.showloading(false);
                        }).onError((error, stackTrace) {
                          value1.showerrorflushbar(error.toString(), context);
                          value1.showloading(false);
                        });
                      },
                      title: 'Đăng Nhập',
                    ),
                  ),
                );
              }),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.forgotPasswordScreen);
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 27),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Quên mật khẩu',
                    style: TextStyling.formtextstyle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Bạn chưa có tài khoản?',
                    style: TextStyle(
                      fontFamily: 'Raleway-Medium',
                      fontSize: 13,
                      color: Color(
                        0xff6A6A6A,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.signUpScreen);
                    },
                    child: const Text(
                      'Đăng ký miễn phí',
                      style: TextStyle(
                        fontFamily: 'Raleway-Medium',
                        fontSize: 13,
                        color: Color(
                          0xff1A1D1E,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}