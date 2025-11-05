import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/utils/gemini_config.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';
import 'package:ecommerce_app/services/system_prompt_builder.dart';
import 'package:ecommerce_app/services/intent_detector.dart';
import 'package:ecommerce_app/services/product_search_service.dart';
import 'package:ecommerce_app/model/chat_message.dart';
import 'package:ecommerce_app/respository/components/address_picker.dart';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  
  bool get isAvailable => GeminiConfig.isConfigured && _model != null;
  
  GeminiService() {
    if (GeminiConfig.isConfigured) {
      try {
        _model = GenerativeModel(
          model: GeminiConfig.model,
          apiKey: GeminiConfig.apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
          ),
        );
        _chatSession = _model!.startChat();
      } catch (e) {
        _model = null;
        _chatSession = null;
      }
    } else {
      _model = null;
      _chatSession = null;
    }
  }
  
  void _resetChatSession() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  Future<String> getOrderDetails(String userId, String orderId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('userId', isEqualTo: userId)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'Không tìm thấy đơn hàng với mã: $orderId';
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      final total = int.tryParse(data['totalPrice']?.toString() ?? data['total']?.toString() ?? '0') ?? 0;

      final itemsDetail = items.map((item) {
        final itemMap = item as Map<String, dynamic>;
        final quantity = itemMap['quantity'] ?? 1;
        final unitPrice = int.tryParse(itemMap['unitPrice']?.toString() ?? '0') ?? 0;
        return '   • ${itemMap['productName'] ?? 'N/A'} - Số lượng: $quantity - Giá: ${Formatter.formatCurrency(unitPrice)}';
      }).join('\n');

      return '''
📦 Đơn hàng #${data['orderId'] ?? 'N/A'}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Trạng thái: ${data['status'] ?? 'N/A'}
📅 Ngày đặt: ${_formatDate(data['timestamp'] ?? data['orderDate'])}
💰 Tổng tiền: ${Formatter.formatCurrency(total)}
📧 Email: ${data['email'] ?? 'N/A'}
📱 Số điện thoại: ${data['phone'] ?? 'N/A'}
📍 Địa chỉ: ${data['address'] ?? 'N/A'}

🛍️ Chi tiết sản phẩm:
$itemsDetail
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ''';
    } catch (e) {
      return 'Lỗi khi lấy thông tin đơn hàng: $e';
    }
  }

  Future<String> getOrdersByStatus(String userId, String status) async {
    try {
      List<QueryDocumentSnapshot> docs;
      if (status.toLowerCase() == 'tất cả' || status.toLowerCase() == 'all') {
        final snapshot = await FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .limit(20)
            .get();
        
        final tempDocs = snapshot.docs.toList();
        tempDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['timestamp'];
          final bTimestamp = bData['timestamp'];
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
            return bTimestamp.compareTo(aTimestamp);
          }
          return 0;
        });
        docs = tempDocs.take(10).toList();
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: status)
            .limit(20)
            .get();
        
        final tempDocs = snapshot.docs.toList();
        tempDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['timestamp'];
          final bTimestamp = bData['timestamp'];
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
            return bTimestamp.compareTo(aTimestamp);
          }
          return 0;
        });
        docs = tempDocs.take(10).toList();
      }

      if (docs.isEmpty) {
        return 'Bạn chưa có đơn hàng nào với trạng thái: $status';
      }

      final ordersList = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        final total = int.tryParse(data['totalPrice']?.toString() ?? data['total']?.toString() ?? '0') ?? 0;
        final itemNames = items.map((item) => (item as Map<String, dynamic>)['productName'] ?? 'N/A').join(', ');
        
        return '''
📦 Đơn hàng #${data['orderId'] ?? 'N/A'}
   📊 Trạng thái: ${data['status'] ?? 'N/A'}
   🛍️ Số lượng: ${items.length} sản phẩm
   💰 Tổng tiền: ${Formatter.formatCurrency(total)}
   📅 Ngày đặt: ${_formatDate(data['timestamp'] ?? data['orderDate'])}
   📝 Sản phẩm: $itemNames
        ''';
      }).join('\n---\n');

      return 'Danh sách đơn hàng:\n$ordersList';
    } catch (e) {
      return 'Lỗi khi lấy thông tin đơn hàng: $e';
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    if (dateValue is Timestamp) {
      return '${dateValue.toDate().day}/${dateValue.toDate().month}/${dateValue.toDate().year}';
    }
    if (dateValue is String) {
      return dateValue;
    }
    return 'N/A';
  }

  Future<String> _buildSystemPrompt(String userId) async {
    return await SystemPromptBuilder.buildSystemPrompt(userId);
  }

  Future<String> addProductToCart(String productId, String productName, String imageLink, double unitPrice, {int quantity = 1, String size = '38', String color = 'Blue'}) async {
    try {
      if (unitPrice <= 0) {
        return '❌ Lỗi: Giá sản phẩm không hợp lệ. Vui lòng thử lại hoặc liên hệ hỗ trợ.';
      }
      
      if (productId.isEmpty || productName.isEmpty) {
        return '❌ Lỗi: Thông tin sản phẩm không đầy đủ. Vui lòng thử lại.';
      }
      
      final cart = PersistentShoppingCart();
      final cartDataBefore = cart.getCartData();
      final cartItemsBefore = cartDataBefore['cartItems'] as List? ?? [];
      
      final cartItem = PersistentShoppingCartItem(
        productThumbnail: imageLink,
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
        quantity: quantity,
        productDetails: {
          "size": size,
          "color": color,
        },
      );
      
      await cart.addToCart(cartItem);
      await Future.delayed(const Duration(milliseconds: 300));
      
      final cartDataAfter = cart.getCartData();
      final cartItemsAfter = cartDataAfter['cartItems'] as List? ?? [];
      
      bool foundInCart = false;
      for (var item in cartItemsAfter) {
        if (item is PersistentShoppingCartItem) {
          if (item.productId == productId) {
            foundInCart = true;
            break;
          }
        } else if (item is Map) {
          final itemProductId = item['productId']?.toString() ?? '';
          if (itemProductId == productId) {
            foundInCart = true;
            break;
          }
        }
      }
      
      final priceFormatted = Formatter.formatCurrency(unitPrice.toInt());
      
      if (foundInCart) {
        return '✅ Đã thêm "$productName" vào giỏ hàng thành công!\n💰 Giá: $priceFormatted\nSố lượng: $quantity\n\nBạn có thể kiểm tra giỏ hàng và tiến hành thanh toán.';
      } else {
        return '⚠️ Đã thử thêm "$productName" vào giỏ hàng, nhưng có thể có vấn đề. Vui lòng kiểm tra giỏ hàng hoặc thử lại.\n\nNếu vẫn không thấy, vui lòng thử thêm từ trang chi tiết sản phẩm.';
      }
    } catch (e, stackTrace) {
      return '❌ Lỗi khi thêm sản phẩm vào giỏ hàng: $e\n\nVui lòng thử lại hoặc liên hệ hỗ trợ.';
    }
  }

  Future<String> sendMessage(
    String userMessage,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      if (_model == null) {
        return '⚠️ Gemini AI chưa được cấu hình. Vui lòng thêm API key vào lib/utils/gemini_config.dart';
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'Vui lòng đăng nhập để sử dụng chatbot.';
      }

      final orderIntent = OrderIntentDetector.detectOrderIntent(userMessage);
      String? additionalContext;
      
      if (orderIntent['isOrderQuery'] == true) {
        if (orderIntent['orderId'] != null) {
          additionalContext = await getOrderDetails(user.uid, orderIntent['orderId'] as String);
        } else if (orderIntent['status'] != null) {
          additionalContext = await getOrdersByStatus(user.uid, orderIntent['status'] as String);
        } else {
          additionalContext = await getOrdersByStatus(user.uid, 'tất cả');
        }
      }

      final checkoutIntent = CheckoutIntentDetector.detectCheckoutIntent(userMessage);
      String? checkoutResult;
      
      if (checkoutIntent['isCheckoutIntent'] == true) {
        final cart = PersistentShoppingCart();
        final cartData = cart.getCartData();
        final cartItems = cartData['cartItems'] as List? ?? [];
        final totalPrice = cartData['totalPrice'] as double? ?? 0.0;
        
        if (cartItems.isEmpty) {
          checkoutResult = '❌ Giỏ hàng của bạn đang trống. Vui lòng thêm sản phẩm vào giỏ hàng trước khi thanh toán.';
        } else {
          final userDoc = await FirebaseFirestore.instance
              .collection('User Data')
              .doc(user.uid)
              .get();
          
          final userData = userDoc.data() ?? {};
          final userName = userData['Full name']?.toString() ?? '';
          final userEmail = userData['Email']?.toString() ?? '';
          final userPhone = userData['phone']?.toString() ?? '';
          String userAddress = '';
          FullAddress? structuredAddress;
          
          if (userData['provinceCode'] != null || userData['provinceName'] != null) {
            structuredAddress = FullAddress.fromMap(userData);
            userAddress = structuredAddress!.fullAddressString;
          } else if (userData['address'] != null && userData['address'].toString().isNotEmpty) {
            userAddress = userData['address'].toString();
            structuredAddress = FullAddress.fromString(userAddress);
          }
          
          final safeAddress = userAddress.replaceAll('|', '||').replaceAll(':', '::');
          checkoutResult = 'CHECKOUT_FORM:$userName|$userEmail|$userPhone|$safeAddress|$totalPrice';
        }
      }
      
      final purchaseIntent = await PurchaseIntentDetector.detectPurchaseIntent(userMessage, conversationHistory);
      String? purchaseResult;
      
      if (purchaseIntent['isPurchaseIntent'] == true) {
        String? productName = await ProductNameExtractor.extractProductName(userMessage);
        
        if ((purchaseIntent['isConfirmationIntent'] == true || 
             purchaseIntent['hasReference'] == true) && 
            (productName == null || productName.isEmpty)) {
          productName = await PurchaseIntentDetector.extractProductFromAIContext(conversationHistory);
          if (productName == null || productName.isEmpty) {
            productName = await ProductNameExtractor.extractProductFromContext(conversationHistory);
          }
        }
        
        if (productName != null && 
            productName.isNotEmpty && 
            productName.length >= 3 &&
            !ProductNameExtractor.isGenericPhrase(productName)) {
          final product = await ProductSearchService.findProductByName(productName);
          
          if (product != null) {
            final productId = product['productId'] as String? ?? product['productId']?.toString() ?? '';
            final name = product['productname'] as String? ?? product['productname']?.toString() ?? 'N/A';
            final imageLink = product['imagelink'] as String? ?? product['imagelink']?.toString() ?? '';
            
            double price = 0.0;
            final priceValue = product['productprice'];
            if (priceValue is int) {
              price = priceValue.toDouble();
            } else if (priceValue is double) {
              price = priceValue;
            } else if (priceValue is String) {
              price = double.tryParse(priceValue) ?? 0.0;
            } else {
              price = double.tryParse(priceValue.toString()) ?? 0.0;
            }
            
            if (price <= 0) {
              purchaseResult = '❌ Lỗi: Không thể xác định giá sản phẩm. Vui lòng thử lại hoặc liên hệ hỗ trợ.';
            } else if (productId.isEmpty) {
              purchaseResult = '❌ Lỗi: Không tìm thấy mã sản phẩm. Vui lòng thử lại.';
            } else {
              purchaseResult = 'PRODUCT_SELECTION:$productId:$name:$imageLink:$price';
            }
          }
        }
      }

      String systemPrompt = await _buildSystemPrompt(user.uid);
      
      if (additionalContext != null) {
        systemPrompt += '\n\n📋 THÔNG TIN ĐƠN HÀNG MỚI NHẤT (được truy vấn TRỰC TIẾP từ database):\n$additionalContext';
        systemPrompt += '\n\n⚠️ LƯU Ý QUAN TRỌNG:';
        systemPrompt += '\n- Thông tin ở trên được query TRỰC TIẾP từ database khi người dùng hỏi về đơn hàng';
        systemPrompt += '\n- LUÔN ƯU TIÊN sử dụng thông tin này thay vì thông tin trong "LỊCH SỬ ĐƠN HÀNG" ở trên';
        systemPrompt += '\n- Nếu có order IDs trong thông tin trên, HÃY HIỂN THỊ CHÚNG RÕ RÀNG trong câu trả lời';
        systemPrompt += '\n- Trả lời dựa trên thông tin MỚI NHẤT này một cách chính xác và chi tiết';
      }

      final modelWithInstruction = GenerativeModel(
        model: GeminiConfig.model,
        apiKey: GeminiConfig.apiKey,
        systemInstruction: Content.text(systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      ChatSession chatSession;
      if (conversationHistory.isEmpty) {
        chatSession = modelWithInstruction.startChat();
      } else {
        final List<Content> history = [];
        for (var msg in conversationHistory) {
          if (msg.fromUser) {
            history.add(Content.text(msg.text));
          } else {
            history.add(Content.model([TextPart(msg.text)]));
          }
        }
        chatSession = modelWithInstruction.startChat(history: history);
      }

      if (checkoutResult != null) {
        return checkoutResult;
      }
      
      if (purchaseResult != null) {
        return purchaseResult;
      }

      final response = await chatSession.sendMessage(
        Content.text(userMessage),
      );
      
      return response.text ?? 'Xin lỗi, tôi không thể tạo phản hồi. Vui lòng thử lại.';
    } catch (e) {
      return 'Lỗi: ${e.toString()}. Vui lòng kiểm tra API key và thử lại.';
    }
  }

  Future<Map<String, String>> extractTicketData(String conversation) async {
    final Map<String, String> ticketData = {
      'issueType': 'Other',
      'detail': 'AI Chat Conversation',
      'description': conversation,
    };

    final lowerConversation = conversation.toLowerCase();
    
    if (lowerConversation.contains('order') || lowerConversation.contains('đơn hàng')) {
      ticketData['issueType'] = 'Order Issues';
    } else if (lowerConversation.contains('quality') || 
               lowerConversation.contains('chất lượng') ||
               lowerConversation.contains('damaged') ||
               lowerConversation.contains('hỏng')) {
      ticketData['issueType'] = 'Item Quality';
    } else if (lowerConversation.contains('payment') || 
               lowerConversation.contains('thanh toán')) {
      ticketData['issueType'] = 'Payment Issues';
    } else if (lowerConversation.contains('suggestion') || 
               lowerConversation.contains('gợi ý')) {
      ticketData['issueType'] = 'Style Suggestion';
    }

    return ticketData;
  }

  bool shouldCreateTicket(String aiResponse) {
    final lowerResponse = aiResponse.toLowerCase();
    return lowerResponse.contains('ticket') || 
           lowerResponse.contains('support ticket') ||
           lowerResponse.contains('tạo ticket') ||
           lowerResponse.contains('yêu cầu hỗ trợ');
  }
}

