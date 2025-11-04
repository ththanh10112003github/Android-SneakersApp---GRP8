import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedStatus = _getStatusFromIndex(_tabController.index);
      });
    });
    _selectedStatus = null; // Tất cả
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _getStatusFromIndex(int index) {
    switch (index) {
      case 0:
        return null; // Tất cả
      case 1:
        return 'pending';
      case 2:
        return 'processing';
      case 3:
        return 'shipped';
      case 4:
        return 'delivered';
      case 5:
        return 'cancelled';
      default:
        return null;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Chờ xử lý';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lịch sử đơn hàng',
          style: TextStyle(
            fontFamily: 'Raleway-SemiBold',
            color: Color(0xff2B2B2B),
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColor.backgroundColor,
              labelColor: AppColor.backgroundColor,
              unselectedLabelColor: const Color(0xff707B81),
              labelStyle: const TextStyle(
                fontFamily: 'Poppins-Medium',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins-Medium',
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Tất cả'),
                Tab(text: 'Chờ xử lý'),
                Tab(text: 'Đang xử lý'),
                Tab(text: 'Đang giao'),
                Tab(text: 'Đã giao'),
                Tab(text: 'Đã hủy'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColor.backgroundColor,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa có đơn hàng nào',
                    style: TextStyle(
                      fontFamily: 'Poppins-Medium',
                      fontSize: 16,
                      color: Color(0xff707B81),
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter orders by selected status and sort by timestamp
          final allOrders = snapshot.data!.docs;
          
          // Sort by timestamp (descending - newest first)
          final sortedOrders = List.from(allOrders);
          sortedOrders.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;
            
            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            
            return bTimestamp.compareTo(aTimestamp); // Descending order
          });
          
          // Filter by status
          final filteredOrders = _selectedStatus == null
              ? sortedOrders
              : sortedOrders.where((doc) {
                  final order = doc.data() as Map<String, dynamic>;
                  return (order['status'] ?? 'pending') == _selectedStatus;
                }).toList();

          if (filteredOrders.isEmpty && _selectedStatus != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có đơn hàng ${_getStatusLabel(_selectedStatus).toLowerCase()}',
                    style: const TextStyle(
                      fontFamily: 'Poppins-Medium',
                      fontSize: 16,
                      color: Color(0xff707B81),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index].data() as Map<String, dynamic>;
              final items = order['items'] as List<dynamic>;
              final status = order['status'] ?? 'pending';
              final statusColor = _getStatusColor(status);
              final statusLabel = _getStatusLabel(status);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Theme(
                  data: ThemeData(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    iconColor: AppColor.backgroundColor,
                    collapsedIconColor: const Color(0xff707B81),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Đơn hàng #${order['orderId']?.toString().substring(order['orderId'].toString().length - 8) ?? 'N/A'}',
                      style: const TextStyle(
                        fontFamily: 'Poppins-Medium',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xff2B2B2B),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng tiền: ${Formatter.formatCurrency(double.parse(order['totalPrice'].toString()).toInt())}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xff707B81),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 12,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      const Divider(height: 1),
                      ...items.map((item) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: item['productThumbnail'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['productThumbnail'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.image_outlined,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                          title: Text(
                            item['productName'] ?? 'Sản phẩm',
                            style: const TextStyle(
                              fontFamily: 'Poppins-Medium',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Số lượng: ${item['quantity']}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xff707B81),
                            ),
                          ),
                          trailing: Text(
                            Formatter.formatCurrency(
                                double.parse(item['unitPrice'].toString())
                                    .toInt()),
                            style: const TextStyle(
                              fontFamily: 'Poppins-Medium',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColor.backgroundColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Hàm lấy màu sắc tương ứng với trạng thái đơn hàng
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return const Color(0xff0D6EFD);
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
