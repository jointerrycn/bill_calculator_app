// lib/models/ordered_item.dart
class OrderedItem {
  final String itemId; // ID của MenuItem đã đặt
  int quantity; // Số lượng món đã đặt

  OrderedItem({required this.itemId, this.quantity = 1});
  // --- Thêm phương thức copyWith vào đây ---
  OrderedItem copyWith({
    String? itemId,
    int? quantity,
  }) {
    return OrderedItem(
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
    );
  }
  // Factory constructor để tạo OrderedItem từ Map (JSON)
  factory OrderedItem.fromJson(Map<String, dynamic> json) {
    return OrderedItem(
      itemId: json['itemId'],
      quantity: json['quantity'],
    );
  }

  // Phương thức để chuyển đổi OrderedItem thành Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'quantity': quantity,
    };
  }
}