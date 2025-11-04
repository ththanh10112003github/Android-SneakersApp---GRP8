import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/utils/gemini_config.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

// Chat message model for Gemini service
class ChatMessage {
  final String text;
  final bool fromUser;
  ChatMessage({required this.text, required this.fromUser});
}

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  
  bool get isAvailable => GeminiConfig.isConfigured && _model != null;
  
  GeminiService() {
    print('🔧 Initializing GeminiService...');
    print('  isConfigured: ${GeminiConfig.isConfigured}');
    print('  API Key configured: ${GeminiConfig.apiKey.isNotEmpty}');
    
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
        print('✅ GeminiService initialized successfully');
      } catch (e) {
        print('❌ Error initializing GeminiService: $e');
        _model = null;
        _chatSession = null;
      }
    } else {
      print('⚠️ Gemini API key not configured');
      _model = null;
      _chatSession = null;
    }
  }
  
  void _resetChatSession() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  /// Lấy thông tin đơn hàng cụ thể theo orderId
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

  /// Lấy danh sách đơn hàng theo trạng thái
  Future<String> getOrdersByStatus(String userId, String status) async {
    try {
      QuerySnapshot snapshot;
      if (status.toLowerCase() == 'tất cả' || status.toLowerCase() == 'all') {
        snapshot = await FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: status)
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        return 'Bạn chưa có đơn hàng nào với trạng thái: $status';
      }

      final ordersList = snapshot.docs.map((doc) {
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

  /// Format date helper
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

  /// Lấy context về user orders (cải thiện với thông tin chi tiết hơn)
  Future<String> _getUserOrdersContext(String userId) async {
    try {
      // Thử orderBy timestamp trước, nếu không được thì dùng orderDate
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();
      } catch (e) {
        // Fallback nếu không có index cho timestamp
        snapshot = await FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .limit(5)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        return 'Khách hàng chưa có đơn hàng nào.';
      }

      final ordersList = snapshot.docs.map((doc) {
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
   📍 Địa chỉ: ${data['address'] ?? 'N/A'}
        ''';
      }).join('\n---\n');

      return 'Các đơn hàng gần đây của khách hàng:\n$ordersList';
    } catch (e) {
      return 'Lỗi khi lấy thông tin đơn hàng: $e';
    }
  }

  /// Lấy thông tin user profile
  Future<String> _getUserProfileContext(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('User Data')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return 'Không tìm thấy thông tin khách hàng.';
      }

      final data = doc.data()! as Map<String, dynamic>;
      return '''
Thông tin khách hàng:
👤 Tên: ${data['Full name'] ?? 'N/A'}
📧 Email: ${data['Email'] ?? 'N/A'}
📱 Số điện thoại: ${data['Phone'] ?? 'N/A'}
      ''';
    } catch (e) {
      return 'Lỗi khi lấy thông tin khách hàng: $e';
    }
  }

  /// Lấy danh sách products có sẵn trong app
  Future<String> _getProductsContext() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'Hiện tại không có sản phẩm nào trong kho.';
      }

      final productsList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final price = int.tryParse(data['productprice']?.toString() ?? '0') ?? 0;
        final priceFormatted = (price / 1000000).toStringAsFixed(1);
        return '''
📦 ${data['productname'] ?? 'N/A'} (${data['brandId'] ?? 'N/A'})
   💰 Giá: ${priceFormatted} triệu VND
   🏷️ Danh mục: ${data['title'] ?? 'N/A'}
   📝 ${data['description'] ?? 'N/A'}
        ''';
      }).join('\n');

      return 'Sản phẩm có sẵn trong cửa hàng:\n$productsList';
    } catch (e) {
      return 'Lỗi khi lấy danh sách sản phẩm: $e';
    }
  }

  /// Build system prompt với context
  Future<String> _buildSystemPrompt(String userId) async {
    final userProfile = await _getUserProfileContext(userId);
    final userOrders = await _getUserOrdersContext(userId);
    final productsInfo = await _getProductsContext();

    return '''Bạn là một CHUYÊN GIA TƯ VẤN GIÀY SNEAKERS chuyên nghiệp và nhiệt tình cho ứng dụng mua bán giày sneakers này.

🎯 VAI TRÒ CỦA BẠN:
Bạn không chỉ là chatbot hỗ trợ khách hàng, mà còn là một chuyên gia tư vấn giày với kiến thức sâu rộng về:
- Các thương hiệu giày sneakers: Nike, Adidas, Puma, Converse, Under Armour, Reebok
- Phong cách và xu hướng giày: Classic, Running, Street Style, Retro, Chunky, Iconic
- Tư vấn chọn size, fit, và style phù hợp với nhu cầu của khách hàng
- Đặc điểm, công nghệ và chất liệu của từng dòng sản phẩm
- Giá cả và giá trị của các sản phẩm

📚 KIẾN THỨC CHUYÊN MÔN:
1. **Nike**: Nổi tiếng với Air Force 1, Dunk, Pegasus - công nghệ Air cushioning, phong cách streetwear và sport
2. **Adidas**: Đặc trưng với Ultraboost (Boost technology), Stan Smith (classic), NMD (street style)
3. **Puma**: Thương hiệu Đức, nổi tiếng với RS-X, Suede Classic - phong cách retro và casual
4. **Converse**: Biểu tượng Chuck Taylor, Run Star Hike - phong cách cổ điển và chunky
5. **Under Armour**: Thương hiệu thể thao, nổi tiếng với Curry series và HOVR technology

💡 NHIỆM VỤ:
1. **Tư vấn sản phẩm**: Giúp khách hàng chọn giày phù hợp dựa trên:
   - Mục đích sử dụng (chạy bộ, đi chơi, thể thao, streetwear)
   - Phong cách cá nhân (classic, modern, retro, chunky)
   - Budget và giá trị sản phẩm
   - Size và fit

2. **Tư vấn về orders**: 
   - Kiểm tra trạng thái đơn hàng
   - Hướng dẫn tracking
   - Giải đáp thắc mắc về shipping

3. **Hỗ trợ kỹ thuật**:
   - Thanh toán và giao dịch
   - Đổi trả và hoàn tiền
   - Vấn đề về sản phẩm

4. **Chăm sóc khách hàng**:
   - Thân thiện, nhiệt tình, chuyên nghiệp
   - Sử dụng tiếng Việt tự nhiên
   - Nếu không giải quyết được, hướng dẫn tạo support ticket

🎨 PHONG CÁCH GIAO TIẾP:
- Thân thiện như một người bạn am hiểu về giày
- Nhiệt tình tư vấn, không ép buộc mua hàng
- Chuyên nghiệp nhưng không cứng nhắc
- Sử dụng emoji hợp lý để tạo sự gần gũi (👍, 👟, ✨, 💯)
- Trả lời ngắn gọn nhưng đầy đủ thông tin

📋 THÔNG TIN KHÁCH HÀNG:
$userProfile

📦 LỊCH SỬ ĐƠN HÀNG:
$userOrders

🛍️ SẢN PHẨM CÓ SẴN:
$productsInfo

⚠️ QUAN TRỌNG:
- LUÔN trả lời bằng tiếng Việt
- Sử dụng thông tin về products và orders ở trên để tư vấn chính xác
- Khi khách hỏi về đơn hàng cụ thể (có mã đơn hàng), hệ thống sẽ tự động truy vấn thông tin chi tiết
- Khi khách hỏi về trạng thái đơn hàng (pending, shipping, delivered, cancelled), hệ thống sẽ tự động lọc theo trạng thái
- Nếu khách hỏi về sản phẩm không có trong danh sách, gợi ý sản phẩm tương tự
- Khi khách muốn tạo ticket hỗ trợ, hướng dẫn chuyển sang chế độ Form
- Giữ câu trả lời ngắn gọn, dễ hiểu, tránh dài dòng
- Khi có thông tin bổ sung từ truy vấn tự động, ƯU TIÊN sử dụng thông tin đó để trả lời

🔍 KHẢ NĂNG ĐẶC BIỆT:
- Có thể trả lời về đơn hàng cụ thể nếu khách cung cấp mã đơn hàng
- Có thể lọc và hiển thị đơn hàng theo trạng thái khi khách yêu cầu
- Tự động cập nhật thông tin đơn hàng mới nhất từ database
- **CÓ THỂ ĐẶT HÀNG**: Khi khách hàng muốn mua sản phẩm (ví dụ: "Mua Nike Air Force 1", "Tôi muốn mua Adidas Ultraboost", "Thêm vào giỏ hàng Nike Dunk"), hệ thống sẽ TỰ ĐỘNG tìm sản phẩm và thêm vào giỏ hàng. Sau đó trả về thông báo xác nhận.

🛒 HƯỚNG DẪN ĐẶT HÀNG:
- Khi khách hàng muốn mua sản phẩm, hãy khuyến khích họ nói rõ tên sản phẩm
- Sau khi hệ thống thêm vào giỏ hàng thành công, hãy nhắc khách hàng kiểm tra giỏ hàng và tiến hành thanh toán
- Nếu không tìm thấy sản phẩm, hãy gợi ý các sản phẩm tương tự có sẵn

Hãy thể hiện bạn là một chuyên gia giày sneakers thực thụ, luôn sẵn sàng giúp khách hàng tìm được đôi giày hoàn hảo! 👟✨''';
  }

  /// Detect và extract orderId từ user message
  String? _extractOrderId(String message) {
    // Pattern: số dài (orderId thường là timestamp hoặc số)
    final regex = RegExp(r'(?:đơn hàng|order|mã đơn|orderid|order id)[\s#:]*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(message);
    if (match != null) {
      return match.group(1);
    }
    
    // Pattern: chỉ số dài (10-15 chữ số)
    final numberRegex = RegExp(r'\b\d{10,15}\b');
    final numberMatch = numberRegex.firstMatch(message);
    return numberMatch?.group(0);
  }

  /// Detect intent về đơn hàng
  Map<String, dynamic> _detectOrderIntent(String message) {
    final lowerMessage = message.toLowerCase();
    final orderId = _extractOrderId(message);
    
    // Detect status query
    String? status;
    if (lowerMessage.contains('đang xử lý') || lowerMessage.contains('pending')) {
      status = 'pending';
    } else if (lowerMessage.contains('đã giao') || lowerMessage.contains('delivered') || lowerMessage.contains('completed')) {
      status = 'delivered';
    } else if (lowerMessage.contains('đang giao') || lowerMessage.contains('shipping')) {
      status = 'shipping';
    } else if (lowerMessage.contains('đã hủy') || lowerMessage.contains('cancelled')) {
      status = 'cancelled';
    } else if (lowerMessage.contains('tất cả') || lowerMessage.contains('all orders')) {
      status = 'tất cả';
    }
    
    return {
      'isOrderQuery': lowerMessage.contains('đơn hàng') || 
                      lowerMessage.contains('order') ||
                      orderId != null ||
                      status != null,
      'orderId': orderId,
      'status': status,
    };
  }

  /// Detect intent đặt hàng (mua hàng, thêm vào giỏ)
  Map<String, dynamic> _detectPurchaseIntent(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Keywords cho đặt hàng
    final purchaseKeywords = [
      'mua', 'đặt mua', 'muốn mua', 'cho tôi', 'tôi muốn mua',
      'thêm vào giỏ', 'thêm giỏ hàng', 'add to cart', 'buy',
      'đặt hàng', 'tôi cần', 'cần mua', 'mua giúp', 'đặt cho tôi'
    ];
    
    bool isPurchaseIntent = purchaseKeywords.any((keyword) => lowerMessage.contains(keyword));
    
    return {
      'isPurchaseIntent': isPurchaseIntent,
    };
  }

  /// Tìm sản phẩm theo tên (fuzzy search)
  Future<Map<String, dynamic>?> _findProductByName(String productName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final lowerProductName = productName.toLowerCase().trim();
      
      // Tìm exact match trước
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['productname'] ?? '').toString().toLowerCase();
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

      // Tìm partial match
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['productname'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        
        // Kiểm tra nếu tên hoặc mô tả chứa từ khóa
        if (name.contains(lowerProductName) || 
            description.contains(lowerProductName) ||
            lowerProductName.split(' ').any((word) => name.contains(word) && word.length > 2)) {
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
      print('Lỗi khi tìm sản phẩm: $e');
      return null;
    }
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<String> addProductToCart(String productId, String productName, String imageLink, double unitPrice, {int quantity = 1, String size = '38', String color = 'Blue'}) async {
    try {
      final cart = PersistentShoppingCart();
      
      await cart.addToCart(
        PersistentShoppingCartItem(
          productThumbnail: imageLink,
          productId: productId,
          productName: productName,
          unitPrice: unitPrice,
          quantity: quantity,
          productDetails: {
            "size": size,
            "color": color,
          },
        ),
      );

      final priceFormatted = Formatter.formatCurrency(unitPrice.toInt());
      return '✅ Đã thêm "$productName" vào giỏ hàng thành công!\n💰 Giá: $priceFormatted\nSố lượng: $quantity\n\nBạn có thể kiểm tra giỏ hàng và tiến hành thanh toán.';
    } catch (e) {
      return '❌ Lỗi khi thêm sản phẩm vào giỏ hàng: $e';
    }
  }

  /// Extract tên sản phẩm từ message
  String? _extractProductName(String message) {
    // Loại bỏ các từ khóa đặt hàng
    final purchaseKeywords = [
      'mua', 'đặt mua', 'muốn mua', 'cho tôi', 'tôi muốn mua',
      'thêm vào giỏ', 'thêm giỏ hàng', 'add to cart', 'buy',
      'đặt hàng', 'tôi cần', 'cần mua', 'mua giúp', 'đặt cho tôi',
      'giúp tôi mua', 'hãy mua', 'làm ơn mua'
    ];

    String cleanedMessage = message;
    for (var keyword in purchaseKeywords) {
      cleanedMessage = cleanedMessage.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }

    // Loại bỏ các từ dừng
    final stopWords = ['với', 'một', 'cái', 'đôi', 'của', 'cho', 'giúp', 'tôi'];
    for (var word in stopWords) {
      cleanedMessage = cleanedMessage.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }

    return cleanedMessage.trim().isEmpty ? null : cleanedMessage.trim();
  }

  /// Gửi message đến Gemini và nhận response
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

      // Detect intent về đơn hàng và tự động query nếu cần
      final orderIntent = _detectOrderIntent(userMessage);
      String? additionalContext;
      
      if (orderIntent['isOrderQuery'] == true) {
        if (orderIntent['orderId'] != null) {
          // Query đơn hàng cụ thể
          additionalContext = await getOrderDetails(user.uid, orderIntent['orderId'] as String);
        } else if (orderIntent['status'] != null) {
          // Query đơn hàng theo trạng thái
          additionalContext = await getOrdersByStatus(user.uid, orderIntent['status'] as String);
        }
      }

      // Detect intent đặt hàng (mua sản phẩm)
      final purchaseIntent = _detectPurchaseIntent(userMessage);
      String? purchaseResult;
      
      if (purchaseIntent['isPurchaseIntent'] == true) {
        // Extract tên sản phẩm từ message
        final productName = _extractProductName(userMessage);
        
        if (productName != null && productName.isNotEmpty) {
          // Tìm sản phẩm trong database
          final product = await _findProductByName(productName);
          
          if (product != null) {
            // Thêm sản phẩm vào giỏ hàng
            final productId = product['productId'] as String;
            final name = product['productname'] as String;
            final imageLink = product['imagelink'] as String;
            final price = double.tryParse(product['productprice'].toString()) ?? 0.0;
            
            purchaseResult = await addProductToCart(productId, name, imageLink, price);
          } else {
            purchaseResult = '❌ Không tìm thấy sản phẩm "$productName". Bạn có thể hỏi tôi về các sản phẩm có sẵn trong cửa hàng.';
          }
        } else {
          purchaseResult = '⚠️ Tôi không thể xác định sản phẩm bạn muốn mua. Vui lòng cho tôi biết tên sản phẩm cụ thể, ví dụ: "Mua Nike Air Force 1" hoặc "Tôi muốn mua Adidas Ultraboost".';
        }
      }

      // Build system prompt with context
      String systemPrompt = await _buildSystemPrompt(user.uid);
      
      // Thêm additional context nếu có
      if (additionalContext != null) {
        systemPrompt += '\n\n📋 THÔNG TIN BỔ SUNG (được truy vấn tự động):\n$additionalContext';
        systemPrompt += '\n\n⚠️ LƯU Ý: Sử dụng thông tin bổ sung ở trên để trả lời câu hỏi của khách hàng một cách chính xác nhất.';
      }

      // Tạo model mới với system instruction cho mỗi conversation
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

      // Tạo chat session mới hoặc tiếp tục conversation hiện tại
      ChatSession chatSession;
      if (conversationHistory.isEmpty) {
        // Bắt đầu conversation mới
        chatSession = modelWithInstruction.startChat();
      } else {
        // Tiếp tục conversation với history
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

      // Nếu có kết quả đặt hàng, trả về trực tiếp
      if (purchaseResult != null) {
        return purchaseResult;
      }

      // Send user message
      final response = await chatSession.sendMessage(
        Content.text(userMessage),
      );
      
      return response.text ?? 'Xin lỗi, tôi không thể tạo phản hồi. Vui lòng thử lại.';
    } catch (e) {
      return 'Lỗi: ${e.toString()}. Vui lòng kiểm tra API key và thử lại.';
    }
  }

  /// Extract structured data từ AI response để tạo ticket
  Future<Map<String, String>> extractTicketData(String conversation) async {
    // Phân tích conversation để extract issue type, detail, description
    // Đây là một basic implementation, có thể cải thiện với AI parsing
    
    final Map<String, String> ticketData = {
      'issueType': 'Other',
      'detail': 'AI Chat Conversation',
      'description': conversation,
    };

    // Basic keyword detection
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

  /// Kiểm tra xem AI có nên tạo ticket tự động không
  bool shouldCreateTicket(String aiResponse) {
    final lowerResponse = aiResponse.toLowerCase();
    return lowerResponse.contains('ticket') || 
           lowerResponse.contains('support ticket') ||
           lowerResponse.contains('tạo ticket') ||
           lowerResponse.contains('yêu cầu hỗ trợ');
  }
}

