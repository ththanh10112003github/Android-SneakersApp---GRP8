import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:flutter/material.dart';

class ProductContainer extends StatelessWidget {
  final String title, subtitle;
  final String id;
  final String imagelink;
  final IconButton fav;
  final int quantity;
  final int? salePercent;
  final String originalPrice;
  final String salePrice;
  
  const ProductContainer({
    super.key,
    this.title = 'BÁN CHẠY',
    required this.subtitle,
    required this.imagelink,
    required this.originalPrice,
    required this.id,
    required this.quantity,
    required this.fav,
    this.salePercent,
    required this.salePrice,
  });

  @override
  Widget build(BuildContext context) {
    final screenheight = MediaQuery.of(context).size.height;
    final screenwidht = MediaQuery.of(context).size.width;

    return Container(
      height: screenheight * 0.5,
      width: screenwidht * 0.4,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusDirectional.all(Radius.circular(16))),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fav,
            Image.network(
              imagelink,
              height: 70,
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColor.backgroundColor,
              ),
            ),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Raleway-Medium',
                  fontSize: 15,
                  color: Colors.black),
            ),
            if (salePercent != null && salePercent! > 0) 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        salePrice,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$salePercent%',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    originalPrice,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              )
            else
              Text(
                originalPrice,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CartContainer extends StatelessWidget {
  final String title, subtitle;
  final String imagelink;
  final String originalPrice;
  final String salePrice;
  final int? salePercent;

  const CartContainer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagelink,
    required this.originalPrice,
    required this.salePrice,
    this.salePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imagelink,
              height: 70,
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColor.backgroundColor,
              ),
            ),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Raleway-Medium',
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            if (salePercent != null && salePercent! > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        salePrice,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$salePercent%',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    originalPrice,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              )
            else
              Text(
                originalPrice,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ShowProductContainer extends StatelessWidget {
  final String title, subtitle;
  final String imagelink;
  final IconButton fav;
  final int quantity;
  final VoidCallback onclick;
  final int? salePercent;
  final String originalPrice;
  final String salePrice;

  const ShowProductContainer({
    super.key,
    this.title = 'BÁN CHẠY',
    required this.subtitle,
    required this.imagelink,
    required this.originalPrice,
    required this.quantity,
    required this.fav,
    required this.onclick,
    this.salePercent,
    required this.salePrice,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onclick,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        width: 158,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusDirectional.all(
            Radius.circular(12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fav,
              Image.network(
                imagelink,
                height: 35,
              ),
              Text(
                title,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColor.backgroundColor),
              ),
              Text(
                subtitle,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),
              if (salePercent != null && salePercent! > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          salePrice,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$salePercent%',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      originalPrice,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  originalPrice,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}