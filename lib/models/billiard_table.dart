// lib/models/billiard_table.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bill_calculator_app/models/ordered_item.dart';

class BilliardTable with ChangeNotifier {
  final String id;
  String name;
  double price; // Giá
  bool isOccupied;
  DateTime? startTime;
  DateTime? endTime;
  Duration totalPlayedTime; // Thời gian tích lũy khi dừng bàn
  List<OrderedItem> orderedItems;
  Timer? _timer; // Timer để cập nhật thời gian chơi

  BilliardTable({
    required this.id,
    required this.name,
    required this.price,
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
  void addOrderedItem(String itemId, int quantity, String name, double price) {
    // Kiểm tra xem món đã tồn tại chưa
    final existingItemIndex = orderedItems.indexWhere((item) => item.itemId == itemId);
    if (existingItemIndex != -1) {
      orderedItems[existingItemIndex] = orderedItems[existingItemIndex].copyWith(quantity: orderedItems[existingItemIndex].quantity + quantity);
    } else {
      orderedItems.add(OrderedItem(itemId: itemId, quantity: quantity,name: name, price: price));
    }
    notifyListeners(); // <-- Thông báo khi có món mới
  }

  // Factory constructor để tạo từ JSON
  factory BilliardTable.fromJson(Map<String, dynamic> json) {
    final table = BilliardTable(
      id: json['id'],
      name: json['name'],
      price: json['price']?.toDouble() ?? 0.0,
      isOccupied: json['isOccupied'] ?? false,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      totalPlayedTime: Duration(microseconds: json['totalPlayedTime'] ?? 0),
      orderedItems: (json['orderedItems'] as List<dynamic>?)
          ?.map((itemJson) => OrderedItem.fromJson(itemJson))
          .toList() ??
          [],
    );
    // Nếu bàn đang bận khi tải từ JSON, hãy khởi động lại timer
    if (table.isOccupied) {
      table._startTimer();
    }
    return table;
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isOccupied': isOccupied,
      'startTime': startTime?.toIso8601String(),
      'totalPlayedTime': totalPlayedTime.inMicroseconds,
      'orderedItems': orderedItems.map((item) => item.toJson()).toList(),
    };
  }

  void addOrUpdateOrderedItem(String itemId, int quantityChange, String name, double price) {
    final existingItemIndex = orderedItems.indexWhere((item) => item.itemId == itemId);
    if (existingItemIndex != -1) {
      orderedItems[existingItemIndex].quantity += quantityChange;
      if (orderedItems[existingItemIndex].quantity <= 0) {
        orderedItems.removeAt(existingItemIndex);
      }
    } else if (quantityChange > 0) {
      orderedItems.add(OrderedItem(itemId: itemId, quantity: quantityChange, name: name, price: price));
    }
    debugPrint('Bàn $id: Cập nhật món $itemId, số lượng $quantityChange. Danh sách: ${orderedItems.map((e) => '${e.itemId}:${e.quantity}').join(', ')}');
  }

  void start() {
    if (!isOccupied) {
      isOccupied = true;
      startTime = DateTime.now();
      endTime = null;
      orderedItems.clear();
      _startTimer(); // Bắt đầu timer
      notifyListeners(); // Thông báo thay đổi trạng thái
    }
  }

  void stop() {
    if (isOccupied && startTime != null) {
      // Cộng dồn thời gian của phiên hiện tại vào totalPlayedTime
      totalPlayedTime += DateTime.now().difference(startTime!);
      isOccupied = false;
      startTime = null; // Đặt lại startTime
      endTime = DateTime.now();
      // Để orderedItems và totalPlayedTime cho đến khi thanh toán xong
      // hoặc resetTable được gọi sau khi hóa đơn được in.
      notifyListeners();
    }
  }

  void reset() {
    isOccupied = false;
    startTime = null;
    endTime = null;
    totalPlayedTime = Duration.zero;
    orderedItems.clear();
    notifyListeners();
  }
// Bắt đầu timer để cập nhật UI mỗi giây
  void _startTimer() {
    _timer?.cancel(); // Hủy timer cũ nếu có
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Chỉ notifyListeners nếu bàn đang bận để tránh rebuild không cần thiết
      if (isOccupied) {
        notifyListeners(); // <-- ĐÂY LÀ DÒNG QUAN TRỌNG NHẤT CHO CẬP NHẬT THỜI GIAN THỰC
      } else {
        _stopTimer(); // Nếu không bận nữa thì dừng timer
      }
    });
  }

  // Dừng timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
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