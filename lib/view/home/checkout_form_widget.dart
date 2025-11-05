import 'package:flutter/material.dart';
import 'package:ecommerce_app/model/checkout_form_state.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/respository/components/address_picker.dart';

class CheckoutFormWidget extends StatefulWidget {
  final CheckoutFormState checkoutState;
  final Function(CheckoutFormState) onConfirm;

  const CheckoutFormWidget({
    super.key,
    required this.checkoutState,
    required this.onConfirm,
  });

  @override
  State<CheckoutFormWidget> createState() => _CheckoutFormWidgetState();
}

class _CheckoutFormWidgetState extends State<CheckoutFormWidget> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  CheckoutFormState? _currentState;
  FullAddress? _currentAddress;

  @override
  void initState() {
    super.initState();
    _currentState = widget.checkoutState;
    _nameController = TextEditingController(text: widget.checkoutState.name);
    _emailController = TextEditingController(text: widget.checkoutState.email);
    _phoneController = TextEditingController(text: widget.checkoutState.phone);
    _addressController = TextEditingController(text: widget.checkoutState.address);
    _currentAddress = widget.checkoutState.structuredAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _currentState = CheckoutFormState(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        structuredAddress: _currentAddress,
        totalPrice: widget.checkoutState.totalPrice,
        items: widget.checkoutState.items,
        isReadyToConfirm: true,
      );
    });
  }

  Future<void> _editAddress() async {
    FullAddress? tempAddress = _currentAddress ?? FullAddress();
    
    final result = await showDialog<FullAddress>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Chỉnh sửa địa chỉ',
                style: TextStyle(
                  fontFamily: 'Raleway-Bold',
                  fontSize: 18,
                  color: Color(0xff2B2B2B),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: AddressPicker(
                    initialAddress: tempAddress,
                    onAddressChanged: (address) {
                      setDialogState(() {
                        tempAddress = address;
                      });
                    },
                    detailAddressHint: 'Số nhà, tên đường...',
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      fontFamily: 'Poppins-Medium',
                      fontSize: 14,
                      color: Color(0xff707B81),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempAddress != null) {
                      Navigator.pop(context, tempAddress);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(
                      fontFamily: 'Raleway-Bold',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _currentAddress = result;
        _addressController.text = result.fullAddressString;
        _updateState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Thông tin thanh toán',
            style: TextStyle(
              fontFamily: 'Raleway-Bold',
              fontSize: 16,
              color: Color(0xff1A2530),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _nameController,
            label: 'Tên người nhận',
            icon: Icons.person_outline,
            onChanged: (_) => _updateState(),
          ),
          const SizedBox(height: 12),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _updateState(),
          ),
          const SizedBox(height: 12),
          
          _buildTextField(
            controller: _phoneController,
            label: 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onChanged: (_) => _updateState(),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  icon: Icons.location_on_outlined,
                  onChanged: (_) => _updateState(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _editAddress,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: const Color(0xff707BB1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền:',
                  style: TextStyle(
                    fontFamily: 'Raleway-SemiBold',
                    fontSize: 14,
                    color: Color(0xff707B81),
                  ),
                ),
                Text(
                  Formatter.formatCurrency(_currentState!.totalPrice.toInt()),
                  style: const TextStyle(
                    fontFamily: 'Poppins-Medium',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1A2530),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currentState!.isValid
                  ? () {
                      widget.onConfirm(_currentState!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.backgroundColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Xác nhận thanh toán',
                style: TextStyle(
                  fontFamily: 'Raleway-Bold',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xff707BB1)),
        filled: true,
        fillColor: const Color(0xffF7F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xff707BB1), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(
        fontFamily: 'Poppins-Medium',
        fontSize: 14,
        color: Color(0xff1A2530),
      ),
    );
  }
}

