import 'package:ecommerce_app/model/chat_message.dart';
import 'package:ecommerce_app/services/product_knowledge_base.dart';

class OrderIntentDetector {
  static String? extractOrderId(String message) {
    final regex = RegExp(r'(?:đơn hàng|order|mã đơn|orderid|order id)[\s#:]*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(message);
    if (match != null) {
      return match.group(1);
    }
    
    final numberRegex = RegExp(r'\b\d{10,15}\b');
    final numberMatch = numberRegex.firstMatch(message);
    return numberMatch?.group(0);
  }

  static Map<String, dynamic> detectOrderIntent(String message) {
    final lowerMessage = message.toLowerCase();
    final orderId = extractOrderId(message);
    
    final orderKeywords = [
      'đơn hàng', 'order', 'đơn',
      'đã mua', 'đã mua', 'mua những gì', 'mua gì', 'mua rồi',
      'đã đặt', 'đã đặt hàng', 'đặt hàng', 'đặt những gì',
      'lịch sử', 'lịch sử đơn hàng', 'lịch sử mua hàng', 'order history',
      'sản phẩm đã mua', 'đã mua sản phẩm', 'sản phẩm mua được',
      'giày đã mua', 'giày đã đặt', 'sản phẩm đã đặt'
    ];
    
    final isOrderQuery = orderKeywords.any((keyword) => lowerMessage.contains(keyword)) ||
                        orderId != null;
    
    String? status;
    if (lowerMessage.contains('Chờ lấy hàng') || lowerMessage.contains('pending')) {
      status = 'pending';
    } else if (lowerMessage.contains('đã giao') || lowerMessage.contains('delivered') || lowerMessage.contains('completed')) {
      status = 'delivered';
    } else if (lowerMessage.contains('Chờ giao hàng') || lowerMessage.contains('shipping')) {
      status = 'shipping';
    } else if (lowerMessage.contains('đã hủy') || lowerMessage.contains('cancelled')) {
      status = 'cancelled';
    } else if (lowerMessage.contains('tất cả') || lowerMessage.contains('all orders')) {
      status = 'tất cả';
    }
    
    return {
      'isOrderQuery': isOrderQuery || status != null,
      'orderId': orderId,
      'status': status,
    };
  }
}

class PurchaseIntentDetector {
  static Future<Map<String, dynamic>> detectPurchaseIntent(
    String message, 
    List<ChatMessage> conversationHistory
  ) async {
    final lowerMessage = message.toLowerCase();
    
    final strongPurchaseKeywords = [
      'thêm vào giỏ', 'thêm giỏ hàng', 'add to cart',
      'đặt hàng', 'cho tôi mua', 'mua giúp tôi'
    ];
    
    final purchaseKeywords = [
      'mua', 'nua', 'đặt mua', 'muốn mua', 'tôi muốn mua', 'muốn nua',
      'buy', 'tôi cần', 'cần mua', 'cần nua', 'đặt cho tôi'
    ];
    
    final referenceKeywords = [
      'mua cái đó', 'mua nó', 'mua cái này', 'mua cái đầu tiên',
      'mua cái thứ nhất', 'mua cái thứ hai', 'mua cái cuối',
      'cho tôi cái đó', 'cho tôi nó', 'tôi muốn cái đó',
      'thêm cái đó vào giỏ', 'thêm nó vào giỏ'
    ];
    
    bool isStrongPurchase = strongPurchaseKeywords.any((keyword) => lowerMessage.contains(keyword));
    bool hasReference = referenceKeywords.any((keyword) => lowerMessage.contains(keyword));
    bool hasPurchaseKeyword = purchaseKeywords.any((keyword) => lowerMessage.contains(keyword));
    
    final productName = await ProductNameExtractor.extractProductName(message);
    final hasSpecificProduct = productName != null && 
                               productName.length >= 3 &&
                               !ProductNameExtractor.isGenericPhrase(productName);
    
    int confidence = 0;
    if (isStrongPurchase) confidence += 3;
    if (hasReference) confidence += 2;
    if (hasPurchaseKeyword) confidence += 1;
    if (hasSpecificProduct) confidence += 2;
    
    bool hasOnlyBrand = false;
    if (productName != null && 
        productName.length >= 3 &&
        !ProductNameExtractor.isGenericPhrase(productName)) {
      hasOnlyBrand = await ProductNameExtractor.isOnlyBrand(productName);
    }
    
    bool isPurchaseIntent = false;
    
    if (hasOnlyBrand) {
      isPurchaseIntent = false;
    } else if (hasReference && hasRecentProductInContext(conversationHistory)) {
      isPurchaseIntent = true;
    } else if (isStrongPurchase && hasSpecificProduct && !hasOnlyBrand) {
      isPurchaseIntent = true;
    } else if (confidence >= 4 && hasSpecificProduct && !hasOnlyBrand) {
      isPurchaseIntent = true;
    } else if (hasSpecificProduct && !hasOnlyBrand) {
      final words = lowerMessage.trim().split(RegExp(r'\s+'));
      final productWords = productName!.toLowerCase().split(' ');
      final isProductNameOnly = words.length <= productWords.length + 3;
      if (isProductNameOnly) {
        isPurchaseIntent = true;
      }
    }
    
    bool isConfirmationIntent = false;
    if (conversationHistory.isNotEmpty) {
      final lastAIMessage = conversationHistory
          .where((msg) => !msg.fromUser)
          .lastOrNull;
      
      if (lastAIMessage != null) {
        final lowerAIMessage = lastAIMessage.text.toLowerCase();
        
        final isOrderRelated = lowerAIMessage.contains('đơn hàng') ||
                              lowerAIMessage.contains('order') ||
                              lowerAIMessage.contains('mã đơn hàng') ||
                              lowerAIMessage.contains('order id') ||
                              lowerAIMessage.contains('lịch sử đơn hàng') ||
                              lowerAIMessage.contains('order history') ||
                              lowerAIMessage.contains('trạng thái đơn hàng') ||
                              lowerAIMessage.contains('order status') ||
                              lowerAIMessage.contains('đã đặt') ||
                              lowerAIMessage.contains('đã mua') ||
                              lowerAIMessage.contains('chi tiết đơn hàng') ||
                              lowerAIMessage.contains('order detail');
        
        if (isOrderRelated) {
          return {
            'isPurchaseIntent': false,
            'confidence': 0,
            'hasSpecificProduct': false,
            'hasReference': false,
            'isConfirmationIntent': false,
          };
        }
        
        final isProductList = RegExp(r'\d+\.\s*\*\*').hasMatch(lastAIMessage.text) ||
                            RegExp(r'\d+\.\s+').hasMatch(lastAIMessage.text) ||
                            lowerAIMessage.contains('gợi ý') ||
                            (lowerAIMessage.contains('mẫu') && lowerAIMessage.contains('sau')) ||
                            lowerAIMessage.contains('bạn thích mẫu nào') ||
                            lowerAIMessage.contains('bạn muốn mình tư vấn') ||
                            (lowerAIMessage.split('**').length - 1) >= 4;
        
        if (!isProductList) {
          final aiAsksToAdd = lowerAIMessage.contains('thêm') || 
                             lowerAIMessage.contains('add') ||
                             lowerAIMessage.contains('giỏ hàng') ||
                             lowerAIMessage.contains('cart') ||
                             lowerAIMessage.contains('bạn có muốn') ||
                             lowerAIMessage.contains('muốn mình') ||
                             lowerAIMessage.contains('thanh toán');
          
          final confirmationKeywords = ['có', 'yes', 'ok', 'đồng ý', 'được', 'thêm', 'mua', 'cho tôi'];
          final isConfirmation = confirmationKeywords.any((keyword) => lowerMessage.contains(keyword));
          
          if (aiAsksToAdd && isConfirmation) {
            isConfirmationIntent = true;
          }
        }
      }
    }
    
    if (isConfirmationIntent) {
      isPurchaseIntent = true;
      confidence = 5;
    }
    
    return {
      'isPurchaseIntent': isPurchaseIntent,
      'confidence': confidence,
      'hasSpecificProduct': hasSpecificProduct,
      'hasReference': hasReference,
      'isConfirmationIntent': isConfirmationIntent,
    };
  }
  
