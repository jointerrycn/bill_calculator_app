// lib/models/ordered_item.dart

class OrderedItem {
  final String itemId;    // ID của MenuItem đã đặt (để tham chiếu đến menu gốc nếu cần)
  final String name;      // Tên của món hàng tại thời điểm đặt (ví dụ: "Coca-cola")
  final double price;     // Đơn giá của món hàng tại thời điểm đặt (ví dụ: 15000.0)
  int quantity;           // Số lượng món đã đặt

  OrderedItem({
    required this.itemId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  /// Phương thức copyWith để tạo một bản sao với các thuộc tính được cập nhật.
  OrderedItem copyWith({
    String? itemId,
    String? name,
    double? price,
    int? quantity,
  }) {
    return OrderedItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Factory constructor để tạo OrderedItem từ Map (JSON).
  factory OrderedItem.fromJson(Map<String, dynamic> json) {
    return OrderedItem(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      price: json['price'] as double,
      quantity: json['quantity'] as int,
    );
  }

  /// Phương thức để chuyển đổi OrderedItem thành Map (JSON).
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  // Getter tiện ích để tính tổng giá của món hàng này
  double get totalPrice => quantity * price;

  @override
  String toString() {
    return 'OrderedItem(itemId: $itemId, name: $name, price: $price, quantity: $quantity)';
  }
}