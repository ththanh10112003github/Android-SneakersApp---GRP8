import 'package:cloud_firestore/cloud_firestore.dart';

class ProductSearchService {
  static Future<Map<String, dynamic>?> findProductByName(String productName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final lowerProductName = productName.toLowerCase().trim();
      final productNameWords = lowerProductName.split(' ').where((w) => w.length > 2).toList();
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['productname'] ?? '').toString().toLowerCase();
        final brandId = (data['brandId'] ?? '').toString().toLowerCase();
        
        if (name == lowerProductName || name.contains(lowerProductName) || lowerProductName.contains(name)) {
          return {
            'productId': data['productId'] ?? doc.id,
            'productname': data['productname'] ?? 'N/A',
            'imagelink': data['imagelink'] ?? '',
            'productprice': data['productprice'] ?? 0,
            'title': data['title'] ?? 'N/A',
            'description': data['description'] ?? 'N/A',
          };
        }
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['productname'] ?? '').toString().toLowerCase();
        final brandId = (data['brandId'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        
        bool allWordsMatch = productNameWords.every((word) => 
          name.contains(word) || brandId.contains(word) || description.contains(word)
        );
        
        bool mainMatch = name.contains(lowerProductName) || 
                         brandId.contains(lowerProductName) ||
                         description.contains(lowerProductName);
        
        bool wordMatch = productNameWords.any((word) => 
          (name.contains(word) || brandId.contains(word)) && word.length > 2
        );
        
        if (allWordsMatch || mainMatch || wordMatch) {
          return {
            'productId': data['productId'] ?? doc.id,
            'productname': data['productname'] ?? 'N/A',
            'imagelink': data['imagelink'] ?? '',
            'productprice': data['productprice'] ?? 0,
            'title': data['title'] ?? 'N/A',
            'description': data['description'] ?? 'N/A',
          };
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

