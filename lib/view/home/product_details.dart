import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:ecommerce_app/respository/components/route_names.dart';
import 'package:ecommerce_app/utils/fav_provider.dart';
import 'package:ecommerce_app/utils/formatter.dart';
import 'package:ecommerce_app/utils/general_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';
import 'package:provider/provider.dart';

class ProductDetails extends StatefulWidget {
  final String title;
  final String price;
  final String image;
  final String unitprice;
  final String productid;
  final String description;
  final int? salePercent;

  const ProductDetails({
    super.key,
    required this.title,
    required this.price,
    required this.image,
    required this.unitprice,
    required this.productid,
    required this.description,
    this.salePercent,
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final db2 = FirebaseFirestore.instance.collection('Favourites');

  final id = FirebaseAuth.instance.currentUser!.uid.toString();

  final PersistentShoppingCart cart = PersistentShoppingCart();

  String sizePicker = '38';
  Color colorPicker = Colors.blue;
  bool _isAddingToCart = false;
  bool _hasImageError = false;

  Widget buildButtonColor(Color color) {
    final isSelected = colorPicker == color;
    return InkWell(
      onTap: () {
        colorPicker = color;
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(2),
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
          height: 32,
          width: 32,
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
  }

  Widget buildButtonSize(String size) {
    return InkWell(
      onTap: () {
        sizePicker = size;
        setState(() {});
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: sizePicker == size
              ? colorPicker
              : const Color.fromARGB(255, 229, 231, 232),
          boxShadow: sizePicker == size
              ? [
                  BoxShadow(
                    color: colorPicker.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              fontFamily: 'Poppins-Medium',
              fontSize: 14,
              color: sizePicker == size ? Colors.white : Colors.black,
              fontWeight: sizePicker == size ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    final favprovider = Provider.of<FavouriteProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f9),
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: cart.showCartItemCountWidget(
              cartItemCountWidgetBuilder: ((int itemCount) {
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.cartscreen);
                  },
                  child: Badge(
                    label: Text(itemCount.toString()),
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: SvgPicture.asset(
                        'images/cart.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(
            width: 10,
          )
        ],
        leading: InkWell(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.navbarscreen);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
        backgroundColor: const Color(0xfff7f7f9),
        title: const Text(
          'Sneakers Shop',
          style: TextStyle(fontFamily: 'Raleway-SemiBold', fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenwidth * 0.06,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Ảnh sản phẩm với loading và error handling
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screenheight * 0.28,
                    maxWidth: screenwidth * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _hasImageError
                        ? Container(
                            height: screenheight * 0.25,
                            width: screenwidth * 0.75,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Không thể tải ảnh',
                                  style: TextStyling.subheading,
                                ),
                              ],
                            ),
                          )
                        : Image.network(
                            widget.image,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Container(
                                height: screenheight * 0.25,
                                width: screenwidth * 0.75,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColor.backgroundColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_hasImageError) {
                                  setState(() {
                                    _hasImageError = true;
                                  });
                                }
                              });
                              return Container(
                                height: screenheight * 0.25,
                                width: screenwidth * 0.75,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Không thể tải ảnh',
                                      style: TextStyling.subheading,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(height: screenheight * 0.025),
              // Tên sản phẩm
              Text(
                widget.title,
                style: TextStyling.headingstyle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              // Danh mục
              Text(
                'Giày Nam',
                style: TextStyling.subheading.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 10),
              // Giá
              if (widget.salePercent != null && widget.salePercent! > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          Formatter.formatCurrency(
                            (double.parse(widget.price) * (100 - widget.salePercent!) / 100).toInt()
                          ),
                          style: TextStyling.headingstyle.copyWith(
                            fontSize: 22,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${widget.salePercent}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatter.formatCurrency(double.parse(widget.price).toInt()),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  Formatter.formatCurrency(double.parse(widget.price).toInt()),
                  style: TextStyling.headingstyle.copyWith(
                    fontSize: 20,
                    color: AppColor.backgroundColor,
                  ),
                ),
              const SizedBox(height: 12),
              // Mô tả
              Text(
                widget.description,
                style: TextStyling.subheading.copyWith(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Màu sắc
              Text(
                'Màu sắc',
                style: const TextStyle(
                  fontFamily: 'Poppins-Medium',
                  fontSize: 15,
                  color: Color(0xff2B2B2B),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Row(
                  children: [
                    buildButtonColor(Colors.blue),
                    buildButtonColor(Colors.red),
                    buildButtonColor(Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Kích thước
              Text(
                'Kích thước',
                style: const TextStyle(
                  fontFamily: 'Poppins-Medium',
                  fontSize: 15,
                  color: Color(0xff2B2B2B),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    buildButtonSize('38'),
                    buildButtonSize('39'),
                    buildButtonSize('40'),
                    buildButtonSize('41'),
                    buildButtonSize('42'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Nút yêu thích và thêm vào giỏ
              Row(
                children: [
                  // Nút yêu thích
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        if (favprovider.items.contains(widget.productid)) {
                          favprovider.remove(widget.productid);
                          db2
                              .doc(id)
                              .collection('items')
                              .doc(widget.productid)
                              .delete();
                        } else {
                          favprovider.add(widget.productid);
                          db2
                              .doc(id)
                              .collection('items')
                              .doc(widget.productid)
                              .set(
                            {
                              'name': widget.title,
                              'subtitle': 'BÁN CHẠY',
                              'image': widget.image,
                              'price': widget.price,
                              'description': widget.description,
                            },
                          );
                        }
                      },
                      icon: Icon(
                        favprovider.items.contains(widget.productid)
                            ? Icons.favorite
                            : Icons.favorite_border_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nút thêm vào giỏ
                  Expanded(
                    child: InkWell(
                      onTap: _isAddingToCart
                          ? null
                          : () async {
                              setState(() {
                                _isAddingToCart = true;
                              });
                              try {
                                final String color = colorPicker == Colors.red
                                    ? 'Red'
                                    : colorPicker == Colors.blue
                                        ? 'Blue'
                                        : 'Grey';
                                await cart.addToCart(
                                  PersistentShoppingCartItem(
                                    productThumbnail: widget.image,
                                    productId: widget.productid,
                                    productName: widget.title,
                                    unitPrice: double.parse(widget.unitprice),
                                    quantity: 1,
                                    productDetails: {
                                      "size": sizePicker,
                                      "color": color,
                                      "salePercent": widget.salePercent,
                                    },
                                  ),
                                );
                                if (mounted) {
                                  GeneralUtils().showsuccessflushbar(
                                    'Sản phẩm đã được thêm vào giỏ hàng',
                                    context,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Có lỗi xảy ra: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isAddingToCart = false;
                                  });
                                }
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isAddingToCart
                              ? AppColor.backgroundColor.withOpacity(0.7)
                              : AppColor.backgroundColor,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.backgroundColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_isAddingToCart)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            else
                              SvgPicture.asset(
                                'images/cart.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _isAddingToCart
                                  ? 'Đang thêm...'
                                  : 'Thêm Vào Giỏ Hàng',
                              style: TextStyling.buttonTextTwo.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenheight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