  static Future<String?> extractProductFromAIContext(List<ChatMessage> conversationHistory) async {
    if (conversationHistory.isEmpty) return null;
    
    final recentAIMessages = conversationHistory
        .where((msg) => !msg.fromUser)
        .take(5)
        .toList();
    
    if (recentAIMessages.isEmpty) return null;
    
    for (var msg in recentAIMessages.reversed) {
      final lowerAIMessage = msg.text.toLowerCase();
      
      final isOrderRelated = lowerAIMessage.contains('đơn hàng') ||
                            lowerAIMessage.contains('order') ||
                            lowerAIMessage.contains('mã đơn hàng') ||
                            lowerAIMessage.contains('order id') ||
                            lowerAIMessage.contains('lịch sử đơn hàng') ||
                            lowerAIMessage.contains('order history') ||
                            lowerAIMessage.contains('trạng thái đơn hàng') ||
                            lowerAIMessage.contains('order status') ||
                            lowerAIMessage.contains('đã đặt') ||
                            lowerAIMessage.contains('đã mua') ||
                            lowerAIMessage.contains('chi tiết đơn hàng') ||
                            lowerAIMessage.contains('order detail') ||
                            lowerAIMessage.contains('đơn hàng đã được đặt') ||
                            lowerAIMessage.contains('đã được đặt thành công') ||
                            lowerAIMessage.contains('thành tiền') ||
                            lowerAIMessage.contains('thông tin giao hàng');
      
      final isProductList = RegExp(r'\d+\.\s*\*\*').hasMatch(msg.text) ||
                            RegExp(r'\d+\.\s+').hasMatch(msg.text) ||
                            lowerAIMessage.contains('gợi ý') ||
                            lowerAIMessage.contains('mẫu') ||
                            lowerAIMessage.contains('sau') ||
                            lowerAIMessage.contains('bạn thích mẫu nào') ||
                            lowerAIMessage.contains('bạn muốn mình tư vấn') ||
                            (lowerAIMessage.contains('mẫu') && lowerAIMessage.contains('sau')) ||
                            (lowerAIMessage.split('**').length - 1) >= 4;
      
      if (isOrderRelated || isProductList) {
        continue;
      }
      
      final productName = await ProductNameExtractor.extractProductName(msg.text);
      if (productName != null && 
          productName.isNotEmpty && 
          productName.length >= 3 &&
          !ProductNameExtractor.isGenericPhrase(productName)) {
        return productName;
      }
    }
    
    return null;
  }
  
