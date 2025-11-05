import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ecommerce_app/services/gemini_service.dart';
import 'package:ecommerce_app/utils/chat_utils.dart';
import 'package:ecommerce_app/utils/gemini_config.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/model/chat_message.dart';
import 'package:ecommerce_app/model/product_selection_state.dart';
import 'package:ecommerce_app/model/checkout_form_state.dart';
import 'package:ecommerce_app/view/home/checkout_form_widget.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';
import 'package:ecommerce_app/respository/components/address_picker.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';

const botWelcome =
    "Xin chào! Chào mừng đến với Dịch vụ Hỗ trợ Khách hàng. Vui lòng cung cấp thông tin về vấn đề của bạn.";
const aiBotWelcome =
    "Xin chào! Tôi là trợ lý AI của bạn. Tôi có thể giúp bạn với các câu hỏi về đơn hàng, sản phẩm, thanh toán và hơn thế nữa. Bạn cần hỗ trợ gì?";
final mainIssues = [
  "Order Issues",
  "Item Quality",
  "Payment Issues",
  "Style Suggestion",
  "Other"
];

final orderIssueSub = [
  "I didn't receive my parcel",
  "I want to cancel my order",
  "I want to return my order",
  "Package was damaged",
  "Other"
];

class Order {
  final String id;
  final String status;
  final String summary;
  final int items;
  final String thumbUrl;
  Order({
    required this.id,
    required this.status,
    required this.summary,
    required this.items,
    required this.thumbUrl,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class Message {
  final String text;
  final bool fromUser;
  final DateTime time;
  Message({required this.text, this.fromUser = false}) : time = DateTime.now();
}

enum ChatMode { ai, form }

class _ChatScreenState extends State<ChatScreen> {
  ChatMode _chatMode = ChatMode.ai;
  
  int step = 0;
  String? selectedMain;
  String? selectedSub;
  String? description;
  Order? selectedOrder;
  
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _aiMessageController = TextEditingController();
  bool _isLoadingAIResponse = false;
  ProductSelectionState? _productSelection;
  CheckoutFormState? _checkoutState;
  
  final Set<String> _chatbotCartProductIds = <String>{};
  
  List<Message> messages = [];
  final TextEditingController _descCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }
  
  void _initializeChat() {
    if (_chatMode == ChatMode.ai) {
      final isConfigured = GeminiConfig.isConfigured;
      final hasModel = _geminiService.isAvailable;
      
      if (isConfigured && hasModel) {
        messages.add(Message(text: aiBotWelcome, fromUser: false));
      } else {
        String errorMsg = 'Chế độ AI chưa sẵn sàng.\n';
        if (!isConfigured) {
          errorMsg += 'API key chưa được cấu hình.\n';
          errorMsg += 'Hiện tại: ${GeminiConfig.apiKey.substring(0, 10)}...\n';
        }
        if (!hasModel) {
          errorMsg += 'Model chưa được khởi tạo.';
        }
        errorMsg += '\nVui lòng kiểm tra lại file lib/utils/gemini_config.dart';
        messages.add(Message(text: errorMsg, fromUser: false));
      }
    } else {
      messages.add(Message(text: botWelcome, fromUser: false));
    }
  }
  
  void _switchMode(ChatMode newMode) {
    setState(() {
      _chatMode = newMode;
      messages.clear();
      step = 0;
      selectedMain = null;
      selectedSub = null;
      selectedOrder = null;
      description = null;
      _descCtrl.clear();
      _aiMessageController.clear();
      _initializeChat();
    });
  }

  void addUserMessage(String text) {
    setState(() {
      messages.add(Message(text: text, fromUser: true));
    });
  }

  void addBotMessage(String text) {
    setState(() {
      messages.add(Message(text: text, fromUser: false));
    });
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
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
  
  void _handleProductSelection(String response) {
    if (!response.startsWith('PRODUCT_SELECTION:')) return;
    
    final withoutPrefix = response.substring('PRODUCT_SELECTION:'.length);
    
    final lastColonIndex = withoutPrefix.lastIndexOf(':');
    if (lastColonIndex == -1) return;
    
    final priceStr = withoutPrefix.substring(lastColonIndex + 1);
    final price = double.tryParse(priceStr) ?? 0.0;
    
    final remaining = withoutPrefix.substring(0, lastColonIndex);
    
    final firstColonIndex = remaining.indexOf(':');
    if (firstColonIndex == -1) return;
    
    final productId = remaining.substring(0, firstColonIndex);
    
    final nameAndImage = remaining.substring(firstColonIndex + 1);
    
    final secondColonIndex = nameAndImage.indexOf(':');
    if (secondColonIndex == -1) return;
    
    final name = nameAndImage.substring(0, secondColonIndex);
    final imageLink = nameAndImage.substring(secondColonIndex + 1);
    
    setState(() {
      _productSelection = ProductSelectionState(
        productId: productId,
        productName: name,
        imageLink: imageLink,
        price: price,
        selectedSize: null,
        selectedColor: null,
        isWaitingForSize: true,
        isWaitingForColor: false,
        isReadyToConfirm: false,
      );
    });
    
    addBotMessage('Bạn muốn chọn size nào? (${ProductSizes.available.join(', ')})');
  }
  
  void _handleCheckoutForm(String response) {
    if (!response.startsWith('CHECKOUT_FORM:')) return;
    
    final withoutPrefix = response.substring('CHECKOUT_FORM:'.length);
    final parts = withoutPrefix.split('|');
    
    if (parts.length < 5) {
      addBotMessage('Lỗi: Không thể parse thông tin thanh toán. Vui lòng thử lại.');
      return;
    }
    
    final userName = parts[0];
    final userEmail = parts[1];
    final userPhone = parts[2];
    final userAddress = parts[3].replaceAll('||', '|').replaceAll('::', ':');
    final totalPrice = double.tryParse(parts[4]) ?? 0.0;
    
    final cart = PersistentShoppingCart();
    final cartData = cart.getCartData();
    final cartItems = cartData['cartItems'] as List? ?? [];
    
    List<Map<String, dynamic>> itemsList = [];
    for (var item in cartItems) {
      String? productId;
      
      if (item is PersistentShoppingCartItem) {
        productId = item.productId;
      } else if (item is Map) {
        productId = item['productId']?.toString();
      }
      
      if (productId != null && _chatbotCartProductIds.contains(productId)) {
        if (item is PersistentShoppingCartItem) {
          itemsList.add(item.toJson());
        } else if (item is Map) {
          itemsList.add(Map<String, dynamic>.from(item));
        }
      }
    }
    
    if (itemsList.isEmpty) {
      addBotMessage('Không tìm thấy sản phẩm nào trong giỏ hàng được đặt mua qua chatbot. Vui lòng thêm sản phẩm vào giỏ hàng trước khi thanh toán.');
      return;
    }
    
    double calculatedTotal = 0.0;
    for (var itemJson in itemsList) {
      final unitPrice = (itemJson['unitPrice'] as num?)?.toDouble() ?? 0.0;
      final quantity = (itemJson['quantity'] as num?)?.toInt() ?? 0;
      calculatedTotal += unitPrice * quantity;
    }
    
      final finalTotalPrice = calculatedTotal > 0 ? calculatedTotal : totalPrice;
      
      FirebaseFirestore.instance
        .collection('User Data')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((userDoc) {
      final userData = userDoc.data() ?? {};
      FullAddress? structuredAddress;
      
      if (userData['provinceCode'] != null || userData['provinceName'] != null) {
        structuredAddress = FullAddress.fromMap(userData);
      } else if (userData['address'] != null && userData['address'].toString().isNotEmpty) {
        structuredAddress = FullAddress.fromString(userData['address'].toString());
      }
      
      setState(() {
        _checkoutState = CheckoutFormState(
          name: userName,
          email: userEmail,
          phone: userPhone,
          address: userAddress,
          structuredAddress: structuredAddress,
          totalPrice: finalTotalPrice,
          items: itemsList,
          isReadyToConfirm: true,
        );
      });
      
      addBotMessage('Vui lòng kiểm tra và xác nhận thông tin thanh toán bên dưới:');
    });
  }
  
  void _confirmCheckout(CheckoutFormState checkoutState) {
    _placeOrderFromChat(checkoutState);
  }
  
  String _buildOrderDetailsMessage(String orderId, CheckoutFormState checkoutState) {
    final buffer = StringBuffer();
    
    buffer.writeln('**Đơn hàng đã được đặt thành công!**\n');
    buffer.writeln('**Trạng thái:** Chờ xác nhận');
    buffer.writeln('**Tổng tiền:** ${Formatter.formatCurrency(checkoutState.totalPrice.toInt())}\n');
    
    buffer.writeln('**Danh sách sản phẩm:**');
    for (int i = 0; i < checkoutState.items.length; i++) {
      final item = checkoutState.items[i];
      final productName = item['productName']?.toString() ?? 'N/A';
      final quantity = item['quantity'] ?? 1;
      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
      final size = item['productDetails']?['size']?.toString() ?? 'N/A';
      final color = item['productDetails']?['color']?.toString() ?? 'N/A';
      final itemTotal = unitPrice * (quantity as num).toInt();
      
      buffer.writeln('${i + 1}. $productName');
      buffer.writeln('   - Size: $size | Màu: $color');
      buffer.writeln('   - Số lượng: $quantity');
      buffer.writeln('   - Đơn giá: ${Formatter.formatCurrency(unitPrice.toInt())}');
      buffer.writeln('   - Thành tiền: ${Formatter.formatCurrency(itemTotal.toInt())}');
      if (i < checkoutState.items.length - 1) {
        buffer.writeln('');
      }
    }
    
    buffer.writeln('\n**Thông tin giao hàng:**');
    buffer.writeln('   - Người nhận: ${checkoutState.name}');
    buffer.writeln('   - Số điện thoại: ${checkoutState.phone}');
    buffer.writeln('   - Email: ${checkoutState.email}');
    buffer.writeln('   - Địa chỉ: ${checkoutState.address}');
    
    buffer.writeln('\n💬 **Lưu ý:** Bạn có thể theo dõi trạng thái đơn hàng trong phần "Đơn hàng" của ứng dụng.');
    buffer.writeln('\nCảm ơn bạn đã mua sắm! 🎉');
    
    return buffer.toString();
  }
  
  Future<void> _placeOrderFromChat(CheckoutFormState checkoutState) async {
    final orderDb = FirebaseFirestore.instance.collection('Orders');
    final auth = FirebaseAuth.instance;
    
    try {
      addBotMessage('Đang xử lý đơn hàng...');
      
      if (checkoutState.items.isEmpty) {
        addBotMessage('Không có sản phẩm nào để đặt hàng. Vui lòng thử lại.');
        return;
      }
      
      for (var itemJson in checkoutState.items) {
        final quantity = (itemJson['quantity'] as num?)?.toInt() ?? 0;
        final unitPrice = (itemJson['unitPrice'] as num?)?.toDouble() ?? 0.0;
        final productName = itemJson['productName']?.toString() ?? 'N/A';
        final productDetails = itemJson['productDetails'] as Map<String, dynamic>?;
        
        if (quantity <= 0) {
          addBotMessage('Sản phẩm "$productName" có số lượng không hợp lệ!');
          return;
        }
        
        if (productDetails == null || 
            productDetails['size'] == null || 
            productDetails['color'] == null) {
          addBotMessage('Sản phẩm "$productName" thiếu thông tin size hoặc color!');
          return;
        }
        
        if (unitPrice <= 0) {
          addBotMessage('Sản phẩm "$productName" có giá không hợp lệ!');
          return;
        }
      }
      
      String orderId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final orderData = <String, dynamic>{
        'orderId': orderId,
        'userId': auth.currentUser!.uid,
        'name': checkoutState.name,
        'email': checkoutState.email,
        'phone': checkoutState.phone,
        'address': checkoutState.address,
        'totalPrice': checkoutState.totalPrice,
        'items': checkoutState.items,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      if (checkoutState.structuredAddress != null) {
        orderData.addAll(checkoutState.structuredAddress!.toMap());
      }
      
      await orderDb.doc(orderId).set(orderData);
      
      final cart = PersistentShoppingCart();
      
      final orderedProductIds = <String>{};
      for (var itemJson in checkoutState.items) {
        final productId = itemJson['productId']?.toString();
        if (productId != null) {
          orderedProductIds.add(productId);
        }
      }
      
      for (var productId in orderedProductIds) {
        cart.removeFromCart(productId);
      }
      
      setState(() {
        _chatbotCartProductIds.clear();
      });
      
      final userDataRef = FirebaseFirestore.instance
          .collection('User Data')
          .doc(auth.currentUser!.uid);
      
      final updateData = <String, dynamic>{};
      if (checkoutState.name.isNotEmpty) {
        updateData['Full name'] = checkoutState.name;
      }
      if (checkoutState.email.isNotEmpty) {
        updateData['Email'] = checkoutState.email;
      }
      if (checkoutState.phone.isNotEmpty) {
        updateData['phone'] = checkoutState.phone;
      }
      if (checkoutState.structuredAddress != null) {
        updateData.addAll(checkoutState.structuredAddress!.toMap());
        updateData['address'] = checkoutState.structuredAddress!.fullAddressString;
      } else if (checkoutState.address.isNotEmpty) {
        updateData['address'] = checkoutState.address;
      }
      
      if (updateData.isNotEmpty) {
        await userDataRef.update(updateData);
      }
      
      setState(() {
        _checkoutState = null;
      });
      
      final orderDetails = _buildOrderDetailsMessage(orderId, checkoutState);
      addBotMessage(orderDetails);
      
    } catch (e) {
      addBotMessage('❌ Có lỗi xảy ra khi đặt hàng: $e\nVui lòng thử lại hoặc liên hệ hỗ trợ.');
    }
  }
  
  void _handleProductSelectionResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase().trim();
    
    if (_productSelection!.isWaitingForSize) {
      String? selectedSize;
      for (var size in ProductSizes.available) {
        if (lowerMessage.contains(size)) {
          selectedSize = size;
          break;
        }
      }
      
      if (selectedSize != null) {
        setState(() {
          _productSelection = _productSelection!.copyWith(
            selectedSize: selectedSize,
            isWaitingForSize: false,
            isWaitingForColor: true,
          );
        });
        addUserMessage(userMessage);
        addBotMessage('Bạn muốn chọn màu nào? (${ProductColors.available.map((c) => c['name']).join(', ')})');
      } else {
        addUserMessage(userMessage);
        addBotMessage('Vui lòng chọn size từ danh sách: ${ProductSizes.available.join(', ')}');
      }
    }
    else if (_productSelection!.isWaitingForColor) {
      String? selectedColor;
      for (var color in ProductColors.available) {
        final colorName = color['name'].toString().toLowerCase();
        if (lowerMessage.contains(colorName)) {
          selectedColor = color['name'] as String;
          break;
        }
      }
      
      if (selectedColor != null) {
        setState(() {
          _productSelection = _productSelection!.copyWith(
            selectedColor: selectedColor,
            isWaitingForColor: false,
            isReadyToConfirm: true,
          );
        });
        addUserMessage(userMessage);
        _showProductConfirmation();
      } else {
        addUserMessage(userMessage);
        addBotMessage('Vui lòng chọn màu từ danh sách: ${ProductColors.available.map((c) => c['name']).join(', ')}');
      }
    }
  }
  
  void _showProductConfirmation() {
    if (_productSelection == null) return;
    
    final priceFormatted = _productSelection!.price != null 
        ? Formatter.formatCurrency(_productSelection!.price!.toInt())
        : 'N/A';
    
    final confirmationText = '''
**Đã chọn sản phẩm:**

**Tên sản phẩm:** ${_productSelection!.productName}
**Size:** ${_productSelection!.selectedSize}
**Màu:** ${_productSelection!.selectedColor}
**Giá:** $priceFormatted

Bạn có muốn thanh toán luôn cho sản phẩm này không? Tôi sẽ giúp bạn kiểm tra lại thông tin và tiến hành thanh toán.
''';
    
    addBotMessage(confirmationText);
  }
  
  Future<void> _addProductToCartFromSelection() async {
    if (_productSelection == null) {
      return;
    }
    
    if (!_productSelection!.isComplete) {
      return;
    }
    
    if (!_productSelection!.isReadyToConfirm) {
      return;
    }
    
    try {
      final result = await _geminiService.addProductToCart(
        _productSelection!.productId!,
        _productSelection!.productName!,
        _productSelection!.imageLink!,
        _productSelection!.price!,
        size: _productSelection!.selectedSize!,
        color: _productSelection!.selectedColor!,
      );
      
      setState(() {
        _chatbotCartProductIds.add(_productSelection!.productId!);
        _productSelection = null;
      });
      
      addBotMessage(result);
    } catch (e) {
      addBotMessage('❌ Lỗi khi thêm sản phẩm vào giỏ hàng: $e');
    }
  }
  
  void _showCreateTicketDialog(String conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo Ticket Hỗ trợ'),
        content: const Text('Bạn có muốn tạo ticket hỗ trợ từ cuộc trò chuyện này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTicketFromAIConversation(conversation);
            },
            child: const Text('Tạo Ticket'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _createTicketFromAIConversation(String conversation) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      addBotMessage('Vui lòng đăng nhập để tạo ticket.');
      return;
    }
    
    final ticketData = ChatUtils.extractTicketDataFromConversation(
      conversation,
      selectedOrder?.id,
    );
    
    final conversationText = messages
        .where((m) => m.fromUser)
        .map((m) => m.text)
        .join('\n');
    
    final summary = {
      "userId": user.uid,
      "email": user.email ?? "",
      "issueType": ticketData['issueType'] ?? 'Other',
      "detail": ticketData['detail'] ?? 'AI Chat Conversation',
      "description": '$conversationText\n\n---\nAI Conversation Summary',
      "orderId": ticketData['orderId'] ?? "",
      "status": "pending",
      "createdAt": DateTime.now().toString(),
      "source": "AI Chat",
    };
    
    try {
      await FirebaseFirestore.instance
          .collection("SupportTickets")
          .add(summary);
      
      addBotMessage('✅ Ticket đã được tạo thành công! Mã ticket sẽ được gửi đến email của bạn.');
    } catch (e) {
      addBotMessage('⚠️ Không thể tạo ticket: $e');
    }
  }

  void goNext() async {
    if (step == 0 && selectedMain == null) return;
    if (step == 1 && selectedSub == null) return;
    if (step == 2 && (description == null || description!.isEmpty)) return;
    if (step == 3 && selectedOrder == null && selectedMain == "Order Issues") {
      return;
    }

    setState(() {
      if (step == 0) {
        addUserMessage("Issue selected: $selectedMain");
        step = 1;
        addBotMessage("Please specify details for: $selectedMain");
      } else if (step == 1) {
        addUserMessage("Detail: $selectedSub");
        step = 2;
        addBotMessage("Please describe your issue in a few words.");
      } else if (step == 2) {
        addUserMessage("Description: $description");
        if (selectedMain == "Order Issues") {
          step = 3;
          addBotMessage("Select one of your orders:");
        } else {
          step = 4;
          addBotMessage("Ready to submit your request.");
        }
      } else if (step == 3) {
        addUserMessage("Selected order: ${selectedOrder!.id}");
        step = 4;
        addBotMessage("Ready. Tap Submit to send your request.");
      } else if (step == 4) {
        submitRequest();
      }
    });
  }

  void submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      addBotMessage("Please log in first.");
      return;
    }

    final summary = {
      "userId": user.uid,
      "email": user.email ?? "",
      "issueType": selectedMain ?? "",
      "detail": selectedSub ?? "",
      "description": description ?? "",
      "orderId": selectedOrder?.id ?? "",
      "status": "pending",
      "createdAt": DateTime.now().toString(),
    };

    try {
      await FirebaseFirestore.instance
          .collection("SupportTickets")
          .add(summary);

      final summaryText = '''
📝 **Ticket Summary**
━━━━━━━━━━━━━━━
📂 Issue Type: ${summary['issueType']}
📦 Order ID: ${summary['orderId']}
💬 Detail: ${summary['detail']}
🖊️ Description: ${summary['description']}
''';
      addUserMessage(summaryText);
      addBotMessage(
          "✅ Thank you! Your ticket has been submitted successfully.");
    } on JsonUnsupportedObjectError catch (e) {
      addBotMessage("⚠️ Failed to send request: $e");
    }
  }

  void resetChat() {
    setState(() {
      step = 0;
      selectedMain = null;
      selectedSub = null;
      selectedOrder = null;
      description = null;
      _productSelection = null;
      _checkoutState = null;
      _descCtrl.clear();
      _aiMessageController.clear();
      messages.clear();
      _initializeChat();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _descCtrl.dispose();
    _aiMessageController.dispose();
    super.dispose();
  }

  Widget buildMessage(Message m) {
    final align =
        m.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = m.fromUser ? Colors.blue : Colors.grey.shade200;
    final txtColor = m.fromUser ? Colors.white : Colors.black87;
    
    final isSizeQuestion = !m.fromUser && 
        (m.text.toLowerCase().contains('size') || m.text.contains('chọn size')) && 
        _productSelection?.isWaitingForSize == true;
    final isColorQuestion = !m.fromUser && 
        (m.text.toLowerCase().contains('màu') || m.text.toLowerCase().contains('color')) && 
        _productSelection?.isWaitingForColor == true;
    final isConfirmationQuestion = !m.fromUser && 
        (m.text.contains('thêm sản phẩm') || m.text.contains('giỏ hàng')) && 
        _productSelection?.isReadyToConfirm == true;
    
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: m.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: txtColor, fontSize: 14),
                  strong: TextStyle(
                    color: txtColor,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color: txtColor,
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: TextStyle(color: txtColor),
                  listIndent: 24.0,
                  h1: TextStyle(color: txtColor, fontSize: 20, fontWeight: FontWeight.bold),
                  h2: TextStyle(color: txtColor, fontSize: 18, fontWeight: FontWeight.bold),
                  h3: TextStyle(color: txtColor, fontSize: 16, fontWeight: FontWeight.bold),
                  code: TextStyle(
                    color: txtColor,
                    backgroundColor: Colors.transparent,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                selectable: true,
              ),
              // Hiển thị size picker nếu đang hỏi size
              if (isSizeQuestion) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProductSizes.available.map((size) {
                    final isSelected = _productSelection?.selectedSize == size;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _productSelection = _productSelection!.copyWith(
                            selectedSize: size,
                            isWaitingForSize: false,
                            isWaitingForColor: true,
                          );
                        });
                        addUserMessage(size);
                        addBotMessage('Bạn muốn chọn màu nào? (${ProductColors.available.map((c) => c['name']).join(', ')})');
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          border: Border.all(
                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            size,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (isColorQuestion) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ProductColors.available.map((colorData) {
                    final colorName = colorData['name'] as String;
                    final colorValue = Color(colorData['color'] as int);
                    final isSelected = _productSelection?.selectedColor == colorName;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _productSelection = _productSelection!.copyWith(
                            selectedColor: colorName,
                            isWaitingForColor: false,
                            isReadyToConfirm: true,
                          );
                        });
                        addUserMessage(colorName);
                        _showProductConfirmation();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade400,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorValue,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (isConfirmationQuestion) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        addUserMessage('Có');
                        _addProductToCartFromSelection();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Có, thêm vào giỏ'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        addUserMessage('Không');
                        addBotMessage('Đã hủy việc thêm sản phẩm vào giỏ hàng.');
                        setState(() {
                          _productSelection = null;
                        });
                      },
                      child: const Text('Hủy'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget buildIssuesStep() => _buildChipStep("What's your issue?", mainIssues,
      selectedMain, (v) => setState(() => selectedMain = v));

  Widget buildSubStep() {
    final list = selectedMain == "Order Issues"
        ? orderIssueSub
        : ["Product damaged", "Wrong size", "Other"];
    return _buildChipStep("Please choose details", list, selectedSub,
        (v) => setState(() => selectedSub = v));
  }

  Widget _buildChipStep(String title, List<String> list, String? selected,
      Function(String) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.map((t) {
            final isSel = selected == t;
            return ChoiceChip(
              label: Text(t),
              selected: isSel,
              onSelected: (_) => onSel(t),
              selectedColor: Colors.blue,
              backgroundColor: Colors.white,
              shape: const StadiumBorder(
                  side: BorderSide(color: Colors.blueAccent)),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : Colors.blueAccent,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildDescStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _descCtrl,
        decoration: InputDecoration(
          labelText: "Describe your issue...",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              setState(() {
                description = _descCtrl.text.trim();
              });
              goNext();
            },
          ),
        ),
        maxLines: 3,
      ),
    );
  }

  Future<List<Order>> fetchOrders(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Orders')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Order(
        id: data['orderId'] ?? '',
        status: data['status'] ?? '',
        summary: data['address'] ?? '',
        items: (data['items'] as List?)?.length ?? 0,
        thumbUrl: (data['items']?[0]?['productThumbnail'] ??
            "https://via.placeholder.com/80") as String,
      );
    }).toList();
  }

  Widget buildOrderStep() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Order>>(
      future: fetchOrders(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("You don’t have any orders."),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Select one of your orders:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...orders.map((o) {
              final sel = selectedOrder?.id == o.id;
              return GestureDetector(
                onTap: () => setState(() => selectedOrder = o),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sel ? Colors.blue.shade50 : Colors.white,
                    border: Border.all(
                        color: sel ? Colors.blue : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.network(o.thumbUrl,
                          width: 56, height: 56, fit: BoxFit.cover),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Order ${o.id}\nStatus: ${o.status}"),
                      ),
                      Text(sel ? "✓" : "Select",
                          style: TextStyle(
                              color: sel ? Colors.blue : Colors.grey)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget buildConfirmStep() => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Ready to submit your request."),
            if (selectedMain != null) Text("Issue: $selectedMain"),
            if (selectedSub != null) Text("Detail: $selectedSub"),
            if (description != null) Text("Desc: $description"),
            if (selectedOrder != null) Text("Order: ${selectedOrder!.id}"),
          ],
        ),
      );

  Widget buildBottomBar() {
    final label = step == 4 ? "Submit" : "Next";
    bool disabled = (step == 0 && selectedMain == null) ||
        (step == 1 && selectedSub == null) ||
        (step == 2 && (description == null || description!.isEmpty)) ||
        (step == 3 && selectedMain == "Order Issues" && selectedOrder == null);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: disabled ? null : goNext,
              child: Text(label),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: resetChat,
            icon: const Icon(Icons.refresh),
            tooltip: "Restart chat",
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              'AI Chat',
              ChatMode.ai,
              Icons.smart_toy,
            ),
          ),
          Expanded(
            child: _buildModeButton(
              'Form',
              ChatMode.form,
              Icons.article,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeButton(String label, ChatMode mode, IconData icon) {
    final isSelected = _chatMode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAIChatInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aiMessageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendAIMessage(),
              enabled: !_isLoadingAIResponse,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isLoadingAIResponse 
                  ? Colors.grey 
                  : Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isLoadingAIResponse
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoadingAIResponse ? null : _sendAIMessage,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Bot"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _switchMode(_chatMode),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildModeSelector(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length + (_checkoutState != null ? 2 : 1),
                itemBuilder: (context, i) {
                  if (i < messages.length) {
                    return buildMessage(messages[i]);
                  } else if (i == messages.length && _checkoutState != null) {
                    return CheckoutFormWidget(
                      checkoutState: _checkoutState!,
                      onConfirm: (checkoutState) {
                        _confirmCheckout(checkoutState);
                      },
                    );
                  } else {
                    return SizedBox(height: _chatMode == ChatMode.ai ? 80 : 180);
                  }
                },
              ),
            ),
            if (_chatMode == ChatMode.ai)
              _buildAIChatInput()
            else ...[
              Container(
                color: Colors.grey.shade50,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (step == 0) buildIssuesStep(),
                    if (step == 1) buildSubStep(),
                    if (step == 2) buildDescStep(),
                    if (step == 3) buildOrderStep(),
                    if (step == 4) buildConfirmStep(),
                  ],
                ),
              ),
              buildBottomBar(),
            ],
          ],
        ),
      ),
    );
  }
}
