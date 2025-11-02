import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/view/admin/admin_order_page.dart';
import 'package:ecommerce_app/view/admin/admin_product_page.dart';
import 'package:ecommerce_app/view/admin/admin_user_page.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final screens = const [
    AdminProductScreen(),
    AdminOrderListScreen(),
    AdminUserListScreen(),
  ];
  int itemindex = 0;

  @override
  Widget build(BuildContext context) {
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
            Icon(
              Icons.toys,
              color: itemindex == 0 ? Colors.white : null,
            ),
            Icon(
              Icons.list_alt_outlined,
              color: itemindex == 1 ? Colors.white : null,
            ),
            Icon(
              Icons.person,
              color: itemindex == 2 ? Colors.white : null,
            )
          ],
        ),
      ),
    );
  }
}
