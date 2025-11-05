import 'package:flutter/material.dart';

class ProductSelectionState {
  final String? productId;
  final String? productName;
  final String? imageLink;
  final double? price;
  final String? selectedSize;
  final String? selectedColor;
  final bool isWaitingForSize;
  final bool isWaitingForColor;
  final bool isReadyToConfirm;

  ProductSelectionState({
    this.productId,
    this.productName,
    this.imageLink,
    this.price,
    this.selectedSize,
    this.selectedColor,
    this.isWaitingForSize = false,
    this.isWaitingForColor = false,
    this.isReadyToConfirm = false,
  });

  ProductSelectionState copyWith({
    String? productId,
    String? productName,
    String? imageLink,
    double? price,
    String? selectedSize,
    String? selectedColor,
    bool? isWaitingForSize,
    bool? isWaitingForColor,
    bool? isReadyToConfirm,
  }) {
    return ProductSelectionState(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageLink: imageLink ?? this.imageLink,
      price: price ?? this.price,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      isWaitingForSize: isWaitingForSize ?? this.isWaitingForSize,
      isWaitingForColor: isWaitingForColor ?? this.isWaitingForColor,
      isReadyToConfirm: isReadyToConfirm ?? this.isReadyToConfirm,
    );
  }

  bool get hasProduct => productId != null && productName != null;
  bool get hasSize => selectedSize != null && selectedSize!.isNotEmpty;
  bool get hasColor => selectedColor != null && selectedColor!.isNotEmpty;
  bool get isComplete => hasSize && hasColor;

  void reset() {
  }
}

class ProductSizes {
  static const List<String> available = ['38', '39', '40', '41', '42'];
}

class ProductColors {
  static const List<Map<String, dynamic>> available = [
    {'name': 'Blue', 'color': 0xFF2196F3},
    {'name': 'Red', 'color': 0xFFF44336},
    {'name': 'Grey', 'color': 0xFF9E9E9E},
  ];
  
  static Color getColorFromName(String name) {
    final color = available.firstWhere(
      (c) => c['name'].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => available[0],
    );
    return Color(color['color'] as int);
  }
  
  static String getNameFromColor(Color color) {
    final colorValue = color.value;
    for (var col in available) {
      if (col['color'] == colorValue) {
        return col['name'] as String;
      }
    }
    return 'Blue';
  }
}

