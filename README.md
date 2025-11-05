# Ứng Dụng Bán Giày Sneakers - Android App

## Giới Thiệu

Ứng dụng di động bán giày sneakers được phát triển bằng Flutter/Dart cho nền tảng Android. Ứng dụng cung cấp một nền tảng thương mại điện tử hoàn chỉnh với tính năng AI Chat Bot thông minh, cho phép người dùng tương tác tự nhiên để tìm kiếm sản phẩm, đặt hàng và nhận hỗ trợ khách hàng.

---

## Cấu Trúc Project và Công Nghệ Chính

### 1. Cấu Trúc Thư Mục

```
lib/
├── main.dart                    # Entry point của ứng dụng
├── firebase_options.dart        # Cấu hình Firebase
├── model/                       # Các model dữ liệu
│   ├── chat_message.dart
│   ├── checkout_form_state.dart
│   ├── item_model.dart
│   ├── product_list.dart
│   ├── product_selection_state.dart
│   └── user_model.dart
├── respository/                 # Các component và repository
│   ├── app_bar.dart
│   └── components/
│       ├── address_picker.dart
│       ├── app_styles.dart
│       ├── brand_list.dart
│       ├── product_container.dart
│       ├── route_names.dart
│       ├── routes.dart
│       └── round_button.dart
├── services/                    # Các service chính (QUAN TRỌNG)
│   ├── gemini_service.dart      # Service xử lý AI Chat Bot
│   ├── intent_detector.dart     # Phát hiện ý định người dùng
│   ├── product_knowledge_base.dart
│   ├── product_search_service.dart
│   ├── system_prompt_builder.dart # Xây dựng prompt cho AI
│   └── vietnam_address_service.dart
├── utils/                       # Các tiện ích
│   ├── chat_utils.dart
│   ├── fav_provider.dart
│   ├── formatter.dart
│   ├── gemini_config.dart       # Cấu hình Gemini API
│   └── general_utils.dart
└── view/                        # Các màn hình UI
    ├── admin/                   # Màn hình quản trị
    ├── auth/                    # Màn hình đăng nhập/đăng ký
    ├── home/                    # Màn hình chính
    │   ├── chat_bot_screen.dart  # Màn hình AI Chat Bot
    │   ├── home_screen.dart
    │   ├── cart_screen.dart
    │   ├── checkout_screen.dart
    │   └── ...
    └── splash_screen/           # Màn hình khởi động
```

### 2. Công Nghệ Chính

#### Backend & Database
- **Firebase Core**: Nền tảng backend chính
- **Cloud Firestore**: Database NoSQL cho sản phẩm, đơn hàng, người dùng
- **Firebase Authentication**: Xác thực người dùng
- **Firebase Storage**: Lưu trữ hình ảnh sản phẩm
- **Firebase Realtime Database**: Cập nhật dữ liệu real-time

#### AI & Machine Learning
- **Google Gemini API** (`google_generative_ai` package): Công nghệ AI chính cho Chat Bot
- **Model**: `gemini-2.0-flash` - Model mới nhất của Google Gemini

#### UI & State Management
- **Flutter SDK**: Framework phát triển ứng dụng
- **Provider**: Quản lý state
- **Persistent Shopping Cart**: Quản lý giỏ hàng

#### Dependencies Khác
- `http`, `dio`: Xử lý HTTP requests
- `flutter_svg`: Hiển thị SVG
- `flutter_markdown`: Hiển thị nội dung markdown trong chat
- `intl`: Format số và ngày tháng
- `image_picker`: Chọn ảnh từ thiết bị

### 3. Luồng Hoạt Động Chính của Ứng Dụng

