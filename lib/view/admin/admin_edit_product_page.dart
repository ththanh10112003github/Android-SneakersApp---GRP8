import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? productData;

  const EditProductScreen({super.key, this.productId, this.productData});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  String? selectedImageUrl;
  String? selectedBrandId;
  List<Map<String, String>> brands = [];

  @override
  void initState() {
    super.initState();
    fetchBrands().then((data) {
      setState(() {
        brands = data;
      });
    });

    if (widget.productData != null) {
      nameController.text = widget.productData!['productname'] ?? '';
      priceController.text = widget.productData!['productprice'] ?? '';
      descController.text = widget.productData!['description'] ?? '';
      selectedImageUrl = widget.productData!['imagelink'];
    }
  }

  Future<String?> uploadImageToCloudinary(String imagePath) async {
    const String cloudName = "dgfmiwien";
    const String apiKey = "BvZZdKGI6pq4C8QrALmkZWt2MnY";
    const String uploadPreset = "sneakers";

    try {
      File file = File(imagePath);
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path),
        "upload_preset": uploadPreset,
        "api_key": apiKey,
      });

      Response response = await Dio().post(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data["secure_url"] as String?;
      }
    } catch (_) {}

    return null;
  }

  Future<List<Map<String, String>>> fetchBrands() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('brands').get();
    return snapshot.docs
        .map((doc) => {"id": doc.id, "name": doc["name"].toString()})
        .toList();
  }

  Future<void> saveProduct() async {
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin!")),
      );
      return;
    }

    Map<String, dynamic> productData = {
      "brandId": selectedBrandId,
      "productname": nameController.text,
      "productprice": priceController.text,
      "unitprice": priceController.text,
      "description": descController.text,
      "imagelink": selectedImageUrl,
      "title": "Best Seller"
    };

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      if (widget.productId == null) {
        DocumentReference newProduct =
            await firestore.collection('products').add(productData);
        await newProduct.update({"productId": newProduct.id});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Thêm sản phẩm thành công!")),
        );
      } else {
        await firestore
            .collection('products')
            .doc(widget.productId)
            .update(productData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cập nhật sản phẩm thành công!")),
        );
      }

      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã xảy ra lỗi, vui lòng thử lại!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.productId == null
              ? "Thêm sản phẩm"
              : "Cập nhật sản phẩm")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Tên sản phẩm",
                labelStyle: TextStyling.hinttext,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                filled: true,
                fillColor: const Color.fromARGB(255, 233, 233, 236),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: "Giá sản phẩm",
                labelStyle: TextStyling.hinttext,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                filled: true,
                fillColor: const Color.fromARGB(255, 233, 233, 236),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 15),
            TextField(
              controller: descController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Mô tả sản phẩm",
                labelStyle: TextStyling.hinttext,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                filled: true,
                fillColor: const Color.fromARGB(255, 233, 233, 236),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedBrandId,
              hint: Text("Chọn thương hiệu"),
              items: brands.map((brand) {
                return DropdownMenuItem(
                  value: brand["id"],
                  child: Text(brand["name"]!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBrandId = value;
                });
              },
            ),
            SizedBox(height: 20),
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    selectedImageUrl ??
                        "https://cdn0.iconfinder.com/data/icons/apple-apps/100/Apple_Camera-512.png",
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  width: 1,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                XFile? image =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) {
                  String? uploadedUrl =
                      await uploadImageToCloudinary(image.path);
                  if (uploadedUrl != null) {
                    setState(() {
                      selectedImageUrl = uploadedUrl;
                    });
                  }
                }
              },
              child: Text("Chọn ảnh"),
            ),
            Spacer(),
            RoundButtonTwo(
              onpress: saveProduct,
              title: "Lưu",
            ),
          ],
        ),
      ),
    );
  }
}
