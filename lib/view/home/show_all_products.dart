import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/product_container.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/fav_provider.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/view/home/product_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShowProducts extends StatefulWidget {
  const ShowProducts({super.key});

  @override
  State<ShowProducts> createState() => _ShowProductsState();
}

class _ShowProductsState extends State<ShowProducts> {
  final db2 = FirebaseFirestore.instance.collection('Favourites');
  final id = FirebaseAuth.instance.currentUser!.uid.toString();

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();

  Future<void> initData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference productsCollection = firestore.collection('products');

    try {
      QuerySnapshot querySnapshot = await productsCollection.get();
      products = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      filteredProducts = List.from(products);

      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    initData();
    super.initState();
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = List.from(products);
      });
      return;
    }

    setState(() {
      filteredProducts = products
          .where((product) => product['productname']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favprovider = Provider.of<FavouriteProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f9),
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.navbarscreen);
          },
          child: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Tất cả sản phẩm'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
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
              onChanged: searchProducts,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return ShowProductContainer(
                    subtitle: filteredProducts[index]['productname'],
                    imagelink: filteredProducts[index]['imagelink'],
                    price: Formatter.formatCurrency(
                        double.parse(filteredProducts[index]['productprice'])
                            .toInt()),
                    quantity: 0,
                    fav: IconButton(
                      onPressed: () async {
                        if (favprovider.items
                            .contains(filteredProducts[index]['productId'])) {
                          favprovider
                              .remove(filteredProducts[index]['productId']);
                          db2
                              .doc(id)
                              .collection('items')
                              .doc(filteredProducts[index]['productId'])
                              .delete();
                        } else {
                          favprovider.add(filteredProducts[index]['productId']);
                          db2
                              .doc(id)
                              .collection('items')
                              .doc(filteredProducts[index]['productId'])
                              .set({
                            'product id':
                                filteredProducts[index]['productId'].toString(),
                            'name': filteredProducts[index]['productname']
                                .toString(),
                            'subtitle':
                                filteredProducts[index]['title'].toString(),
                            'image':
                                filteredProducts[index]['imagelink'].toString(),
                            'price': filteredProducts[index]['productprice']
                                .toString(),
                            'description': filteredProducts[index]
                                    ['description']
                                .toString(),
                          });
                        }
                      },
                      icon: Icon(
                        favprovider.items
                                .contains(filteredProducts[index]['productId'])
                            ? Icons.favorite
                            : Icons.favorite_border_outlined,
                        color: Colors.red,
                      ),
                    ),
                    onclick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => ProductDetails(
                            title: filteredProducts[index]['productname'],
                            price: filteredProducts[index]['productprice'],
                            productid: filteredProducts[index]['productId'],
                            unitprice: filteredProducts[index]['unitprice'],
                            image: filteredProducts[index]['imagelink'],
                            description: filteredProducts[index]['description'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