  static bool hasRecentProductInContext(List<ChatMessage> conversationHistory) {
    if (conversationHistory.isEmpty) return false;
    
    final recentAIMessages = conversationHistory
        .where((msg) => !msg.fromUser)
        .take(5)
        .toList();
    
    final brands = ['nike', 'adidas', 'puma', 'converse', 'under armour', 'reebok'];
    final productNames = [
      'air force', 'dunk', 'pegasus', 'air max', 'stan smith', 'ultraboost', 
      'nmd', 'suede', 'rs-x', 'chuck', 'chuck taylor', 'run star', 'curry', 'hovr'
    ];
    
    for (var msg in recentAIMessages) {
      final lowerText = msg.text.toLowerCase();
      bool hasBrand = brands.any((brand) => lowerText.contains(brand));
      bool hasProductName = productNames.any((pn) => lowerText.contains(pn));
      
      if (hasBrand || hasProductName) {
        return true;
      }
    }
    
    return false;
  }
}

class ProductNameExtractor {
  static Future<String?> extractProductName(String message) async {
    final brands = await ProductKnowledgeBase.getBrands();
    final productNames = await ProductKnowledgeBase.getProductNames();
    
    String lowerMessage = message.toLowerCase();
    
    String? foundBrand;
    for (var brand in brands) {
      if (lowerMessage.contains(brand)) {
        foundBrand = brand;
        break;
      }
    }
    
    String? foundProductName;
    int maxLength = 0;
    
    final sortedProductNames = List<String>.from(productNames)
      ..sort((a, b) {
        final aWords = a.split(' ').length;
        final bWords = b.split(' ').length;
        if (aWords != bWords) {
          return bWords.compareTo(aWords);
        }
        return b.length.compareTo(a.length);
      });
    
    for (var productName in sortedProductNames) {
      final lowerPn = productName.toLowerCase();
      if (lowerMessage.contains(lowerPn)) {
        if (foundProductName == null || productName.length > maxLength) {
          foundProductName = productName;
          maxLength = productName.length;
          if (productName.split(' ').length >= 2) {
            break;
          }
        }
      }
    }
    
    if (foundBrand != null && foundProductName != null) {
      final lowerProductName = foundProductName.toLowerCase();
      if (lowerProductName.contains(foundBrand)) {
        return foundProductName;
      }
      String combined = '$foundBrand $foundProductName';
      return combined;
    }
    
    if (foundBrand != null) {
      final brandIndex = lowerMessage.indexOf(foundBrand);
      if (brandIndex != -1) {
        String afterBrand = message.substring(brandIndex + foundBrand.length).trim();
        
        final purchaseKeywords = [
          'mua', 'đặt mua', 'muốn mua', 'cho tôi', 'tôi muốn mua',
          'thêm vào giỏ', 'thêm giỏ hàng', 'add to cart', 'buy',
          'đặt hàng', 'tôi cần', 'cần mua', 'mua giúp', 'đặt cho tôi',
          'giúp tôi mua', 'hãy mua', 'làm ơn mua', 'mình muốn mua', 'thêm',
          'được', 'đấy', 'đó', 'này', 'rồi', 'thế'
        ];
        
        final stopWords = ['với', 'một', 'cái', 'đôi', 'của', 'cho', 'giúp', 'tôi', 'mình', 'và', 'về', 'những', 'nào', 'đó', 'thế', 'lông', 'được', 'đấy', 'rồi', 
                           'size', 'giày', 'nhé', 'bạn', 'ơi', 'thì', 'là', 'đi'];
        
        String cleaned = afterBrand.toLowerCase();
        for (var keyword in purchaseKeywords) {
          cleaned = cleaned.replaceAll(RegExp('\\b$keyword\\b', caseSensitive: false), '');
        }
        for (var word in stopWords) {
          cleaned = cleaned.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
        }
        
        cleaned = cleaned.trim().replaceAll(RegExp(r'[^\w\sàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]', unicode: true), '');
        cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
        
        final words = cleaned.split(' ').where((w) => w.length > 2).toList();
        
        if (words.isNotEmpty) {
          final productNamesFromDb = await ProductKnowledgeBase.getProductNames();
          final fullText = words.join(' ');
          
          String? matchedProductName;
          int maxMatchLength = 0;
          
          for (var pn in productNamesFromDb) {
            final lowerPn = pn.toLowerCase();
            if (fullText.contains(lowerPn) || lowerPn.contains(fullText)) {
              if (pn.length > maxMatchLength) {
                matchedProductName = pn;
                maxMatchLength = pn.length;
              }
            }
          }
          
          if (matchedProductName != null) {
            String fullProductName = '$foundBrand $matchedProductName';
            return fullProductName;
          } else {
            String fullProductName = '$foundBrand ${words.join(' ')}';
            return fullProductName;
          }
        }
      }
      
      return foundBrand;
    }
    
    if (foundProductName != null) {
      return foundProductName;
    }
    final purchaseKeywords = [
      'mua', 'đặt mua', 'muốn mua', 'cho tôi', 'tôi muốn mua',
      'thêm vào giỏ', 'thêm giỏ hàng', 'add to cart', 'buy',
      'đặt hàng', 'tôi cần', 'cần mua', 'mua giúp', 'đặt cho tôi',
      'giúp tôi mua', 'hãy mua', 'làm ơn mua', 'mình muốn mua', 'thêm'
    ];

    final greetingWords = [
      'chào', 'xin chào', 'hello', 'hi', 'chào bạn', 'bạn',
      'của bạn', 'của mình', 'của tôi'
    ];

    String cleanedMessage = message;
    
    for (var keyword in purchaseKeywords) {
      cleanedMessage = cleanedMessage.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }

    for (var word in greetingWords) {
      cleanedMessage = cleanedMessage.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }

    final stopWords = ['với', 'một', 'cái', 'đôi', 'của', 'cho', 'giúp', 'tôi', 'mình', 'và', 'về', 'những', 'nào', 'đó', 'thế', 'lông',
                       'size', 'giày', 'nhé', 'bạn', 'ơi', 'thì', 'là', 'đi', 'có', 'nghĩ', 'chọn', 'xin', 'muốn', 'nhưng', 'chưa', 'biết', 'loại'];
    for (var word in stopWords) {
      cleanedMessage = cleanedMessage.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }

    cleanedMessage = cleanedMessage.trim().replaceAll(RegExp(r'[^\w\sàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]', unicode: true), '');
    cleanedMessage = cleanedMessage.replaceAll(RegExp(r'\s+'), ' ').trim();

    final remainingStopWords = ['đôi', 'cái', 'một', 'và', 'với', 'cho', 'về', 'những', 'nào', 'đó', 'thế',
                                'size', 'giày', 'nhé', 'bạn', 'ơi', 'thì', 'là', 'đi', 'có', 'nghĩ', 'chọn',
                                'xin', 'muốn', 'nhưng', 'chưa', 'biết', 'loại'];
    final cleanedWords = cleanedMessage.toLowerCase().split(' ').where((w) => w.length > 2 && !remainingStopWords.contains(w)).toList();
    
    bool hasValidProductWord = false;
    for (var word in cleanedWords) {
      if (brands.contains(word) || productNames.any((pn) => pn.contains(word) || word.contains(pn))) {
        hasValidProductWord = true;
        break;
      }
    }
    
    if (cleanedWords.isEmpty || !hasValidProductWord) {
      return null;
    }
    
    if (cleanedMessage.length >= 3 && cleanedWords.isNotEmpty) {
      final finalResult = cleanedWords.join(' ');
      return finalResult;
    }

    return null;
  }
  
