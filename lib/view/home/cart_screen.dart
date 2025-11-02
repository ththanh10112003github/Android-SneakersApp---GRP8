import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:flutter/material.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PersistentShoppingCart cart = PersistentShoppingCart();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f9),
      appBar: AppBar(
        backgroundColor: const Color(0xfff7f7f9),
        title: const Text('Giỏ hàng của tôi'),
        titleTextStyle: TextStyling.apptitle,
        centerTitle: true,
        leading: SizedBox.shrink(),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 10,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Column(
            children: [
              Expanded(
                child: cart.showCartItems(
                  cartItemsBuilder: (context, data) {
                    if (data.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Giỏ hàng đang rỗng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  RouteNames.navbarscreen,
                                  (route) => false,
                                );
                              },
                              child: const Text('Tiếp tục mua sắm'),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return Container(
                          height: 104,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              Image.network(
                                data[index].productThumbnail.toString(),
                                height: 50,
                                width: 70,
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      data[index].productName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          Formatter.formatCurrency(
                                              data[index].unitPrice.toInt()),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Spacer(),
                                        InkWell(
                                          onTap: () {
                                            cart.decrementCartItemQuantity(
                                              data[index].productId,
                                            );
                                          },
                                          child: const Icon(
                                            Icons.remove_circle_outlined,
                                            color: AppColor.buttonColorTwo,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          data[index].quantity.toString(),
                                          style: const TextStyle(),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            cart.incrementCartItemQuantity(
                                              data[index].productId,
                                            );
                                          },
                                          child: const Icon(
                                            Icons.add_circle_outlined,
                                            color: AppColor.buttonColorTwo,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    data[index]
                                        .productDetails!['size']
                                        .toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    data[index]
                                        .productDetails!['color']
                                        .toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      cart.removeFromCart(
                                          data[index].productId);
                                    },
                                    icon: Icon(
                                      color: Colors.red,
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              cart.showTotalAmountWidget(
                cartTotalAmountWidgetBuilder: (totalAmount) => Visibility(
                  visible: totalAmount == 0.0 ? false : true,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Formatter.formatCurrency(
                                      cart.calculateTotalPrice().toInt()),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins-Medium',
                                    color: Color(0xff1A2530),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
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
                            const SizedBox(
                              height: 20,
                            ),
                            const Divider(
                              color: Colors.black,
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Tổng cộng',
                                  style: TextStyle(
                                      fontFamily: 'Poppins-Medium',
                                      color: Color(0xff1A2530),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Spacer(),
                                Text(
                                  Formatter.formatCurrency(
                                      cart.calculateTotalPrice().toInt()),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins-Medium',
                                    color: Color(0xff1A2530),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            RoundButtonTwo(
                              onpress: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.checkOutScreen,
                                );
                              },
                              title: 'Thanh toán',
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
