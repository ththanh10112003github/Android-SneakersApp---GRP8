import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/utils/formatter.dart';

class SystemPromptBuilder {
  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    if (dateValue is Timestamp) {
      return '${dateValue.toDate().day}/${dateValue.toDate().month}/${dateValue.toDate().year}';
    }
    if (dateValue is String) {
      return dateValue;
    }
    return 'N/A';
  }

  static Future<String> getUserProfileContext(String userId) async {
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
- Tên: ${data['Full name'] ?? 'N/A'}
- Email: ${data['Email'] ?? 'N/A'}
- Số điện thoại: ${data['Phone'] ?? 'N/A'}
      ''';
    } catch (e) {
      return 'Lỗi khi lấy thông tin khách hàng: $e';
    }
  }

  static Future<String> getUserOrdersContext(String userId) async {
    try {
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
      final docs = tempDocs.take(5).toList();

      if (docs.isEmpty) {
        return 'Khách hàng chưa có đơn hàng nào.';
      }

      final ordersList = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        final total = int.tryParse(data['totalPrice']?.toString() ?? data['total']?.toString() ?? '0') ?? 0;
        final itemNames = items.map((item) => (item as Map<String, dynamic>)['productName'] ?? 'N/A').join(', ');
        
        return '''
Đơn hàng #${data['orderId'] ?? 'N/A'}
   - Trạng thái: ${data['status'] ?? 'N/A'}
   - Số lượng: ${items.length} sản phẩm
   - Tổng tiền: ${Formatter.formatCurrency(total)}
   - Ngày đặt: ${_formatDate(data['timestamp'] ?? data['orderDate'])}
   - Sản phẩm: $itemNames
   - Địa chỉ: ${data['address'] ?? 'N/A'}
        ''';
      }).join('\n---\n');

      return 'Các đơn hàng gần đây của khách hàng:\n$ordersList';
    } catch (e) {
      try {
        final fallbackSnapshot = await FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .limit(10)
            .get();
        
        if (fallbackSnapshot.docs.isEmpty) {
          return 'Khách hàng chưa có đơn hàng nào.';
        }
        
        final ordersList = fallbackSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['items'] as List? ?? [];
          final total = int.tryParse(data['totalPrice']?.toString() ?? data['total']?.toString() ?? '0') ?? 0;
          final itemNames = items.map((item) => (item as Map<String, dynamic>)['productName'] ?? 'N/A').join(', ');
          
          return '''
Đơn hàng #${data['orderId'] ?? 'N/A'}
   - Trạng thái: ${data['status'] ?? 'N/A'}
   - Số lượng: ${items.length} sản phẩm
   - Tổng tiền: ${Formatter.formatCurrency(total)}
   - Sản phẩm: $itemNames
        ''';
        }).join('\n---\n');
        
        return 'Các đơn hàng của khách hàng:\n$ordersList';
      } catch (fallbackError) {
        return 'Lỗi khi lấy thông tin đơn hàng: $e';
      }
    }
  }

  static Future<String> getProductsContext() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      if (snapshot.docs.isEmpty) {
        return 'Hiện tại không có sản phẩm nào trong kho.';
      }

      final productsList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final price = int.tryParse(data['productprice']?.toString() ?? '0') ?? 0;
        final priceFormatted = (price / 1000000).toStringAsFixed(1);
        final description = (data['description'] ?? '').toString();
        final shortDescription = description.length > 100 
            ? '${description.substring(0, 100)}...' 
            : description;
        return '''
${data['productname'] ?? 'N/A'} (${data['brandId'] ?? 'N/A'})
   - Giá: ${priceFormatted} triệu VND
   - Danh mục: ${data['title'] ?? 'N/A'}
   - Mô tả: ${shortDescription}
        ''';
      }).join('\n');

      return 'Sản phẩm có sẵn trong cửa hàng (Tổng: ${snapshot.docs.length} sản phẩm):\n$productsList';
    } catch (e) {
      return 'Lỗi khi lấy danh sách sản phẩm: $e';
    }
  }

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
}

