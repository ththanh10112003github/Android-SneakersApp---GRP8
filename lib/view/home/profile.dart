import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/view/home/update_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    double screenheight = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;
    return StreamBuilder(
      stream: db.doc(id).snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        dynamic userData = snapshot.data?.data();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
            color: AppColor.backgroundColor,
          ));
        } else if (snapshot.hasError) {
          const Center(
            child: Text("Error Occured"),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: SizedBox.shrink(),
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
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: screenheight * 0.05),
                  child: Column(
                    children: [
                      userData!['image'].toString().isEmpty
                          ? Container(
                              height: 100,
                              width: 100,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(
                                  'images/profile.png',
                                )),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Colors.grey,
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              height: 105,
                              width: 105,
                              child: ClipOval(
                                child: Image.network(
                                  userData!['image'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: screenheight * 0.02,
                              left: screenwidth * 0.05),
                          child: const Text(
                            'Tên của bạn',
                            style: TextStyling.formtextstyle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenwidth * 0.04,
                            right: screenwidth * 0.04,
                            top: screenheight * 0.01),
                        child: TextFormField(
                          readOnly: true,
                          initialValue: userData['Full name'],
                          decoration: InputDecoration(
                            labelStyle: TextStyling.hinttext,
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            filled: true,
                            fillColor: const Color(0xffF7F7F9),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: screenheight * 0.02,
                              left: screenwidth * 0.05),
                          child: const Text(
                            'Email',
                            style: TextStyling.formtextstyle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenwidth * 0.04,
                            right: screenwidth * 0.04,
                            top: screenheight * 0.01),
                        child: TextFormField(
                          initialValue: userData['Email'],
                          readOnly: true,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            labelStyle: TextStyling.hinttext,
                            filled: true,
                            fillColor: const Color(0xffF7F7F9),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: screenheight * 0.02,
                              left: screenwidth * 0.05),
                          child: const Text(
                            'Số điện thoại',
                            style: TextStyling.formtextstyle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenwidth * 0.04,
                            right: screenwidth * 0.04,
                            top: screenheight * 0.01),
                        child: TextFormField(
                          initialValue: userData['phone'] ?? '',
                          readOnly: true,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            labelStyle: TextStyling.hinttext,
                            filled: true,
                            fillColor: const Color(0xffF7F7F9),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: screenheight * 0.02,
                              left: screenwidth * 0.05),
                          child: const Text(
                            'Địa chỉ',
                            style: TextStyling.formtextstyle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenwidth * 0.04,
                            right: screenwidth * 0.04,
                            top: screenheight * 0.01),
                        child: TextFormField(
                          initialValue: userData['address'] ?? '',
                          readOnly: true,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            labelStyle: TextStyling.hinttext,
                            filled: true,
                            fillColor: const Color(0xffF7F7F9),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: screenheight * 0.02,
                              left: screenwidth * 0.05),
                          child: const Text(
                            'Mật khẩu',
                            style: TextStyling.formtextstyle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenwidth * 0.04,
                            right: screenwidth * 0.04,
                            top: screenheight * 0.01),
                        child: TextFormField(
                          enabled: false,
                          decoration: InputDecoration(
                            label: const Text('*********'),
                            labelStyle: TextStyling.hinttext,
                            filled: true,
                            fillColor: const Color(0xffF7F7F9),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: RoundButtonTwo(
                          onpress: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateProfileScreen(
                                    name: userData['Full name'],
                                    email: userData['Email'],
                                  ),
                                ));
                          },
                          title: 'Cập nhật',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
