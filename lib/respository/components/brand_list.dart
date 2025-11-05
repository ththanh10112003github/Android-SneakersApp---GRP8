import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/view/home/product_by_brand_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandList extends StatefulWidget {
  const BrandList({super.key});

  @override
  State<BrandList> createState() => _BrandListState();
}

class _BrandListState extends State<BrandList> {
  List<Map<String, dynamic>> brands = [];

  @override
  void initState() {
    super.initState();
    fetchBrands();
  }

  Future<void> fetchBrands() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference brandsCollection = firestore.collection('brands');

      QuerySnapshot snapshot = await brandsCollection.get();
      List<Map<String, dynamic>> loadedBrands = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'] ?? '',
          'image': doc['image'] ?? '',
        };
      }).toList();

      setState(() {
        brands = loadedBrands;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return brands.isEmpty
        ? const Center(
            child:
                CircularProgressIndicator()) // Hiển thị loading nếu chưa tải xong
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: brands.map((brand) {
                return InkWell(
                  radius: 12,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductByBrandScreen(
                          brandId: brand['id'],
                          brandName: brand['name'],
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              brand['name'],
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: brand['image'].isNotEmpty
                                  ? ClipOval(
                                      child: SvgPicture.network(
                                        brand['image'],
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
  }
}
