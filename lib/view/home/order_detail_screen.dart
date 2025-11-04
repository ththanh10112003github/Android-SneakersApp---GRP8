import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(widget.orderId)
          .get();

      if (orderSnapshot.exists) {
        setState(() {
          orderData = orderSnapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'processing':
        return 'Chờ lấy hàng';
      case 'shipped':
        return 'Chờ giao hàng';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Chờ xác nhận';
    }
  }

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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
    return 'N/A';
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Xác nhận hủy đơn hàng',
            style: TextStyle(
              fontFamily: 'Raleway-SemiBold',
              fontSize: 20,
              color: Color(0xff2B2B2B),
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn hủy đơn hàng này? Hành động này không thể hoàn tác.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xff707B81),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Không',
                style: TextStyle(
                  fontFamily: 'Raleway-Medium',
                  color: Color(0xff707B81),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Hủy đơn hàng',
                style: TextStyle(
                  fontFamily: 'Raleway-Medium',
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final utilsProvider = Provider.of<GeneralUtils>(context, listen: false);
    utilsProvider.showloading(true);

    try {
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(widget.orderId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      utilsProvider.showloading(false);

      if (mounted) {
        GeneralUtils().showsuccessflushbar(
          'Đơn hàng đã được hủy thành công',
          context,
        );
        _fetchOrderDetails(); // Refresh data
      }
    } catch (e) {
      utilsProvider.showloading(false);
      
      if (mounted) {
        GeneralUtils().showerrorflushbar(
          'Không thể hủy đơn hàng: ${e.toString()}',
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xff2B2B2B),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Chi tiết đơn hàng',
            style: TextStyling.apptitle,
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColor.backgroundColor,
          ),
        ),
      );
    }

    if (hasError || orderData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xff2B2B2B),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Chi tiết đơn hàng',
            style: TextStyling.apptitle,
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy đơn hàng',
                style: TextStyling.formtextstyle.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final status = orderData!['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final items = orderData!['items'] as List<dynamic>;
    final canCancel = status == 'pending' || status == 'processing';

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff2B2B2B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(
            fontFamily: 'Raleway-SemiBold',
            color: Color(0xff2B2B2B),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card thông tin đơn hàng
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mã đơn hàng',
                            style: TextStyling.subheading.copyWith(fontSize: 12),
                          ),
                          Text(
                            '#${orderData!['orderId']?.toString().substring(orderData!['orderId'].toString().length - 8) ?? 'N/A'}',
                            style: TextStyling.formtextstyle.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trạng thái',
                            style: TextStyling.subheading.copyWith(fontSize: 12),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ngày đặt',
                            style: TextStyling.subheading.copyWith(fontSize: 12),
                          ),
                          Text(
                            _formatDate(orderData!['timestamp']),
                            style: TextStyling.hinttext.copyWith(
                              fontSize: 14,
                              color: const Color(0xff2B2B2B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng tiền',
                            style: TextStyling.subheading.copyWith(fontSize: 12),
                          ),
                          Text(
                            Formatter.formatCurrency(
                              double.parse(orderData!['totalPrice'].toString()).toInt(),
                            ),
                            style: TextStyling.formtextstyle.copyWith(
                              fontSize: 18,
                              color: AppColor.backgroundColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card thông tin giao hàng
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin giao hàng',
                        style: TextStyling.formtextstyle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Người nhận',
                        orderData!['email'] ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Số điện thoại',
                        orderData!['phone'] ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Địa chỉ',
                        orderData!['address'] ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Danh sách sản phẩm
              Text(
                'Sản phẩm',
                style: TextStyling.formtextstyle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
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
                        style: TextStyling.hinttext.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff2B2B2B),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Số lượng: ${item['quantity']}',
                          style: TextStyling.subheading.copyWith(fontSize: 12),
                        ),
                      ),
                      trailing: Text(
                        Formatter.formatCurrency(
                          double.parse(item['unitPrice'].toString()).toInt(),
                        ),
                        style: TextStyling.hinttext.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColor.backgroundColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Button hủy đơn hàng (nếu có thể)
              if (canCancel)
                Consumer<GeneralUtils>(
                  builder: (context, utilsProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: utilsProvider.load ? null : _cancelOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: utilsProvider.load
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Hủy đơn hàng',
                                style: TextStyling.buttonTextTwo.copyWith(fontSize: 16),
                              ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xff6A6A6A),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyling.subheading.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyling.hinttext.copyWith(
                  fontSize: 14,
                  color: const Color(0xff2B2B2B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}