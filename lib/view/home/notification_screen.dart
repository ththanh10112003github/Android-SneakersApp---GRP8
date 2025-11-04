import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool hasError = false;

  Future<void> initData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference productsCollection = firestore.collection('products');
      QuerySnapshot querySnapshot = await productsCollection.get();
      
      // Tạo danh sách thông báo từ products
      List<Map<String, dynamic>> tempNotifications = [];
      
      if (querySnapshot.docs.length > 4) {
        tempNotifications.add({
          'id': 'noti_1',
          'type': 'new_product',
          'title': 'Sản phẩm mới',
          'message': 'Chúng tôi có sản phẩm mới với ưu đãi đặc biệt',
          'product': querySnapshot.docs[4].data() as Map<String, dynamic>,
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'isRead': false,
        });
      }
      
      if (querySnapshot.docs.length > 6) {
        tempNotifications.add({
          'id': 'noti_2',
          'type': 'promotion',
          'title': 'Khuyến mãi',
          'message': 'Sản phẩm đang có ưu đãi hấp dẫn',
          'product': querySnapshot.docs[6].data() as Map<String, dynamic>,
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          'isRead': false,
        });
      }
      
      if (querySnapshot.docs.length > 7) {
        tempNotifications.add({
          'id': 'noti_3',
          'type': 'new_product',
          'title': 'Sản phẩm mới',
          'message': 'Sản phẩm mới đã có mặt tại cửa hàng',
          'product': querySnapshot.docs[7].data() as Map<String, dynamic>,
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'isRead': false,
        });
      }

      setState(() {
        notifications = tempNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f9),
      appBar: AppBar(
        backgroundColor: const Color(0xfff7f7f9),
        title: const Text('Thông báo'),
        titleTextStyle: TextStyling.apptitle,
        centerTitle: true,
        leading: const SizedBox.shrink(),
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                // TODO: Implement mark all as read
              },
              child: const Text(
                'Đánh dấu đã đọc',
                style: TextStyle(
                  color: AppColor.backgroundColor,
                  fontFamily: 'Raleway-Medium',
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColor.backgroundColor,
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontFamily: 'Raleway-Medium',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: initData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.backgroundColor,
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontFamily: 'Raleway-Medium',
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chúng tôi sẽ thông báo khi có sản phẩm mới',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: initData,
      color: AppColor.backgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index], index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final product = notification['product'] as Map<String, dynamic>;
    final timestamp = notification['timestamp'] as DateTime;
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to product details
              // Navigator.pushNamed(context, RouteNames.productsdetails, arguments: product);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isRead
                    ? null
                    : Border.all(
                        color: AppColor.backgroundColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hình ảnh sản phẩm
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product['imagelink'] ?? '',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: AppColor.backgroundColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Nội dung thông báo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Raleway-SemiBold',
                                      fontSize: 14,
                                      color: AppColor.backgroundColor,
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(timestamp),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification['message'] as String,
                              style: TextStyle(
                                fontFamily: 'Raleway-Medium',
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (product['unitprice'] != null)
                              Row(
                                children: [
                                  Text(
                                    Formatter.formatCurrency(
                                      double.parse(product['unitprice']).toInt(),
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Poppins Medium',
                                      fontSize: 14,
                                      color: AppColor.backgroundColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Xem ngay',
                                    style: TextStyle(
                                      fontFamily: 'Raleway-Medium',
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Badge chưa đọc ở góc trên bên phải
                  if (!isRead)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
