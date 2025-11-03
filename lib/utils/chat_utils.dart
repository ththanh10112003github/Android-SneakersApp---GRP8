import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility functions for chat context building
class ChatUtils {
  /// Build context string về orders của user
  static Future<String> buildOrdersContext(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'Bạn chưa có đơn hàng nào.';
      }

      final ordersList = snapshot.docs.map((doc) {
        final data = doc.data();
        final items = data['items'] as List?;
        final itemNames = items?.map((item) => item['productName'] ?? 'N/A').join(', ') ?? 'N/A';
        
        return '''
📦 Đơn hàng #${data['orderId'] ?? 'N/A'}
   Trạng thái: ${data['status'] ?? 'N/A'}
   Số lượng sản phẩm: ${items?.length ?? 0}
   Tổng tiền: ${data['total'] ?? 'N/A'} VND
   Sản phẩm: $itemNames
        ''';
      }).join('\n');

      return 'Các đơn hàng gần đây của bạn:\n$ordersList';
    } catch (e) {
      return 'Không thể tải thông tin đơn hàng: $e';
    }
  }

  /// Build context string về user profile
  static Future<String> buildUserProfileContext(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('User Data')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return 'Không tìm thấy thông tin người dùng.';
      }

      final data = doc.data()!;
      return '''
Thông tin khách hàng:
👤 Tên: ${data['Full name'] ?? 'N/A'}
📧 Email: ${data['Email'] ?? 'N/A'}
📱 Số điện thoại: ${data['Phone'] ?? 'N/A'}
      ''';
    } catch (e) {
      return 'Không thể tải thông tin người dùng: $e';
    }
  }

  /// Extract structured data từ conversation để tạo ticket
  static Map<String, String> extractTicketDataFromConversation(
    String conversation,
    String? selectedOrderId,
  ) {
    final Map<String, String> ticketData = {
      'issueType': 'Other',
      'detail': 'AI Chat Conversation',
      'description': conversation,
      'orderId': selectedOrderId ?? '',
    };

    final lowerConversation = conversation.toLowerCase();
    
    // Phát hiện issue type từ conversation
    if (lowerConversation.contains('order') || 
        lowerConversation.contains('đơn hàng') ||
        lowerConversation.contains('parcel') ||
        lowerConversation.contains('gói hàng')) {
      ticketData['issueType'] = 'Order Issues';
      
      if (lowerConversation.contains('cancel') || lowerConversation.contains('hủy')) {
        ticketData['detail'] = "I want to cancel my order";
      } else if (lowerConversation.contains('return') || lowerConversation.contains('trả lại')) {
        ticketData['detail'] = "I want to return my order";
      } else if (lowerConversation.contains('receive') || 
                 lowerConversation.contains('nhận') ||
                 lowerConversation.contains('deliver')) {
        ticketData['detail'] = "I didn't receive my parcel";
      } else if (lowerConversation.contains('damaged') || lowerConversation.contains('hỏng')) {
        ticketData['detail'] = "Package was damaged";
      }
    } else if (lowerConversation.contains('quality') || 
               lowerConversation.contains('chất lượng') ||
               lowerConversation.contains('damaged') ||
               lowerConversation.contains('defect') ||
               lowerConversation.contains('lỗi')) {
      ticketData['issueType'] = 'Item Quality';
      if (lowerConversation.contains('size') || lowerConversation.contains('kích thước')) {
        ticketData['detail'] = 'Wrong size';
      } else {
        ticketData['detail'] = 'Product damaged';
      }
    } else if (lowerConversation.contains('payment') || 
               lowerConversation.contains('thanh toán') ||
               lowerConversation.contains('transaction') ||
               lowerConversation.contains('giao dịch')) {
      ticketData['issueType'] = 'Payment Issues';
    } else if (lowerConversation.contains('suggestion') || 
               lowerConversation.contains('gợi ý') ||
               lowerConversation.contains('recommend') ||
               lowerConversation.contains('đề xuất')) {
      ticketData['issueType'] = 'Style Suggestion';
    }

    return ticketData;
  }
}

