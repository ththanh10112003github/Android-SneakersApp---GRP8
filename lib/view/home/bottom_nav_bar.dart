import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/fav_provider.dart';
import 'package:ecommerce_app/view/home/cart_screen.dart';
import 'package:ecommerce_app/view/home/favourites_screen.dart';
import 'package:ecommerce_app/view/home/home_screen.dart';
import 'package:ecommerce_app/view/home/notification_screen.dart';
import 'package:ecommerce_app/view/home/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  const BottomNavigationBarScreen({super.key});

  @override
  State<BottomNavigationBarScreen> createState() =>
      _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  final screens = const [
    HomeScreen(),
    FavouriteScreen(),
    CartScreen(),
    NotificationScreen(),
    UserProfile()
  ];
  final auth = FirebaseAuth.instance;
  int itemindex = 0;
  final id = FirebaseAuth.instance.currentUser!.uid;
  final db = FirebaseFirestore.instance.collection("User Data");
  final db2 = FirebaseFirestore.instance.collection("Favourites");

  @override
  Widget build(BuildContext context) {
    final screenheight = MediaQuery.of(context).size.height;
    final favprovider = Provider.of<FavouriteProvider>(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: screens[itemindex],
        backgroundColor: const Color(0xffF7F7F9),
        bottomNavigationBar: CurvedNavigationBar(
          animationDuration: const Duration(milliseconds: 300),
          onTap: (index) {
            setState(() {
              itemindex = index;
            });
          },
          color: const Color(0xffFFFFFF),
          index: itemindex,
          buttonBackgroundColor: AppColor.backgroundColor,
          backgroundColor: const Color(0xffF7F7F9),
          items: [
            SvgPicture.asset(
                'images/home.svg',
                colorFilter: ColorFilter.mode(
                  itemindex == 0 ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            SvgPicture.asset(
                'images/heart.svg',
                colorFilter: ColorFilter.mode(
                  itemindex == 1 ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            SvgPicture.asset(
                'images/cart.svg',
                colorFilter: ColorFilter.mode(
                  itemindex == 2 ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            SvgPicture.asset(
                'images/notification.svg',
                colorFilter: ColorFilter.mode(
                  itemindex == 3 ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            SvgPicture.asset(
                'images/profile.svg',
                colorFilter: ColorFilter.mode(
                  itemindex == 4 ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
          ],
        ),
        drawer: SizedBox(
          height: screenheight,
          child: Drawer(
            // key: scaffoldKey,
            backgroundColor: const Color(0xff0D6EFD),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: ListView(
                children: [
                  SizedBox(
                    height: screenheight * 0.07,
                  ),
                  StreamBuilder(
                      stream: db.doc(id).snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        dynamic userData = snapshot.data?.data();

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                            color: Colors.purple,
                          ));
                        } else if (snapshot.hasError) {
                          const Center(
                            child: Text("Error Occured"),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              userData['image'] == null || userData['image'].toString().isEmpty
                                  ? CircleAvatar(
                                      radius: 96,
                                      backgroundColor: Colors.transparent,
                                      child: ClipOval(
                                        child: SvgPicture.asset(
                                          'images/default_profile.svg',
                                          fit: BoxFit.cover,
                                          width: 192,
                                          height: 192,
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(userData['image']),
                                      radius: 96,
                                    ),
                              const SizedBox(
                                height: 20,
                              ),
                              userData['Full name'] == null
                                  ? Container()
                                  : Text(
                                      userData['Full name'].toString(),
                                      style: const TextStyle(
                                          fontFamily: 'Raleway-Medium',
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )
                            ],
                          ),
                        );
                      }),

                  const SizedBox(
                    height: 20,
                  ),
                  ListTile(
                    textColor: const Color(0xffFFFFFF),
                    leading: SvgPicture.asset(
                      'images/profile.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xffFFFFFF),
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.profilescreen);
                    },
                  ),
                  //1
                  ListTile(
                    textColor: const Color(0xffFFFFFF),
                    leading: SvgPicture.asset(
                      'images/cart.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xffFFFFFF),
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                    title: const Text('My Cart'),
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.cartscreen);
                    },
                  ),
                  //2
                  ListTile(
                    textColor: const Color(0xffFFFFFF),
                    leading: SvgPicture.asset(
                      'images/heart.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xffFFFFFF),
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                    title: const Text('Favourites'),
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.favcreen);
                    },
                  ),
                  //3
                  ListTile(
                    textColor: const Color(0xffFFFFFF),
                    leading: const Image(
                      image: AssetImage(
                        'images/orders.png',
                      ),
                      color: Color(0xffFFFFFF),
                    ),
                    title: const Text('Orders'),
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.orderSreen);
                    },
                  ),
                  //4
                  ListTile(
                    textColor: const Color(0xffFFFFFF),
                    leading: SvgPicture.asset(
                      'images/notification.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xffFFFFFF),
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                    title: const Text('Notifications'),
                    onTap: () {
                      Navigator.pushNamed(
                          context, RouteNames.notificationscreen);
                    },
                  ),
                  ListTile(
                    textColor: const Color(0xffFFFFFF),
                    leading: Icon(
                      Icons.chat_outlined,
                      color: Color(0xffFFFFFF),
                    ),
                    title: const Text('ChatBot'),
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.chatBoxSreen);
                    },
                  ),
                  //5
                  ListTile(
                    textColor: const Color(0xffFFFFFF),
                    leading: SvgPicture.asset(
                      'images/settings.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xffFFFFFF),
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                    title: const Text(
                      'Settings',
                    ),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    textColor: const Color(0xffFFFFFF),
                    leading: const Image(
                      image: AssetImage(
                        'images/signout.png',
                      ),
                      color: Color(0xffFFFFFF),
                    ),
                    title: const Text(
                      'Sign Out',
                    ),
                    onTap: () async {
                      await favprovider.deleteItems();
                      auth.signOut().then((value) {
                        if (context.mounted) {
                          Navigator.pushNamed(
                              context, RouteNames.pageViewScreen);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
