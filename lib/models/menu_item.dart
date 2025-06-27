// lib/models/menu_item.dart
class MenuItem {
  final String id; // ID duy nhất cho mỗi món
  final String name;
  final double price;

  MenuItem({required this.id, required this.name, required this.price});

  // Factory constructor để tạo MenuItem từ Map (JSON)
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(), // Đảm bảo chuyển đổi sang double
    );
  }

  // Phương thức để chuyển đổi MenuItem thành Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}