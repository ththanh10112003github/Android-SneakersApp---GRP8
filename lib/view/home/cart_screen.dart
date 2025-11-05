import 'package:ecommerce_app/model/product_selection_state.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/round_button.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:flutter/material.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PersistentShoppingCart cart = PersistentShoppingCart();
  final Map<String, bool> _selectedItems = {};
  bool _selectAll = false;

  void _initializeSelection(List<PersistentShoppingCartItem> items) {
    bool allSelected = true;
    for (var item in items) {
      if (!_selectedItems.containsKey(item.productId)) {
        _selectedItems[item.productId] = true;
      }
      if (!(_selectedItems[item.productId] ?? false)) {
        allSelected = false;
      }
    }
    setState(() {
      _selectAll = allSelected;
    });
  }

  void _toggleItemSelection(String productId) {
    setState(() {
      _selectedItems[productId] = !(_selectedItems[productId] ?? false);
      _selectAll = _selectedItems.values.every((selected) => selected);
    });
  }

  void _toggleSelectAll(List<PersistentShoppingCartItem> items) {
    setState(() {
      _selectAll = !_selectAll;
      for (var item in items) {
        _selectedItems[item.productId] = _selectAll;
      }
    });
  }

  double _calculateSelectedTotal(List<PersistentShoppingCartItem> items) {
    double total = 0.0;
    for (var item in items) {
      if (_selectedItems[item.productId] ?? false) {
        total += item.unitPrice * item.quantity;
      }
    }
    return total;
  }

  List<PersistentShoppingCartItem> _getSelectedItems(List<PersistentShoppingCartItem> items) {
    return items.where((item) => _selectedItems[item.productId] ?? false).toList();
  }

  String? _validateBeforeCheckout(List<PersistentShoppingCartItem> items) {
    final selectedItems = _getSelectedItems(items);
    
    if (selectedItems.isEmpty) {
      return 'Vui lòng chọn ít nhất một sản phẩm để thanh toán';
    }

    for (var item in selectedItems) {
      if (item.quantity <= 0) {
        return 'Sản phẩm "${item.productName}" có số lượng không hợp lệ';
      }
      
      if (item.productDetails == null || 
          item.productDetails!['size'] == null || 
          item.productDetails!['color'] == null) {
        return 'Sản phẩm "${item.productName}" thiếu thông tin size hoặc color';
      }
      
      if (item.unitPrice <= 0) {
        return 'Sản phẩm "${item.productName}" có giá không hợp lệ';
      }
    }

    return null;
  }

  Future<void> _showEditSizeColorDialog(
    BuildContext context,
    PersistentShoppingCartItem item,
  ) async {
    String selectedSize = item.productDetails?['size']?.toString() ?? '38';
    String selectedColorName = item.productDetails?['color']?.toString() ?? 'Blue';
    Color selectedColor = ProductColors.getColorFromName(selectedColorName);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn Size và Màu sắc',
                        style: TextStyle(
                          fontFamily: 'Raleway-Bold',
                          fontSize: 18,
                          color: Color(0xff1A2530),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontFamily: 'Poppins-Medium',
                      fontSize: 14,
                      color: Color(0xff707BB1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Kích thước',
                    style: TextStyle(
                      fontFamily: 'Poppins-Medium',
                      fontSize: 15,
                      color: Color(0xff1A2530),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ProductSizes.available.map((size) {
                      final isSelected = selectedSize == size;
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedSize = size;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? selectedColor
                                : Colors.grey.shade200,
                            border: Border.all(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.grey.shade400,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              size,
                              style: TextStyle(
                                fontFamily: 'Poppins-Medium',
                                fontSize: 14,
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Màu sắc',
                    style: TextStyle(
                      fontFamily: 'Poppins-Medium',
                      fontSize: 15,
                      color: Color(0xff1A2530),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ProductColors.available.map((colorData) {
                      final colorName = colorData['name'] as String;
                      final color = Color(colorData['color'] as int);
                      final isSelected = selectedColorName == colorName;
                      
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedColorName = colorName;
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _updateCartItemSizeColor(item, selectedSize, selectedColorName);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.backgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontFamily: 'Raleway-Bold',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateCartItemSizeColor(
    PersistentShoppingCartItem item,
    String newSize,
    String newColor,
  ) {
    if (!mounted) return;
    
    final currentSize = item.productDetails?['size']?.toString() ?? '';
    final currentColor = item.productDetails?['color']?.toString() ?? '';
    
    if (currentSize == newSize && currentColor == newColor) {
      return;
    }
    
    final currentQuantity = item.quantity;
    final currentPrice = item.unitPrice;
    final wasSelected = _selectedItems[item.productId] ?? false;
    
    cart.removeFromCart(item.productId);
    
    final updatedItem = PersistentShoppingCartItem(
      productThumbnail: item.productThumbnail,
      productId: item.productId,
      productName: item.productName,
      unitPrice: currentPrice,
      quantity: currentQuantity,
      productDetails: {
        'size': newSize,
        'color': newColor,
      },
    );
    
    cart.addToCart(updatedItem);
    
    if (wasSelected) {
      setState(() {
        _selectedItems[item.productId] = true;
      });
    }
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        GeneralUtils().showsuccessflushbar(
          'Đã cập nhật Size và Màu sắc',
          context,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f9),
      appBar: AppBar(
        backgroundColor: const Color(0xfff7f7f9),
        title: const Text('Giỏ hàng'),
        titleTextStyle: TextStyling.apptitle,
        centerTitle: true,
        leading: SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Column(
            children: [
              cart.showCartItems(
                cartItemsBuilder: (context, data) {
                  if (data.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _initializeSelection(data);
                    });
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 0.80,
                            child: Checkbox(
                              value: _selectAll,
                              onChanged: (value) {
                                _toggleSelectAll(data);
                              },
                              activeColor: AppColor.backgroundColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Chọn tất cả',
                            style: TextStyle(
                              fontFamily: 'Poppins-Medium',
                              fontSize: 14,
                              color: Color(0xff1A2530),
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Đã chọn: ${_getSelectedItems(data).length}/${data.length}',
                            style: const TextStyle(
                              fontFamily: 'Poppins-Medium',
                              fontSize: 12,
                              color: Color(0xff707BB1),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
              Expanded(
                child: cart.showCartItems(
                  cartItemsBuilder: (context, data) {
                    if (data.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Giỏ hàng đang rỗng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  RouteNames.navbarscreen,
                                  (route) => false,
                                );
                              },
                              child: const Text('Tiếp tục mua sắm'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _initializeSelection(data);
                    });
                    
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final isSelected = _selectedItems[item.productId] ?? false;
                        
                        return Dismissible(
                          key: Key(item.productId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text(
                                    'Xác nhận xóa',
                                    style: TextStyle(
                                      fontFamily: 'Raleway-Bold',
                                      fontSize: 18,
                                    ),
                                  ),
                                  content: Text(
                                    'Bạn có chắc chắn muốn xóa "${item.productName}" khỏi giỏ hàng?',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins-Medium',
                                      fontSize: 14,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Hủy',
                                        style: TextStyle(
                                          fontFamily: 'Poppins-Medium',
                                          color: Color(0xff707B81),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        'Xóa',
                                        style: TextStyle(
                                          fontFamily: 'Raleway-Bold',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            setState(() {
                              _selectedItems.remove(item.productId);
                            });
                            cart.removeFromCart(item.productId);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            height: 104,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected 
                                    ? AppColor.backgroundColor 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(width: 6),
                                Transform.scale(
                                  scale: 0.70,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      _toggleItemSelection(item.productId);
                                    },
                                    activeColor: AppColor.backgroundColor,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.productThumbnail.toString(),
                                    height: 50,
                                    width: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 50,
                                        width: 60,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image_not_supported, size: 18),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item.productName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: InkWell(
                                                onTap: () {
                                                  _showEditSizeColorDialog(context, item);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: Colors.grey.shade300,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          'Size: ${item.productDetails?['size']?.toString() ?? 'N/A'} | Màu: ${item.productDetails?['color']?.toString() ?? 'N/A'}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w400,
                                                            color: Color(0xff1A2530),
                                                            fontSize: 9,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      const Icon(
                                                        Icons.arrow_drop_down,
                                                        size: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              cart.decrementCartItemQuantity(
                                                item.productId,
                                              );
                                            },
                                            child: const Icon(
                                              Icons.remove_circle_outlined,
                                              color: AppColor.buttonColorTwo,
                                              size: 18,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            child: Text(
                                              item.quantity.toString(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              cart.incrementCartItemQuantity(
                                                item.productId,
                                              );
                                            },
                                            child: const Icon(
                                              Icons.add_circle_outlined,
                                              color: AppColor.buttonColorTwo,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          Formatter.formatCurrency(
                                              item.unitPrice.toInt()),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              cart.showTotalAmountWidget(
                cartTotalAmountWidgetBuilder: (totalAmount) => cart.showCartItems(
                  cartItemsBuilder: (context, data) {
                    final selectedTotal = _calculateSelectedTotal(data);
                    final selectedCount = _getSelectedItems(data).length;
                    
                    return Visibility(
                      visible: data.isNotEmpty,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: AppColor.backgroundColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Đã chọn $selectedCount sản phẩm',
                                          style: TextStyle(
                                            fontFamily: 'Poppins-Medium',
                                            fontSize: 12,
                                            color: AppColor.backgroundColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (selectedCount > 0) const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      'Thành tiền',
                                      style: TextStyle(
                                        fontFamily: 'Raleway-SemiBold',
                                        color: Color(0xff707B81),
                                        fontSize: 16,
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      Formatter.formatCurrency(selectedTotal.toInt()),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins-Medium',
                                        color: Color(0xff1A2530),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Giảm giá',
                                      style: TextStyle(
                                        fontFamily: 'Raleway-SemiBold',
                                        color: Color(0xff707B81),
                                        fontSize: 16,
                                      ),
                                    ),
                                    Spacer(),
                                    const Text(
                                      '0',
                                      style: TextStyle(
                                        fontFamily: 'Poppins-Medium',
                                        color: Color(0xff1A2530),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: Colors.black),
                                Row(
                                  children: [
                                    const Text(
                                      'Tổng cộng',
                                      style: TextStyle(
                                        fontFamily: 'Poppins-Medium',
                                        color: Color(0xff1A2530),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      Formatter.formatCurrency(selectedTotal.toInt()),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins-Medium',
                                        color: Color(0xff1A2530),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                RoundButtonTwo(
                                  onpress: () {
                                    final validationError = _validateBeforeCheckout(data);
                                    if (validationError != null) {
                                      GeneralUtils().showerrorflushbar(
                                        validationError,
                                        context,
                                      );
                                      return;
                                    }
                                    
                                    final selectedItems = _getSelectedItems(data);
                                    if (selectedItems.isEmpty) {
                                      GeneralUtils().showerrorflushbar(
                                        'Vui lòng chọn ít nhất một sản phẩm để thanh toán',
                                        context,
                                      );
                                      return;
                                    }
                                    
                                    Navigator.pushNamed(
                                      context,
                                      RouteNames.checkOutScreen,
                                      arguments: selectedItems,
                                    );
                                  },
                                  title: 'Thanh toán',
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
      ),
    );
  }
}
