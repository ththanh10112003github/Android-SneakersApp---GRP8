import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/view/admin/admin_edit_product_page.dart';
import 'package:flutter/material.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> products = [];

  int _getSalePercent(Map<String, dynamic> product) {
    try {
      if (product['salePercent'] != null) {
        return int.tryParse(product['salePercent'].toString()) ?? 0;
      }
    } catch (e) {
      print('Error parsing salePercent: $e');
    }
    return 0;
  }

  int _getPrice(Map<String, dynamic> product) {
    try {
      if (product['productprice'] != null) {
        return int.tryParse(product['productprice'].toString()) ?? 0;
      }
    } catch (e) {
      print('Error parsing price: $e');
    }
    return 0;
  }

  int _calculateSalePrice(Map<String, dynamic> product) {
    int originalPrice = _getPrice(product);
    int salePercent = _getSalePercent(product);
    return (originalPrice * (100 - salePercent) / 100).toInt();
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    CollectionReference productsCollection = firestore.collection('products');
    QuerySnapshot querySnapshot = await productsCollection.get();
    setState(() {
      products = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    });
  }

  Future<String?> uploadImageToCloudinary(String filePath) async {
    const String cloudName = "dgfmiwien";
    const String uploadPreset = "sneakers";

    try {
      File file = File(filePath);
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path),
        "upload_preset": uploadPreset,
      });

      Response response = await Dio().post(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data["secure_url"] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> addOrUpdateProduct(
      {String? id, Map<String, dynamic>? product}) async {
    bool? isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProductScreen(productId: id, productData: product),
      ),
    );

    if (isUpdated == true) {
      fetchProducts();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await firestore.collection('products').doc(id).delete();
      fetchProducts();

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Xóa sản phẩm thành công!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi xóa sản phẩm!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> confirmDeleteProduct(String id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa sản phẩm này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      deleteProduct(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Quản Lý Sản Phẩm",
          style: TextStyle(fontSize: 18),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.loginScreen);
            },
            icon: Icon(
              Icons.logout,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length + 1,
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return SizedBox(
                    height: 70,
                  );
                }
                final product = products[index];

                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.network(
                      product['imagelink'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: Icon(Icons.error_outline, color: Colors.red),
                        );
                      },
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(product['productname']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_getSalePercent(product) > 0) ...[
                            Row(
                              children: [
                                Text(
                                  "Giá gốc: ${Formatter.formatCurrency(int.tryParse(product['productprice'].toString()) ?? 0)}",
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "-${int.tryParse(product['salePercent'].toString()) ?? 0}%",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Giá sale: ${Formatter.formatCurrency(((int.tryParse(product['productprice'].toString()) ?? 0) * (100 - (int.tryParse(product['salePercent'].toString()) ?? 0)) / 100).toInt())}",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else
                            Text(
                              "Giá: ${Formatter.formatCurrency(_getPrice(product))}",
                            ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => addOrUpdateProduct(
                              id: product['id'], product: product),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => confirmDeleteProduct(product['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrUpdateProduct(),
        child: Icon(Icons.add),
      ),
    );
  }
}