  static Future<String?> extractProductFromContext(List<ChatMessage> conversationHistory) async {
    if (conversationHistory.isEmpty) return null;
    
    final recentAIMessages = conversationHistory
        .where((msg) => !msg.fromUser)
        .take(5)
        .toList();
    
    final brands = await ProductKnowledgeBase.getBrands();
    final productNames = await ProductKnowledgeBase.getProductNames();
    
    String? foundBrand;
    String? foundProductName;
    
    for (var msg in recentAIMessages) {
      final lowerText = msg.text.toLowerCase();
      
      for (var brand in brands) {
        if (lowerText.contains(brand)) {
          foundBrand = brand;
          break;
        }
      }
      
      for (var pn in productNames) {
        if (lowerText.contains(pn)) {
          foundProductName = pn;
          break;
        }
      }
      
      if (foundBrand != null && foundProductName != null) {
        return '$foundBrand $foundProductName';
      }
      
      if (foundBrand != null) {
        return foundBrand;
      }
      
      if (foundProductName != null) {
        return foundProductName;
      }
    }
    
    return null;
  }
  
  static bool isGenericPhrase(String phrase) {
    final genericPhrases = [
      'giày', 'giày dép', 'sneakers', 'sản phẩm', 'hàng', 
      'đồ', 'món', 'cái', 'đôi', 'một', 'và', 'với', 'cho',
      'những', 'nào', 'đó', 'thế', 'khác', 'khác', 'giày khác'
    ];
    
    final lowerPhrase = phrase.toLowerCase().trim();
    
    final words = lowerPhrase.split(' ').where((w) => w.length > 2).toList();
    if (words.isEmpty) return true;
    
    bool allGeneric = words.every((word) => 
      genericPhrases.any((gp) => word.contains(gp) || gp.contains(word))
    );
    
    return allGeneric;
  }
  
