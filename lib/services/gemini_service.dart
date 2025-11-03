import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/utils/gemini_config.dart';

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

  /// Lấy context về user orders
  Future<String> _getUserOrdersContext(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'Khách hàng chưa có đơn hàng nào.';
      }

      final ordersList = snapshot.docs.map((doc) {
        final data = doc.data();
        final items = data['items'] as List?;
        final itemNames = items?.map((item) => item['productName'] ?? 'N/A').join(', ') ?? 'N/A';
        final total = int.tryParse(data['total']?.toString() ?? '0') ?? 0;
        final totalFormatted = (total / 1000000).toStringAsFixed(1);
        
        return '''
📦 Đơn hàng #${data['orderId'] ?? 'N/A'}
   📊 Trạng thái: ${data['status'] ?? 'N/A'}
   🛍️ Số lượng: ${items?.length ?? 0} sản phẩm
   💰 Tổng tiền: ${totalFormatted} triệu VND
   📅 Ngày đặt: ${data['orderDate'] ?? 'N/A'}
   📝 Sản phẩm: $itemNames
        ''';
      }).join('\n---\n');

      return 'Các đơn hàng gần đây:\n$ordersList';
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

      final data = doc.data()!;
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
        final data = doc.data();
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
- Nếu khách hỏi về sản phẩm không có trong danh sách, gợi ý sản phẩm tương tự
- Khi khách muốn tạo ticket hỗ trợ, hướng dẫn chuyển sang chế độ Form
- Giữ câu trả lời ngắn gọn, dễ hiểu, tránh dài dòng

Hãy thể hiện bạn là một chuyên gia giày sneakers thực thụ, luôn sẵn sàng giúp khách hàng tìm được đôi giày hoàn hảo! 👟✨''';
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

      // Build system prompt with context
      final systemPrompt = await _buildSystemPrompt(user.uid);

      // Tạo model mới với system instruction cho mỗi conversation
      // Điều này đảm bảo system prompt được áp dụng đúng cách
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
        // Build history với format đúng: alternate user/model messages
        final List<Content> history = [];
        for (var msg in conversationHistory) {
          if (msg.fromUser) {
            history.add(Content.text(msg.text));
          } else {
            // Model response - cần format đúng
            history.add(Content.model([TextPart(msg.text)]));
          }
        }
        chatSession = modelWithInstruction.startChat(history: history);
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

