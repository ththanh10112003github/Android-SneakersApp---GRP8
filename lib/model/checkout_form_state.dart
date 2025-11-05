import 'package:ecommerce_app/respository/components/address_picker.dart';

/// Model để quản lý state khi người dùng đang thanh toán
class CheckoutFormState {
  final String name;
  final String email;
  final String phone;
  final String address;
  final FullAddress? structuredAddress;
  final double totalPrice;
  final List<Map<String, dynamic>> items;
  final bool isReadyToConfirm;

  CheckoutFormState({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.structuredAddress,
    required this.totalPrice,
    required this.items,
    this.isReadyToConfirm = false,
  });

  CheckoutFormState copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    FullAddress? structuredAddress,
    double? totalPrice,
    List<Map<String, dynamic>>? items,
    bool? isReadyToConfirm,
  }) {
    return CheckoutFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      structuredAddress: structuredAddress ?? this.structuredAddress,
      totalPrice: totalPrice ?? this.totalPrice,
      items: items ?? this.items,
      isReadyToConfirm: isReadyToConfirm ?? this.isReadyToConfirm,
    );
  }

  bool get isValid {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        address.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'totalPrice': totalPrice,
      'items': items,
      if (structuredAddress != null) ...structuredAddress!.toMap(),
    };
  }
}

