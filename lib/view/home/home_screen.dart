import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/app_bar.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/brand_list.dart';
import 'package:ecommerce_app/respository/components/product_container.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/fav_provider.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/view/home/product_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PersistentShoppingCart cart = PersistentShoppingCart();

  List<Map<String, dynamic>> products = [];

  Future<void> initData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference productsCollection = firestore.collection('products');
    try {
      QuerySnapshot querySnapshot = await productsCollection.get();
      products = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenheight = MediaQuery.of(context).size.height;
    final screenwidth = MediaQuery.of(context).size.width;
    final db2 = FirebaseFirestore.instance.collection('Favourites');
    final id = FirebaseAuth.instance.currentUser!.uid.toString();

    final favprovider = Provider.of<FavouriteProvider>(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBarComp(
          color: const Color(0xfff7f7f9),
          apptitle: 'Khám phá',
          appleading: IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Image(image: AssetImage('images/bar.png'))),
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
        ),
      ),
      backgroundColor: const Color(0xffF7F7F9),
      body: Padding(
        padding: EdgeInsets.only(
          left: screenwidth * 0.05,
          right: screenwidth * 0.05,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: screenheight * 0.02,
              ),
              SizedBox(
                width: screenwidth,
                child: TextFormField(
                  readOnly: true,
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.productsScreen);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xff6A6A6A),
                    ),
                    hintText: 'Tìm kiếm giày',
                    hintStyle: TextStyling.hinttext,
                    filled: true,
                    fillColor: const Color(0xffffffff),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: screenheight * 0.03,
              ),
              const Text(
                'Chọn danh mục',
                style: TextStyle(
                  fontFamily: 'Raleway-SemiBold',
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              SizedBox(
                height: screenheight * 0.03,
              ),
              BrandList(),
              SizedBox(
                height: screenheight * 0.03,
              ),
              Row(
                children: [
                  const Text(
                    'Giày phổ biến',
                    style: TextStyle(
                      fontFamily: 'Raleway-SemiBold',
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.productsScreen);
                    },
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontFamily: 'Raleway-SemiBold',
                        color: AppColor.backgroundColor,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              ),
              if (products.length >= 8)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 8,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) => ProductDetails(
                              title: products[index]['productname'],
                              price: products[index]['productprice'],
                              productid: products[index]['productId'],
                              unitprice: products[index]['unitprice'],
                              image: products[index]['imagelink'].toString(),
                              description: products[index]['description'],
                            ),
                          ),
                        );
                      },
                      child: ProductContainer(
                        fav: IconButton(
                          onPressed: () async {
                            if (favprovider.items
                                .contains(products[index]['productId'])) {
                              favprovider.remove(products[index]['productId']);
                              db2
                                  .doc(id)
                                  .collection('items')
                                  .doc(products[index]['productId'])
                                  .delete();
                            } else {
                              favprovider.add(products[index]['productId']);
                              db2
                                  .doc(id)
                                  .collection('items')
                                  .doc(products[index]['productId'])
                                  .set(
                                {
                                  'product id':
                                      products[index]['productId'].toString(),
                                  'name':
                                      products[index]['productname'].toString(),
                                  'subtitle':
                                      products[index]['title'].toString(),
                                  'image':
                                      products[index]['imagelink'].toString(),
                                  'price': products[index]['productprice']
                                      .toString(),
                                  'description':
                                      products[index]['description'].toString(),
                                },
                              );
                            }
                          },
                          icon: Icon(
                            favprovider.items
                                    .contains(products[index]['productId'])
                                ? Icons.favorite
                                : Icons.favorite_border_outlined,
                            color: Colors.red,
                          ),
                        ),
                        id: products[index]['productId'],
                        subtitle: products[index]['productname'],
                        imagelink: products[index]['imagelink'],
                        price: Formatter.formatCurrency(
                            double.parse(products[index]['productprice'])
                                .toInt()),
                        quantity: 0,
                      ),
                    );
                  },
                ),
              Row(
                children: [
                  const Text(
                    'Hàng mới',
                    style: TextStyle(
                        fontFamily: 'Raleway-SemiBold',
                        color: Colors.black,
                        fontSize: 16),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.productsScreen);
                    },
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                          fontFamily: 'Poppins-Medium',
                          color: AppColor.backgroundColor,
                          fontSize: 16),
                    ),
                  )
                ],
              ),
              Container(
                height: screenheight * 0.14,
                width: screenwidth * 0.85,
                decoration: const BoxDecoration(color: Colors.white),
                child: const Padding(
                  padding: EdgeInsets.only(top: 10, left: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Summer Sale',
                                style: TextStyle(
                                    fontFamily: 'Raleway-SemiBold',
                                    color: Colors.black,
                                    fontSize: 12),
                              ),
                              Text(
                                '15%  OFF',
                                style: TextStyle(
                                    fontFamily: 'Poppins-Medium',
                                    color: Color(0xff674DC5),
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 40,
                          ),
                          Image(
                            image: AssetImage(
                              'images/shoe3.png',
                            ),
                            height: 70,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
