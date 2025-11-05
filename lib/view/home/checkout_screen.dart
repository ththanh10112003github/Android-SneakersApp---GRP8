import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/address_picker.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';
import 'package:provider/provider.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final auth = FirebaseAuth.instance;
  var userdata;
  var name = '';
  var phone = '';
  var email = '';
  String address = '';
  FullAddress? _currentAddress;
  PersistentShoppingCart cart = PersistentShoppingCart();
  
  List<PersistentShoppingCartItem>? _selectedItems;
  double _selectedTotalPrice = 0.0;

  final db = FirebaseFirestore.instance.collection('User Data');
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController phonecontroller = TextEditingController();
  final TextEditingController emailcontroller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is List<PersistentShoppingCartItem>) {
        setState(() {
          _selectedItems = args;
          _selectedTotalPrice = _calculateSelectedTotal(args);
        });
      }
    });
    fetchdata();
  }
  
  double _calculateSelectedTotal(List<PersistentShoppingCartItem> items) {
    double total = 0.0;
    for (var item in items) {
      total += item.unitPrice * item.quantity;
    }
    return total;
  }

  Future fetchdata() async {
    try {
      DocumentSnapshot db2 = await db.doc(auth.currentUser!.uid).get();
      userdata = db2.data();
      setState(() {
        name = userdata['Full name'] ?? '';
        email = userdata['Email'];
        phone = userdata['phone'] ?? '';
      });
      
      if (userdata['provinceCode'] != null || userdata['provinceName'] != null) {
        _currentAddress = FullAddress.fromMap(userdata);
        address = _currentAddress!.fullAddressString;
      } else if (userdata['address'] != null && userdata['address'].toString().isNotEmpty) {
        address = userdata['address'].toString();
        _currentAddress = FullAddress.fromString(address);
      } else {
        address = '';
        _currentAddress = FullAddress();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenwidth = MediaQuery.of(context).size.width;
    double screenheight = MediaQuery.of(context).size.height;
    final utils = Provider.of<GeneralUtils>(context);

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f9),
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.cartscreen);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
        backgroundColor: const Color(0xfff7f7f9),
        title: const Text('Thanh toán'),
        centerTitle: true,
        titleTextStyle: TextStyling.apptitle,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 17, right: 17, top: 25),
          child: Container(
            height: screenheight * 0.9,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Thông tin liên hệ',
                    style: TextStyle(
                      color: Color(0xff1A2530),
                      fontFamily: 'Raleway-Medium',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      const Icon(
                        Icons.person_outline,
                        size: 24,
                        color: Color(0xff707BB1),
                      ),
                      const SizedBox(
                        width: 17,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Chưa cập nhật' : name,
                              style: const TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1A2530),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              'Tên người nhận',
                              style: TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 12,
                                color: Color(0xff707BB1),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(width: screenwidth * 0.01),
                      IconButton(
                          onPressed: () {
                            namecontroller.text = name;
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    // ignore: sized_box_for_whitespace
                                    content: Container(
                                        height: 196,
                                        width: 335,
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Nhập tên người nhận',
                                              style: TextStyle(
                                                fontFamily: 'Raleway-Bold',
                                                fontSize: 16,
                                                color: Color(
                                                  0xff2B2B2B,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            TextFormField(
                                              controller: namecontroller,
                                              decoration: InputDecoration(
                                                  hintText: 'Nhập tên người nhận',
                                                  hintStyle:
                                                      TextStyling.hinttext,
                                                  filled: true,
                                                  fillColor:
                                                      const Color(0xffF7F7F9),
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12))),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                utils.showloading(true);
                                                db
                                                    .doc(auth.currentUser!.uid)
                                                    .update({
                                                  'Full name': namecontroller.text
                                                      .toString()
                                                }).then((value) {
                                                  utils.showloading(false);
                                                  GeneralUtils()
                                                      .showsuccessflushbar(
                                                          'Tên đã được cập nhật',
                                                          context);
                                                  fetchdata();
                                                }).onError((error, stackTrace) {
                                                  utils.showloading(false);
                                                  GeneralUtils()
                                                      .showerrorflushbar(
                                                          error.toString(),
                                                          context);
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                height: 40,
                                                width: 130,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: AppColor
                                                        .backgroundColor),
                                                child: utils.load
                                                    ? const Center(
                                                        child:
                                                            CircularProgressIndicator())
                                                    : const Center(
                                                        child: Text(
                                                          'Xác nhận',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'Raleway-Bold',
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ),
                                              ),
                                            )
                                          ],
                                        )),
                                  );
                                });
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xff707BB1),
                            size: 20,
                          ))
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      SvgPicture.asset(
                        'images/email.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xff707BB1),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(
                        width: 17,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: const TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1A2530),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 12,
                                color: Color(0xff707BB1),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(width: screenwidth * 0.01),
                      IconButton(
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    // ignore: sized_box_for_whitespace
                                    content: Container(
                                        height: 196,
                                        width: 335,
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Nhập địa chỉ email',
                                              style: TextStyle(
                                                fontFamily: 'Raleway-Bold',
                                                fontSize: 16,
                                                color: Color(
                                                  0xff2B2B2B,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            TextFormField(
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              controller: emailcontroller,
                                              decoration: InputDecoration(
                                                  hintText: 'Nhập địa chỉ email của bạn',
                                                  hintStyle:
                                                      TextStyling.hinttext,
                                                  filled: true,
                                                  fillColor:
                                                      const Color(0xffF7F7F9),
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12))),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                utils.showloading(true);
                                                db
                                                    .doc(auth.currentUser!.uid)
                                                    .update({
                                                  'Email': emailcontroller.text
                                                      .toString()
                                                }).then((value) {
                                                  utils.showloading(false);
                                                  GeneralUtils()
                                                      .showsuccessflushbar(
                                                          'Email đã được cập nhật',
                                                          context);
                                                  fetchdata();
                                                }).onError((error, stackTrace) {
                                                  utils.showloading(false);
                                                  GeneralUtils()
                                                      .showerrorflushbar(
                                                          error.toString(),
                                                          context);
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                height: 40,
                                                width: 130,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: AppColor
                                                        .backgroundColor),
                                                child: utils.load
                                                    ? const Center(
                                                        child:
                                                            CircularProgressIndicator())
                                                    : const Center(
                                                        child: Text(
                                                          'Xác nhận',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'Raleway-Bold',
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ),
                                              ),
                                            )
                                          ],
                                        )),
                                  );
                                });
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xff707BB1),
                            size: 20,
                          ))
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      const Icon(
                        Icons.phone_outlined,
                        size: 24,
                        color: Color(0xff707BB1),
                      ),
                      const SizedBox(
                        width: 17,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phone,
                              style: const TextStyle(
                                  fontFamily: 'Poppins-Medium',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff1A2530)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              'Số điện thoại',
                              style: TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 12,
                                color: Color(0xff707BB1),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(width: screenwidth * 0.14),
                      IconButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  // ignore: sized_box_for_whitespace
                                  content: Container(
                                      height: 196,
                                      width: 335,
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Nhập số điện thoại',
                                            style: TextStyle(
                                              fontFamily: 'Raleway-Bold',
                                              fontSize: 16,
                                              color: Color(
                                                0xff2B2B2B,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          TextFormField(
                                            keyboardType: TextInputType.phone,
                                            controller: phonecontroller,
                                            decoration: InputDecoration(
                                              hintText: 'Nhận số điện thoại',
                                              hintStyle: TextStyling.hinttext,
                                              filled: true,
                                              fillColor:
                                                  const Color(0xffF7F7F9),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              db
                                                  .doc(auth.currentUser!.uid)
                                                  .update({
                                                'phone': phonecontroller.text
                                                    .toString()
                                              }).then((value) {
                                                GeneralUtils()
                                                    .showsuccessflushbar(
                                                        'Số điện thoại đã được cập nhật',
                                                        context);
                                                fetchdata();
                                              }).onError((error, stackTrace) {
                                                GeneralUtils()
                                                    .showerrorflushbar(
                                                        error.toString(),
                                                        context);
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              height: 40,
                                              width: 130,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color:
                                                      AppColor.backgroundColor),
                                              child: const Center(
                                                child: Text(
                                                  'Xác nhận',
                                                  style: TextStyle(
                                                      fontFamily:
                                                          'Raleway-Bold',
                                                      fontSize: 12,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )),
                                );
                              });
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xff707BB1),
                          size: 20,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 24,
                        color: Color(0xff707BB1),
                      ),
                      const SizedBox(
                        width: 17,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address,
                              style: const TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1A2530),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              'Địa chỉ',
                              style: TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 12,
                                color: Color(0xff707BB1),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(width: screenwidth * 0.14),
                      IconButton(
                        onPressed: () {
                          FullAddress? tempAddress = _currentAddress;
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return AlertDialog(
                                      title: const Text(
                                        'Chỉnh sửa địa chỉ',
                                        style: TextStyle(
                                          fontFamily: 'Raleway-Bold',
                                          fontSize: 18,
                                          color: Color(0xff2B2B2B),
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: SingleChildScrollView(
                                          child: AddressPicker(
                                            initialAddress: tempAddress,
                                            onAddressChanged: (address) {
                                              setDialogState(() {
                                                tempAddress = address;
                                              });
                                            },
                                            detailAddressHint: 'Số nhà, tên đường...',
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Hủy',
                                            style: TextStyle(
                                              fontFamily: 'Poppins-Medium',
                                              fontSize: 14,
                                              color: Color(0xff707B81),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (tempAddress != null) {
                                              utils.showloading(true);
                                              
                                              final updateData = <String, dynamic>{};
                                              final addressMap = tempAddress!.toMap();
                                              updateData.addAll(addressMap);
                                              updateData['address'] = tempAddress!.fullAddressString;
                                              
                                              db
                                                  .doc(auth.currentUser!.uid)
                                                  .update(updateData)
                                                  .then((value) {
                                                utils.showloading(false);
                                                GeneralUtils()
                                                    .showsuccessflushbar(
                                                        'Địa chỉ đã được cập nhật',
                                                        context);
                                                fetchdata();
                                              }).onError((error, stackTrace) {
                                                utils.showloading(false);
                                                GeneralUtils()
                                                    .showerrorflushbar(
                                                        error.toString(),
                                                        context);
                                              });
                                              Navigator.pop(context);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColor.backgroundColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: utils.load
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Xác nhận',
                                                  style: TextStyle(
                                                    fontFamily: 'Raleway-Bold',
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              });
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xff707BB1),
                          size: 20,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      const Icon(
                        Icons.payment_outlined,
                        size: 24,
                        color: Color(0xff707BB1),
                      ),
                      const SizedBox(
                        width: 17,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Phương thức thanh toán",
                            style: const TextStyle(
                              fontFamily: 'Poppins-Medium',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1A2530),
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          const Text(
                            'Thanh toán khi nhận hàng',
                            style: TextStyle(
                              fontFamily: 'Poppins-Medium',
                              fontSize: 12,
                              color: Color(0xff707BB1),
                            ),
                          )
                          ],
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Builder(
                    builder: (context) {
                      final displayTotal = _selectedItems != null 
                          ? _selectedTotalPrice 
                          : cart.calculateTotalPrice();
                      final displayCount = _selectedItems?.length ?? 
                          (cart.getCartData()['cartItems'] as List? ?? []).length;
                      
                      return Visibility(
                        visible: displayTotal > 0.0,
                        child: Container(
                          height: _selectedItems != null ? 280 : 250,
                          width: double.infinity,
                          color: Colors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedItems != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 15,
                                    right: 15,
                                    top: 15,
                                    bottom: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_checkout,
                                          color: AppColor.backgroundColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Đang thanh toán $displayCount sản phẩm đã chọn',
                                          style: TextStyle(
                                            fontFamily: 'Poppins-Medium',
                                            fontSize: 12,
                                            color: AppColor.backgroundColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Thành tiền',
                                          style: TextStyle(
                                            fontFamily: 'Raleway-SemiBold',
                                            color: Color(0xff707B81),
                                            fontSize: 16,
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          Formatter.formatCurrency(displayTotal.toInt()),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins-Medium',
                                            color: Color(0xff1A2530),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Giảm giá',
                                          style: TextStyle(
                                            fontFamily: 'Raleway-SemiBold',
                                            color: Color(0xff707B81),
                                            fontSize: 16,
                                          ),
                                        ),
                                        Spacer(),
                                        const Text(
                                          '0',
                                          style: TextStyle(
                                            fontFamily: 'Poppins-Medium',
                                            color: Color(0xff1A2530),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    const Divider(color: Colors.black),
                                    Row(
                                      children: [
                                        const Text(
                                          'Tổng cộng',
                                          style: TextStyle(
                                            fontFamily: 'Poppins-Medium',
                                            color: Color(0xff1A2530),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          Formatter.formatCurrency(displayTotal.toInt()),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins-Medium',
                                            color: Color(0xff1A2530),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    RoundButtonTwo(
                                      onpress: () async {
                                        await placeOrder();
                                      },
                                      title: 'Thanh toán',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> placeOrder() async {
    final orderDb = FirebaseFirestore.instance.collection('Orders');

    try {
      if (_selectedItems != null && _selectedItems!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một sản phẩm để thanh toán!')),
        );
        return;
      }

      final itemsToOrder = _selectedItems ?? 
          List<PersistentShoppingCartItem>.from(
            cart.getCartData()['cartItems'] ?? []
          );
      
      for (var item in itemsToOrder) {
        if (item.quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sản phẩm "${item.productName}" có số lượng không hợp lệ!')),
          );
          return;
        }
        
        if (item.productDetails == null || 
            item.productDetails!['size'] == null || 
            item.productDetails!['color'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sản phẩm "${item.productName}" thiếu thông tin size hoặc color!')),
          );
          return;
        }
        
        if (item.unitPrice <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sản phẩm "${item.productName}" có giá không hợp lệ!')),
          );
          return;
        }
      }

      String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      List<Map<String, dynamic>> items =
          itemsToOrder.map((item) => item.toJson()).toList();
      
      final totalPrice = _selectedItems != null 
          ? _selectedTotalPrice 
          : cart.calculateTotalPrice();

      await orderDb.doc(orderId).set({
        'orderId': orderId,
        'userId': auth.currentUser!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        if (_currentAddress != null) ..._currentAddress!.toMap(),
        'totalPrice': totalPrice,
        'items': items,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (_selectedItems != null) {
        for (var item in _selectedItems!) {
          cart.removeFromCart(item.productId);
        }
      } else {
        cart.clearCart();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng đã được đặt thành công!')),
      );

      Navigator.pushNamed(context, RouteNames.navbarscreen);
    } catch (e) {
      debugPrint('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    namecontroller.dispose();
    phonecontroller.dispose();
    emailcontroller.dispose();
    super.dispose();
  }
}
