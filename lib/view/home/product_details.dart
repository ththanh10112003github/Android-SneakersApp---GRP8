import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/fav_provider.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';
import 'package:provider/provider.dart';

class ProductDetails extends StatefulWidget {
  final String title;
  final String price;
  final String image;
  final String unitprice;
  final String productid;
  final String description;

  const ProductDetails({
    super.key,
    required this.title,
    required this.price,
    required this.image,
    required this.unitprice,
    required this.productid,
    required this.description,
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final db2 = FirebaseFirestore.instance.collection('Favourites');

  final id = FirebaseAuth.instance.currentUser!.uid.toString();

  final PersistentShoppingCart cart = PersistentShoppingCart();

  String sizePicker = '38';
  Color colorPicker = Colors.blue;

  InkWell buildButtonColor(Color color) {
    return InkWell(
      onTap: () {
        colorPicker = color;
        setState(() {});
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorPicker == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
          shape: BoxShape.circle,
        ),
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget buildButtonSize(String size) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          sizePicker = size;
          setState(() {});
        },
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sizePicker == size
                ? colorPicker
                : const Color.fromARGB(255, 229, 231, 232),
          ),
          child: Center(
            child: Text(
              size,
              style: TextStyle(
                color: sizePicker == size ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    final favprovider = Provider.of<FavouriteProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f9),
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: cart.showCartItemCountWidget(
              cartItemCountWidgetBuilder: ((int itemCount) {
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.cartscreen);
                  },
                  child: Badge(
                    label: Text(itemCount.toString()),
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Image.asset(
                        'images/cart.png',
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(
            width: 10,
          )
        ],
        leading: InkWell(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.navbarscreen);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
        backgroundColor: const Color(0xfff7f7f9),
        title: const Text(
          'Sneakers Shop',
          style: TextStyle(fontFamily: 'Raleway-SemiBold', fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: screenwidth * 0.06,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              Center(
                child: Image.network(
                  widget.image,
                  height: screenheight * 0.18,
                  width: screenwidth * 0.7,
                ),
              ),
              SizedBox(
                height: screenheight * 0.05,
              ),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 26,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              const Text(
                'Giày Nam',
                style: TextStyle(
                  color: Color(0xff707b81),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                Formatter.formatCurrency(double.parse(widget.price).toInt()),
                style: const TextStyle(
                  fontSize: 26,
                ),
              ),
              Text(
                widget.description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xff707B81),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Text(
                'Màu sắc',
                style: const TextStyle(
                  fontFamily: 'Poppins-Medium',
                  fontSize: 18,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    buildButtonColor(Colors.blue),
                    buildButtonColor(Colors.red),
                    buildButtonColor(Colors.grey),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'Kích thước',
                style: const TextStyle(
                  fontFamily: 'Poppins-Medium',
                  fontSize: 18,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    buildButtonSize('38'),
                    buildButtonSize('39'),
                    buildButtonSize('40'),
                    buildButtonSize('41'),
                    buildButtonSize('42'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Row(
                  children: [
                    Container(
                      height: 55,
                      width: 55,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xffD9D9D9)),
                      child: IconButton(
                        onPressed: () async {
                          if (favprovider.items.contains(widget.productid)) {
                            favprovider.remove(widget.productid);

                            db2
                                .doc(id)
                                .collection('items')
                                .doc(widget.productid)
                                .delete();
                          } else {
                            favprovider.add(widget.productid);
                            db2
                                .doc(id)
                                .collection('items')
                                .doc(widget.productid)
                                .set(
                              {
                                'name': widget.title,
                                'subtitle': 'Best Seller',
                                'image': widget.image,
                                'price': widget.price,
                                'description': widget.description,
                              },
                            );
                          }
                        },
                        icon: Icon(
                          favprovider.items.contains(widget.productid)
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    InkWell(
                      onTap: () {
                        final String color = colorPicker == Colors.red
                            ? 'Red'
                            : colorPicker == Colors.blue
                                ? 'Blue'
                                : 'Grey';
                        cart
                            .addToCart(
                              PersistentShoppingCartItem(
                                productThumbnail: widget.image,
                                productId: widget.productid,
                                productName: widget.title,
                                unitPrice: double.parse(widget.unitprice),
                                quantity: 1,
                                productDetails: {
                                  "size": sizePicker,
                                  "color": color,
                                },
                              ),
                            )
                            .then(
                              (value) => {
                                GeneralUtils().showsuccessflushbar(
                                  'Sản phẩm đã được thêm vào giỏ hàng',
                                  context,
                                )
                              },
                            );
                      },
                      child: Container(
                        height: 50,
                        width: 208,
                        decoration: BoxDecoration(
                          color: AppColor.backgroundColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset('images/cart.png'),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              'Thêm Vào Giỏ Hàng',
                              style: TextStyle(
                                fontFamily: 'Raleway-SemiBold',
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
