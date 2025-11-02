import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

Future<void> addBrands() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference brandsCollection = firestore.collection('brands');

  List<Map<String, dynamic>> brands = [
    {"name": "Nike"},
    {"name": "Adidas"},
    {"name": "Puma"},
    {"name": "Reebok"},
  ];

  for (var brand in brands) {
    await brandsCollection.add(brand);
  }
}

Future<String?> uploadImageToCloudinary(String assetPath) async {
  const String cloudName = "dgfmiwien";
  const String apiKey = "BvZZdKGI6pq4C8QrALmkZWt2MnY";
  const String uploadPreset = "sneakers";

  try {
    XFile image = XFile(assetPath);
    File file = File(image.path);

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path),
      "upload_preset": uploadPreset,
      "api_key": apiKey,
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

class ProductList {
  ProductList() {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference productsCollection = firestore.collection('products');
    try {
      QuerySnapshot querySnapshot = await productsCollection.get();
      itemlist = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (_) {}
  }

  List<Map<String, dynamic>> itemlist = [];
}
