import 'package:cloud_firestore/cloud_firestore.dart';

class ProductKnowledgeBase {
  static List<String>? _cachedBrands;
  static List<String>? _cachedProductNames;
  static DateTime? _lastUpdate;
  static const Duration cacheDuration = Duration(minutes: 30);

  static Future<List<String>> getBrands({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedBrands != null && _isCacheValid()) {
      return _cachedBrands!;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      final brands = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final brandId = (data['brandId'] ?? '').toString().toLowerCase().trim();
        if (brandId.isNotEmpty) {
          brands.add(brandId);
        }
      }

      _cachedBrands = brands.toList()..sort();
      _lastUpdate = DateTime.now();
      return _cachedBrands!;
    } catch (e) {
      return ['nike', 'adidas', 'puma', 'converse', 'under armour', 'reebok'];
    }
  }

  static Future<List<String>> getProductNames({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProductNames != null && _isCacheValid()) {
      return _cachedProductNames!;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      final productNames = <String>{};
      final productNameWords = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final productName = (data['productname'] ?? '').toString().toLowerCase().trim();
        
        if (productName.isNotEmpty) {
          productNames.add(productName);
          
          final words = productName.split(' ');
          for (var word in words) {
            final cleanedWord = word.trim();
            if (cleanedWord.length > 2 && 
                !RegExp(r'^\d+$').hasMatch(cleanedWord) &&
                !_isBrand(cleanedWord)) {
              productNameWords.add(cleanedWord);
            }
          }
          
          for (int i = 0; i < words.length - 1; i++) {
            final twoWords = '${words[i]} ${words[i + 1]}';
            if (twoWords.length > 4 && !_isBrand(twoWords)) {
              productNameWords.add(twoWords);
            }
          }
          
          for (int i = 0; i < words.length - 2; i++) {
            final threeWords = '${words[i]} ${words[i + 1]} ${words[i + 2]}';
            if (threeWords.length > 6 && !_isBrand(threeWords)) {
              productNameWords.add(threeWords);
            }
          }
        }
      }

      final allNames = <String>{};
      allNames.addAll(productNames);
      allNames.addAll(productNameWords);
      
      _cachedProductNames = allNames.toList()..sort();
      _lastUpdate = DateTime.now();
      return _cachedProductNames!;
    } catch (e) {
      return [
        'air force', 'dunk', 'pegasus', 'air max', 'stan smith', 'ultraboost', 
        'nmd', 'suede', 'rs-x', 'chuck', 'chuck taylor', 'run star', 'curry', 'hovr',
        'deviate', 'nitro', 'deviate nitro', 'acg', 'mountain fly', 'chuck 70', 
        'all star', 'run star hike', 'charged assert', 'phantom'
      ];
    }
  }

  static bool _isCacheValid() {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) < cacheDuration;
  }

  static bool _isBrand(String word) {
    final commonBrands = ['nike', 'adidas', 'puma', 'converse', 'under', 'armour', 'reebok'];
    return commonBrands.contains(word.toLowerCase());
  }

  static Future<void> refreshCache() async {
    await getBrands(forceRefresh: true);
    await getProductNames(forceRefresh: true);
  }

  static void clearCache() {
    _cachedBrands = null;
    _cachedProductNames = null;
    _lastUpdate = null;
  }
}