  static Future<bool> isOnlyBrand(String phrase) async {
    final brands = await ProductKnowledgeBase.getBrands();
    final productNames = await ProductKnowledgeBase.getProductNames();
    
    final lowerPhrase = phrase.toLowerCase().trim();
    
    bool hasBrand = brands.any((brand) => lowerPhrase.contains(brand));
    
    bool hasProductName = false;
    for (var pn in productNames) {
      final lowerPn = pn.toLowerCase();
      if (lowerPhrase.contains(lowerPn)) {
        bool isBrand = brands.any((brand) => lowerPn == brand || lowerPn.contains(brand) && lowerPn.length == brand.length);
        if (!isBrand) {
          hasProductName = true;
          break;
        }
      }
    }
    
    final words = lowerPhrase.split(' ').where((w) => w.length > 2).toList();
    if (words.length > 1 && hasBrand) {
      bool hasNonBrandWord = words.any((word) => !brands.contains(word));
      if (hasNonBrandWord) {
        hasProductName = true;
      }
    }
    
    return hasBrand && !hasProductName;
  }
}

class CheckoutIntentDetector {
  static Map<String, dynamic> detectCheckoutIntent(String message) {
    final lowerMessage = message.toLowerCase();
    
    final strongCheckoutKeywords = [
      'thanh toán', 'thanh toan', 'thanh toán',
      'đặt hàng', 'dat hang', 'đặt hàng ngay',
      'checkout', 'hoàn tất đơn hàng', 'hoàn tất',
      'xác nhận đơn hàng', 'xác nhận thanh toán',
      'gửi đơn hàng', 'giao hàng', 'tôi muốn đặt hàng'
    ];
    
    final checkoutKeywords = [
      'mua ngay', 'đặt mua', 'đặt ngay',
      'hoàn thành đơn hàng', 'hoàn thành',
      'tiến hành thanh toán', 'tiến hành đặt hàng',
      'tôi muốn thanh toán', 'muốn thanh toán',
      'cho tôi thanh toán', 'thanh toán giúp tôi'
    ];
    
    bool isStrongCheckout = strongCheckoutKeywords.any((keyword) => 
        lowerMessage.contains(keyword));
    
    bool hasCheckoutKeyword = checkoutKeywords.any((keyword) => 
        lowerMessage.contains(keyword));
    
    int confidence = 0;
    if (isStrongCheckout) confidence += 3;
    if (hasCheckoutKeyword) confidence += 1;
    
    bool isCheckoutIntent = confidence >= 2;
    
    return {
      'isCheckoutIntent': isCheckoutIntent,
      'confidence': confidence,
      'isStrongCheckout': isStrongCheckout,
    };
  }
}

