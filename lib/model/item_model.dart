class ItemModel {
  final String productId, productName, productDescription, productImage;
  final double unitPrice;
  final int? salePercent;
  
  const ItemModel({
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productImage,
    required this.unitPrice,
    this.salePercent,
  });
}
