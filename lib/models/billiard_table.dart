// lib/models/billiard_table.dart
import 'package:flutter/material.dart';
import 'package:bill_calculator_app/models/ordered_item.dart';

class BilliardTable with ChangeNotifier {
  final String id;
  String name; // <--- THÊM DÒNG NÀY
  bool isOccupied;
  DateTime? startTime;
  DateTime? endTime;
  Duration totalPlayedTime; // Thời gian tích lũy khi dừng bàn
  List<OrderedItem> orderedItems;

  BilliardTable({
    required this.id,
    required this.name, // <--- THÊM DÒNG NÀY (hoặc đảm bảo nó có)
    this.isOccupied = false,
    this.startTime,
    this.endTime,
    this.totalPlayedTime = Duration.zero,
    List<OrderedItem>? orderedItems,
  }) : orderedItems = orderedItems ?? [];

  // Thêm getter để tính thời gian hiển thị (thời gian thực nếu đang chơi, hoặc tổng thời gian đã lưu)
  Duration get displayTotalTime {
    if (isOccupied && startTime != null) {
      return totalPlayedTime + DateTime.now().difference(startTime!);
    }
    return totalPlayedTime;
  }
  // Phương thức để cập nhật trạng thái bàn
  void toggleStatus() {
    if (isOccupied) { // Đang chơi -> Dừng
      totalPlayedTime += DateTime.now().difference(startTime!);
      startTime = null;
      isOccupied = false;
    } else { // Trống -> Bắt đầu
      startTime = DateTime.now();
      isOccupied = true;
    }
    notifyListeners(); // <-- Rất quan trọng: Thông báo cho các listener biết có thay đổi
  }

  // Phương thức để thêm món ăn
  void addOrderedItem(String itemId, int quantity) {
    // Kiểm tra xem món đã tồn tại chưa
    final existingItemIndex = orderedItems.indexWhere((item) => item.itemId == itemId);
    if (existingItemIndex != -1) {
      orderedItems[existingItemIndex] = orderedItems[existingItemIndex].copyWith(quantity: orderedItems[existingItemIndex].quantity + quantity);
    } else {
      orderedItems.add(OrderedItem(itemId: itemId, quantity: quantity));
    }
    notifyListeners(); // <-- Thông báo khi có món mới
  }

  // Factory constructor để tạo từ JSON
  factory BilliardTable.fromJson(Map<String, dynamic> json) {
    return BilliardTable(
      id: json['id'],
      name: json['name'],
      isOccupied: json['isOccupied'] ?? false,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      totalPlayedTime: Duration(microseconds: json['totalPlayedTime'] ?? 0),
      orderedItems: (json['orderedItems'] as List<dynamic>?)
          ?.map((itemJson) => OrderedItem.fromJson(itemJson))
          .toList() ??
          [],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isOccupied': isOccupied,
      'startTime': startTime?.toIso8601String(),
      'totalPlayedTime': totalPlayedTime.inMicroseconds,
      'orderedItems': orderedItems.map((item) => item.toJson()).toList(),
    };
  }

  void addOrUpdateOrderedItem(String itemId, int quantityChange) {
    final existingItemIndex = orderedItems.indexWhere((item) => item.itemId == itemId);
    if (existingItemIndex != -1) {
      orderedItems[existingItemIndex].quantity += quantityChange;
      if (orderedItems[existingItemIndex].quantity <= 0) {
        orderedItems.removeAt(existingItemIndex);
      }
    } else if (quantityChange > 0) {
      orderedItems.add(OrderedItem(itemId: itemId, quantity: quantityChange));
    }
    debugPrint('Bàn $id: Cập nhật món $itemId, số lượng $quantityChange. Danh sách: ${orderedItems.map((e) => '${e.itemId}:${e.quantity}').join(', ')}');
  }

  void start() {
    if (!isOccupied) {
      isOccupied = true;
      startTime = DateTime.now();
      endTime = null;
      orderedItems.clear();
      debugPrint('Bàn $id bắt đầu lúc: $startTime');
    }
  }

  void stop() {
    if (isOccupied) {
      isOccupied = false;
      endTime = DateTime.now();
      debugPrint('Bàn $id dừng lúc: $endTime, tổng thời gian chơi: $displayTotalTime');
    }
  }

  void reset() {
    isOccupied = false;
    startTime = null;
    endTime = null;
    orderedItems.clear();
    debugPrint('Bàn $id đã reset.');
  }

 /* Duration get displayTotalTime {
    if (startTime == null) return Duration.zero;
    if (isOccupied) {
      return DateTime.now().difference(startTime!);
    } else if (endTime != null) {
      return endTime!.difference(startTime!);
    }
    return Duration.zero;
  }*/
}