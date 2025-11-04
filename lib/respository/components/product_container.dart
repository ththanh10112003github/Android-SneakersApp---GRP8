import 'package:ecommerce_app/respository/components/app_styles.dart';
import 'package:flutter/material.dart';

class ProductContainer extends StatelessWidget {
  final String title, subtitle, price;
  final String id;
  final String imagelink;
  final IconButton fav;
  final int quantity;
  const ProductContainer({
    super.key,
    this.title = 'BÁN CHẠY',
    required this.subtitle,
    required this.imagelink,
    required this.price,
    required this.id,
    required this.quantity,
    required this.fav,
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
            Text(
              price,
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

///
class CartContainer extends StatelessWidget {
  final String imagelink;
  final String title;
  final String subtitle;
  final String price;

  const CartContainer({
    super.key,
    required this.imagelink,
    required this.price,
    required this.subtitle,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;

    return Container(
      height: 330,
      width: screenwidth * 0.1,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusDirectional.all(Radius.circular(16))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imagelink,
              height: 90,
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
            Text(
              price,
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
  final String title, subtitle, price;
  final String imagelink;
  final IconButton fav;
  final int quantity;
  final VoidCallback onclick;

  const ShowProductContainer(
      {super.key,
      this.title = 'BÁN CHẠY',
      required this.subtitle,
      required this.imagelink,
      required this.price,
      required this.quantity,
      required this.fav,
      required this.onclick});

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
              Text(
                price,
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