```
1. Màn hình Khởi động (Splash Screen)
   |
   v
2. Màn hình Đăng nhập/Đăng ký (Auth)
   |
   v
3. Trang chủ (Home Screen)
   - Xem danh sách sản phẩm
   - Tìm kiếm theo thương hiệu
   - Xem chi tiết sản phẩm
   - Thêm vào giỏ hàng
   |
   v
4. Giỏ hàng (Cart Screen)
   - Xem sản phẩm đã chọn
   - Cập nhật số lượng
   - Thanh toán
   |
   v
5. Thanh toán (Checkout Screen)
   - Nhập thông tin giao hàng
   - Xác nhận đơn hàng
   |
   v
6. Lịch sử đơn hàng (Order History)
   - Theo dõi trạng thái đơn hàng
```

---

## Hướng Dẫn Sử Dụng (Demo)

### Cài Đặt và Chạy Ứng Dụng

1. **Cài đặt Flutter SDK**
   ```bash
   flutter --version  # Kiểm tra Flutter đã được cài đặt
   ```

2. **Cài đặt Dependencies**
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase**
   - File `android/app/google-services.json` đã được cung cấp
   - Đảm bảo Firebase project đã được setup đúng

4. **Cấu hình Gemini API Key**
   - Mở file `lib/utils/gemini_config.dart`
   - Thay thế `apiKey` bằng API key của bạn từ [Google AI Studio](https://aistudio.google.com/app/apikey)

5. **Chạy ứng dụng**
   ```bash
   flutter run
   ```

### Các Tính Năng Chính

#### 1. Đăng Ký/Đăng Nhập
- Tạo tài khoản mới hoặc đăng nhập với email/password
- Xác thực qua Firebase Authentication

#### 2. Xem Sản Phẩm
- Duyệt danh sách giày sneakers từ các thương hiệu: Nike, Adidas, Puma, Converse, Under Armour
- Xem chi tiết sản phẩm: hình ảnh, giá, mô tả
- Lọc sản phẩm theo thương hiệu

#### 3. Giỏ Hàng và Thanh Toán
- Thêm sản phẩm vào giỏ hàng
- Chọn size và màu sắc
- Xem tổng tiền và thanh toán
- Nhập thông tin giao hàng

#### 4. Theo Dõi Đơn Hàng
- Xem lịch sử đơn hàng
- Kiểm tra trạng thái: pending, shipping, delivered

#### 5. AI Chat Bot (Tính năng đặc biệt)
- Xem phần "GIẢI THÍCH CHUYÊN SÂU TÍNH NĂNG AI CHAT BOT" bên dưới

---

## GIẢI THÍCH CHUYÊN SÂU TÍNH NĂNG AI CHAT BOT

### 1. Công Nghệ AI

#### Google Gemini API
Ứng dụng sử dụng **Google Gemini API** - một trong những công nghệ AI tiên tiến nhất hiện nay của Google. Gemini là một mô hình ngôn ngữ lớn (LLM) được thiết kế để hiểu và tạo ra văn bản tự nhiên, phù hợp cho các ứng dụng chatbot.

**Thông số kỹ thuật:**
- **Model**: `gemini-2.0-flash` - Model mới nhất, tối ưu cho tốc độ và hiệu suất
- **Package**: `google_generative_ai: ^0.4.5`
- **API Endpoint**: Gọi thông qua SDK chính thức của Google

**Cấu hình:**
```dart
// lib/utils/gemini_config.dart
class GeminiConfig {
  static const String apiKey = 'YOUR_API_KEY';
  static const String model = 'gemini-2.0-flash';
}
```

**Generation Config:**
- `temperature: 0.7` - Độ sáng tạo của phản hồi (0-1)
- `topK: 40` - Giới hạn số lượng từ khóa được xem xét
- `topP: 0.95` - Nucleus sampling
- `maxOutputTokens: 1024` - Giới hạn độ dài phản hồi

### 2. Vị Trí Code và Cấu Trúc

#### Các File Chính Liên Quan Đến AI Chat Bot

**1. Màn hình Chat Bot (`lib/view/home/chat_bot_screen.dart`)**
- **Vai trò**: UI chính cho người dùng tương tác với AI
- **Chức năng**:
  - Hiển thị danh sách tin nhắn (chat history)
  - Input field cho người dùng nhập câu hỏi
  - Xử lý phản hồi từ AI và hiển thị
  - Xử lý các trạng thái đặc biệt (product selection, checkout form)

**2. Service AI (`lib/services/gemini_service.dart`)**
- **Vai trò**: Lớp trung gian xử lý tất cả logic AI
- **Chức năng chính**:
  - Khởi tạo và quản lý GenerativeModel
  - Gửi message đến Gemini API
  - Xử lý conversation history
  - Tích hợp với Firebase để lấy thông tin người dùng và đơn hàng
  - Phát hiện intent và xử lý các hành động đặc biệt (mua hàng, thanh toán)

**3. Intent Detector (`lib/services/intent_detector.dart`)**
- **Vai trò**: Phân tích ý định người dùng từ câu hỏi
- **Các class chính**:
  - `OrderIntentDetector`: Phát hiện khi người dùng hỏi về đơn hàng
  - `PurchaseIntentDetector`: Phát hiện khi người dùng muốn mua hàng
  - `ProductNameExtractor`: Trích xuất tên sản phẩm từ câu hỏi
  - `CheckoutIntentDetector`: Phát hiện khi người dùng muốn thanh toán

**4. System Prompt Builder (`lib/services/system_prompt_builder.dart`)**
- **Vai trò**: Xây dựng system prompt cho AI với context đầy đủ
- **Chức năng**:
  - Lấy thông tin người dùng từ Firebase
  - Lấy lịch sử đơn hàng
  - Lấy danh sách sản phẩm
  - Tạo prompt chuyên nghiệp cho AI về vai trò tư vấn giày sneakers

**5. Product Search Service (`lib/services/product_search_service.dart`)**
- **Vai trò**: Tìm kiếm sản phẩm trong database
- **Chức năng**: Tìm sản phẩm theo tên, hỗ trợ fuzzy matching

**6. Product Knowledge Base (`lib/services/product_knowledge_base.dart`)**
- **Vai trò**: Quản lý kiến thức về sản phẩm
- **Chức năng**: Cache danh sách brands và product names từ Firestore

### 3. Luồng Dữ Liệu (Data Flow)

#### Luồng Hoạt Động Chi Tiết

```
1. Người dùng nhập câu hỏi trong ChatScreen
   |
   v
2. _ChatScreenState._sendAIMessage()
   - Lấy userMessage từ TextField
   - Tạo chatHistory từ messages gần đây (10 tin nhắn)
   |
   v
3. GeminiService.sendMessage()
   a. Phát hiện Intent (Intent Detection)
      - OrderIntentDetector: Hỏi về đơn hàng?
      - PurchaseIntentDetector: Muốn mua hàng?
      - CheckoutIntentDetector: Muốn thanh toán?
   
   b. Xử lý Intent đặc biệt
      - Nếu là Order Query:
        -> Query Firestore lấy thông tin đơn hàng
      - Nếu là Purchase Intent:
        -> Extract product name từ message
        -> ProductSearchService.findProductByName()
        -> Trả về PRODUCT_SELECTION:...
      - Nếu là Checkout Intent:
        -> Trả về CHECKOUT_FORM:...
   
   c. Xây dựng System Prompt
      -> SystemPromptBuilder.buildSystemPrompt()
          - getUserProfileContext()
          - getUserOrdersContext()
          - getProductsContext()
   
   d. Tạo GenerativeModel với System Prompt
      -> GenerativeModel(
            systemInstruction: systemPrompt,
            generationConfig: {...}
          )
   
   e. Tạo ChatSession với conversation history
      -> model.startChat(history: [...])
   
   f. Gửi message đến Gemini API
      -> chatSession.sendMessage(Content.text(userMessage))
   |
   v
4. Nhận Response từ Gemini API
   - Response là một String chứa phản hồi của AI
   - Hoặc là các special response:
     * PRODUCT_SELECTION:productId:name:image:price
     * CHECKOUT_FORM:name|email|phone|address|total
   |
   v
5. Xử lý Response trong ChatScreen
   - Nếu là PRODUCT_SELECTION:
     -> _handleProductSelection()
         - Hiển thị UI chọn size
         - Hiển thị UI chọn màu
         - Xác nhận và thêm vào giỏ hàng
   - Nếu là CHECKOUT_FORM:
     -> _handleCheckoutForm()
         - Hiển thị form thanh toán
   - Nếu là text response thông thường:
     -> addBotMessage(response)
         - Hiển thị trong chat với Markdown
```

#### Ví Dụ Code: Gửi Message đến AI

```160:229:lib/view/home/chat_bot_screen.dart
  Future<void> _sendAIMessage() async {
    final userMessage = _aiMessageController.text.trim();
    if (userMessage.isEmpty || _isLoadingAIResponse) return;
    
    if (_productSelection != null) {
      if (_productSelection!.isReadyToConfirm) {
        final lowerMessage = userMessage.toLowerCase().trim();
        if (lowerMessage.contains('có') || lowerMessage.contains('yes') || 
            lowerMessage.contains('đồng ý') || lowerMessage.contains('ok') ||
            lowerMessage.contains('thêm') || lowerMessage.contains('mua')) {
          addUserMessage(userMessage);
          _addProductToCartFromSelection();
        } else if (lowerMessage.contains('không') || lowerMessage.contains('no') || 
                   lowerMessage.contains('hủy')) {
          addUserMessage(userMessage);
          addBotMessage('Đã hủy việc thêm sản phẩm vào giỏ hàng.');
          setState(() {
            _productSelection = null;
          });
        } else {
          addUserMessage(userMessage);
          addBotMessage('Vui lòng trả lời "có" hoặc "không" để xác nhận thêm sản phẩm vào giỏ hàng.');
        }
        return;
      }
      
      _handleProductSelectionResponse(userMessage);
      return;
    }
    
    addUserMessage(userMessage);
    _aiMessageController.clear();
    _isLoadingAIResponse = true;
    
    try {
      final recentMessages = messages.length > 10 
          ? messages.sublist(messages.length - 10)
          : messages;
      
      final chatHistory = recentMessages
          .map((msg) => ChatMessage(
                text: msg.text,
                fromUser: msg.fromUser,
              ))
          .toList();
      
      final aiResponse = await _geminiService.sendMessage(userMessage, chatHistory);
      
      setState(() {
        _isLoadingAIResponse = false;
        
        if (aiResponse.startsWith('CHECKOUT_FORM:')) {
          _handleCheckoutForm(aiResponse);
        } else if (aiResponse.startsWith('PRODUCT_SELECTION:')) {
          _handleProductSelection(aiResponse);
        } else {
          addBotMessage(aiResponse);
          
          if (_geminiService.shouldCreateTicket(aiResponse)) {
            _showCreateTicketDialog(userMessage);
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingAIResponse = false;
        addBotMessage('Xin lỗi, đã xảy ra lỗi: $e');
      });
    }
  }
```

#### Ví Dụ Code: Xử lý trong GeminiService

```245:412:lib/services/gemini_service.dart
  Future<String> sendMessage(
    String userMessage,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      if (_model == null) {
        return 'Gemini AI chưa được cấu hình. Vui lòng thêm API key vào lib/utils/gemini_config.dart';
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
          checkoutResult = 'Giỏ hàng của bạn đang trống. Vui lòng thêm sản phẩm vào giỏ hàng trước khi thanh toán.';
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
              purchaseResult = 'Lỗi: Không thể xác định giá sản phẩm. Vui lòng thử lại hoặc liên hệ hỗ trợ.';
            } else if (productId.isEmpty) {
              purchaseResult = 'Lỗi: Không tìm thấy mã sản phẩm. Vui lòng thử lại.';
            } else {
              purchaseResult = 'PRODUCT_SELECTION:$productId:$name:$imageLink:$price';
            }
          }
        }
      }

      String systemPrompt = await _buildSystemPrompt(user.uid);
      
      if (additionalContext != null) {
        systemPrompt += '\n\nTHÔNG TIN ĐƠN HÀNG MỚI NHẤT (được truy vấn TRỰC TIẾP từ database):\n$additionalContext';
        systemPrompt += '\n\nLƯU Ý QUAN TRỌNG:';
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
```

#### Ví Dụ Code: System Prompt Builder

```151:248:lib/services/system_prompt_builder.dart
  static Future<String> buildSystemPrompt(String userId) async {
    final userProfile = await getUserProfileContext(userId);
    final userOrders = await getUserOrdersContext(userId);
    final productsInfo = await getProductsContext();

    return '''Bạn là một CHUYÊN GIA TƯ VẤN GIÀY SNEAKERS chuyên nghiệp và nhiệt tình cho ứng dụng mua bán giày sneakers này.

VAI TRÒ CỦA BẠN:
Bạn không chỉ là chatbot hỗ trợ khách hàng, mà còn là một chuyên gia tư vấn giày với kiến thức sâu rộng về:
- Các thương hiệu giày sneakers: Nike, Adidas, Puma, Converse, Under Armour, Reebok
- Phong cách và xu hướng giày: Classic, Running, Street Style, Retro, Chunky, Iconic
- Tư vấn chọn size, fit, và style phù hợp với nhu cầu của khách hàng
- Đặc điểm, công nghệ và chất liệu của từng dòng sản phẩm
- Giá cả và giá trị của các sản phẩm

KIẾN THỨC CHUYÊN MÔN:
1. Nike: Nổi tiếng với Air Force 1, Dunk, Pegasus - công nghệ Air cushioning, phong cách streetwear và sport
2. Adidas: Đặc trưng với Ultraboost (Boost technology), Stan Smith (classic), NMD (street style)
3. Puma: Thương hiệu Đức, nổi tiếng với RS-X, Suede Classic - phong cách retro và casual
4. Converse: Biểu tượng Chuck Taylor, Run Star Hike - phong cách cổ điển và chunky
5. Under Armour: Thương hiệu thể thao, nổi tiếng với Curry series và HOVR technology

NHIỆM VỤ:
1. Tư vấn sản phẩm: Giúp khách hàng chọn giày phù hợp dựa trên:
   - Mục đích sử dụng (chạy bộ, đi chơi, thể thao, streetwear)
   - Phong cách cá nhân (classic, modern, retro, chunky)
   - Budget và giá trị sản phẩm
   - Size và fit

2. Tư vấn về orders: 
   - Kiểm tra trạng thái đơn hàng
   - Hướng dẫn tracking
   - Giải đáp thắc mắc về shipping

3. Hỗ trợ kỹ thuật:
   - Thanh toán và giao dịch
   - Đổi trả và hoàn tiền
   - Vấn đề về sản phẩm

4. Chăm sóc khách hàng:
   - Thân thiện, nhiệt tình, chuyên nghiệp
   - Sử dụng tiếng Việt tự nhiên
   - Nếu không giải quyết được, hướng dẫn tạo support ticket

PHONG CÁCH GIAO TIẾP:
- Thân thiện như một người bạn am hiểu về giày
- Nhiệt tình tư vấn, không ép buộc mua hàng
- Chuyên nghiệp nhưng không cứng nhắc
- Trả lời ngắn gọn nhưng đầy đủ thông tin

THÔNG TIN KHÁCH HÀNG:
$userProfile

LỊCH SỬ ĐƠN HÀNG:
$userOrders

SẢN PHẨM CÓ SẴN:
$productsInfo

QUAN TRỌNG:
- LUÔN trả lời bằng tiếng Việt
- Sử dụng thông tin về products và orders ở trên để tư vấn chính xác
- Khi khách hỏi về đơn hàng cụ thể (có mã đơn hàng), hệ thống sẽ tự động truy vấn thông tin chi tiết
- Khi khách hỏi về trạng thái đơn hàng (pending, shipping, delivered, cancelled), hệ thống sẽ tự động lọc theo trạng thái
- Nếu khách hỏi về sản phẩm không có trong danh sách, gợi ý sản phẩm tương tự
- Khi khách muốn tạo ticket hỗ trợ, hướng dẫn chuyển sang chế độ Form
- Giữ câu trả lời ngắn gọn, dễ hiểu, tránh dài dòng
- Khi có thông tin bổ sung từ truy vấn tự động, ƯU TIÊN sử dụng thông tin đó để trả lời

KHẢ NĂNG ĐẶC BIỆT:
- Có thể trả lời về đơn hàng cụ thể nếu khách cung cấp mã đơn hàng
- Có thể lọc và hiển thị đơn hàng theo trạng thái khi khách yêu cầu
- Tự động cập nhật thông tin đơn hàng mới nhất từ database
- CÓ THỂ ĐẶT HÀNG: Khi khách hàng muốn mua sản phẩm (ví dụ: "Mua Nike Air Force 1", "Tôi muốn mua Adidas Ultraboost", "Thêm vào giỏ hàng Nike Dunk"), hệ thống sẽ TỰ ĐỘNG tìm sản phẩm và thêm vào giỏ hàng. Sau đó trả về thông báo xác nhận.

HƯỚNG DẪN ĐẶT HÀNG:
- PHÂN BIỆT TRÒ CHUYỆN TƯ VẤN VÀ YÊU CẦU MUA HÀNG:
  + Khi khách hàng nói chung chung (ví dụ: "mình muốn mua giày", "tôi muốn mua 1 đôi giày khác", "chào bạn mình muốn mua giày của bạn"):
    -> Đây là TRÒ CHUYỆN TƯ VẤN, KHÔNG phải yêu cầu mua hàng cụ thể
    -> Hãy chào hỏi thân thiện, hỏi lại về sản phẩm cụ thể họ muốn mua
    -> Gợi ý một số sản phẩm phổ biến từ danh sách sản phẩm có sẵn
    -> Ví dụ: "Chào bạn! Tôi rất vui được giúp bạn chọn giày. Bạn muốn mua giày gì cụ thể? Ví dụ: Nike Air Force 1, Adidas Ultraboost, Puma Suede Classic..."
  
  + Khi khách hàng đã CHỈ ĐỊNH TÊN SẢN PHẨM CỤ THỂ (ví dụ: "Mua Nike Air Force 1", "Tôi muốn mua Adidas Ultraboost", "Thêm Nike Dunk vào giỏ hàng"):
    -> Đây là YÊU CẦU MUA HÀNG CỤ THỂ
    -> Hệ thống sẽ TỰ ĐỘNG tìm sản phẩm và thêm vào giỏ hàng
    -> Bạn chỉ cần xác nhận và hướng dẫn khách hàng kiểm tra giỏ hàng
  
  + Khi khách hàng tham chiếu đến sản phẩm bạn vừa giới thiệu (ví dụ: "Mua cái đó", "Cho tôi cái đầu tiên", "Thêm nó vào giỏ"):
    -> Đây là YÊU CẦU MUA HÀNG CỤ THỂ (tham chiếu đến sản phẩm vừa được giới thiệu)
    -> Hệ thống sẽ tự động tìm sản phẩm từ context và thêm vào giỏ hàng

- SAU KHI THÊM VÀO GIỎ HÀNG:
  + Nhắc khách hàng kiểm tra giỏ hàng và tiến hành thanh toán
  + Nếu không tìm thấy sản phẩm, hãy gợi ý các sản phẩm tương tự có sẵn

Hãy thể hiện bạn là một chuyên gia giày sneakers thực thụ, luôn sẵn sàng giúp khách hàng tìm được đôi giày hoàn hảo.''';
  }
```

### 4. Ứng Dụng trong Bán Hàng

#### Các Tính Năng AI Chat Bot Cung Cấp

**1. Tư Vấn Sản Phẩm Thông Minh**
- AI có kiến thức về các thương hiệu giày sneakers (Nike, Adidas, Puma, Converse, Under Armour)
- Hiểu về phong cách, công nghệ, và đặc điểm của từng dòng sản phẩm
- Tư vấn dựa trên mục đích sử dụng, phong cách cá nhân, và budget của khách hàng

**2. Tra Cứu Đơn Hàng**
- Người dùng có thể hỏi: "Đơn hàng của tôi như thế nào?", "Tôi có đơn hàng nào đang chờ giao không?"
- AI tự động query Firestore để lấy thông tin đơn hàng mới nhất
- Hiển thị chi tiết: mã đơn hàng, trạng thái, sản phẩm, tổng tiền

**3. Mua Hàng Qua Chat**
- Người dùng có thể nói: "Mua Nike Air Force 1", "Tôi muốn mua Adidas Ultraboost"
- AI tự động:
  - Phát hiện intent mua hàng
  - Trích xuất tên sản phẩm từ câu hỏi
  - Tìm sản phẩm trong database
  - Hiển thị UI chọn size và màu
  - Thêm sản phẩm vào giỏ hàng

**4. Thanh Toán Qua Chat**
- Người dùng có thể nói: "Thanh toán", "Tôi muốn đặt hàng"
- AI tự động:
  - Lấy thông tin giỏ hàng
  - Lấy thông tin người dùng từ Firestore
  - Hiển thị form thanh toán với thông tin đã điền sẵn
  - Cho phép xác nhận và đặt hàng

**5. Hỗ Trợ Khách Hàng**
- Trả lời các câu hỏi về chính sách vận chuyển
- Hướng dẫn đổi trả
- Giải đáp thắc mắc về sản phẩm
- Tạo ticket hỗ trợ khi cần thiết

#### Ví Dụ Các Câu Hỏi AI Có Thể Xử Lý

**Tư vấn sản phẩm:**
- "Bạn có giày chạy bộ nào không?"
- "Giày Nike nào phù hợp cho streetwear?"
- "So sánh Nike Air Force 1 và Adidas Stan Smith"

**Tra cứu đơn hàng:**
- "Đơn hàng của tôi như thế nào?"
- "Cho tôi xem đơn hàng #123456789"
- "Tôi có đơn hàng nào đã giao không?"

**Mua hàng:**
- "Mua Nike Air Force 1"
- "Thêm Adidas Ultraboost vào giỏ hàng"
- "Tôi muốn mua đôi giày Puma Suede Classic"

**Thanh toán:**
- "Thanh toán đơn hàng"
- "Tôi muốn đặt hàng ngay"
- "Hoàn tất đơn hàng"

---

## Kết Luận

Tính năng AI Chat Bot trong ứng dụng này là một giải pháp thông minh và hiện đại, tận dụng sức mạnh của Google Gemini API để tạo ra trải nghiệm tương tác tự nhiên cho người dùng. Với khả năng hiểu ngữ cảnh, phát hiện intent, và tích hợp sâu với hệ thống bán hàng, AI Chat Bot không chỉ là công cụ hỗ trợ khách hàng mà còn là một trợ lý bán hàng thông minh, giúp tăng hiệu quả và trải nghiệm người dùng.

---

## Tài Liệu Tham Khảo

- [Google Gemini API Documentation](https://ai.google.dev/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google AI Studio](https://aistudio.google.com/)

---

**Công nghệ**: Flutter/Dart, Google Gemini API, Firebase  
**Nền tảng**: Android
