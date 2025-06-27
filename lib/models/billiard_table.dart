// lib/models/billiard_table.dart
import 'package:flutter/material.dart'; // Import để sử dụng Duration
import 'package:bill_calculator_app/models/ordered_item.dart';// Import OrderedItem

class BilliardTable {
  final String id; // ID duy nhất cho mỗi bàn (ví dụ: "Bàn 1", "Bàn 2")
  bool isOccupied; // Trạng thái: true nếu đang có người chơi, false nếu trống
  DateTime? startTime; // Thời điểm bắt đầu chơi
  DateTime? endTime;   // MỚI: Thời gian kết thúc phiên chơi
  Duration totalPlayedTime; // Tổng thời gian đã chơi (bao gồm cả các phiên trước)
  List<OrderedItem> orderedItems; // Danh sách đồ ăn/thức uống đã đặt cho bàn này


  BilliardTable({
    required this.id,
    this.isOccupied = false,
    this.startTime,
    this.endTime,
    this.totalPlayedTime = Duration.zero,
    List<OrderedItem>? orderedItems, // Khởi tạo optional
  }) : orderedItems = orderedItems ?? []; // Gán nếu có, nếu không thì là list rỗng


  // Thêm factory constructor để tạo BilliardTable từ Map (JSON)
 /* factory BilliardTable.fromJson(Map<String, dynamic> json) {
    // Giải mã danh sách orderedItems từ JSON
    final List<dynamic> orderedItemsJson = json['orderedItems'] ?? [];
    final List<OrderedItem> orderedItems = orderedItemsJson
        .map((itemJson) => OrderedItem.fromJson(itemJson as Map<String, dynamic>))
        .toList();
    return BilliardTable(
      id: json['id'],
      isOccupied: json['isOccupied'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      totalPlayedTime: json['totalPlayedTime'] != null
          ? Duration(microseconds: json['totalPlayedTime'])
          : Duration.zero,
      orderedItems: orderedItems, // Gán danh sách đã giải mã
    );
  }*/
// Factory constructor để tạo BilliardTable từ JSON
  factory BilliardTable.fromJson(Map<String, dynamic> json) {
    return BilliardTable(
      id: json['id'] as String,
      isOccupied: json['isOccupied'] as bool,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null, // Xử lý null
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,     // Xử lý null
      orderedItems: (json['orderedItems'] as List<dynamic>?)
          ?.map((itemJson) => OrderedItem.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
    );
  }

  // Thêm phương thức để chuyển đổi BilliardTable thành Map (JSON)
  /*Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isOccupied': isOccupied,
      'startTime': startTime?.toIso8601String(),
      'totalPlayedTime': totalPlayedTime.inMicroseconds,
      'orderedItems': orderedItems.map((item) => item.toJson()).toList(), // Chuyển đổi orderedItems sang JSON
    };
  }*/
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isOccupied': isOccupied,
      'startTime': startTime?.toIso8601String(), // Lưu dưới dạng chuỗi ISO 8601, có thể null
      'endTime': endTime?.toIso8601String(),     // Lưu dưới dạng chuỗi ISO 8601, có thể null
      'orderedItems': orderedItems.map((item) => item.toJson()).toList(),
    };
  }

  // Phương thức để thêm/cập nhật OrderedItem
  void addOrUpdateOrderedItem(String itemId, int quantityChange) {
    final existingItemIndex = orderedItems.indexWhere((item) => item.itemId == itemId);
    if (existingItemIndex != -1) {
      // Nếu món đã tồn tại, cập nhật số lượng
      orderedItems[existingItemIndex].quantity += quantityChange;
      if (orderedItems[existingItemIndex].quantity <= 0) {
        // Nếu số lượng <= 0, xóa món khỏi danh sách
        orderedItems.removeAt(existingItemIndex);
      }
    } else if (quantityChange > 0) {
      // Nếu chưa tồn tại và số lượng thêm > 0, thêm món mới
      orderedItems.add(OrderedItem(itemId: itemId, quantity: quantityChange));
    }
    debugPrint('Bàn ${id}: Cập nhật món ${itemId}, số lượng ${quantityChange}. Danh sách: ${orderedItems.map((e) => '${e.itemId}:${e.quantity}').join(', ')}');
  }


  // Phương thức để bắt đầu chơi
  void start() {
    if (!isOccupied) {
      isOccupied = true;
      startTime = DateTime.now();
      endTime = null; // Đảm bảo endTime là null khi bắt đầu phiên mới
      orderedItems.clear(); // Xóa các món đã gọi khi bắt đầu phiên mới
      debugPrint('Bàn $id bắt đầu lúc: $startTime');
    }
  }

  // Phương thức để dừng chơi và cập nhật tổng thời gian
/*  void stop() {
    if (isOccupied && startTime != null) {
      final Duration currentSessionDuration = DateTime.now().difference(startTime!);
      totalPlayedTime += currentSessionDuration;
      isOccupied = false;
      startTime = null; // Đặt lại thời gian bắt đầu
      endTime = DateTime.now(); // Ghi nhận thời gian dừng
      debugPrint('Bàn $id đã dừng. Thời gian chơi phiên này: $currentSessionDuration. Tổng thời gian: $totalPlayedTime');
    }
  }*/
  void stop() {
    if (isOccupied) {
      isOccupied = false;
      endTime = DateTime.now(); // Ghi nhận thời gian dừng
      debugPrint('Bàn $id dừng lúc: $endTime, tổng thời gian chơi: $displayTotalTime');
    }
  }
  // Phương thức để reset bàn (đặt lại trạng thái trống và tổng thời gian)
  /*void reset() {
    isOccupied = false;
    startTime = null;
    totalPlayedTime = Duration.zero;
    orderedItems.clear(); // Xóa tất cả đồ ăn khi reset
    debugPrint('Bàn $id đã được reset.');
  }*/
  void reset() {
    isOccupied = false;
    startTime = null; // Đặt lại thời gian bắt đầu
    endTime = null;   // Đặt lại thời gian kết thúc
    orderedItems.clear();
    debugPrint('Bàn $id đã reset.');
  }


/*  // Phương thức để lấy thời gian chơi hiện tại của phiên (nếu đang chơi)
  Duration getCurrentSessionDuration() {
    if (isOccupied && startTime != null) {
      return DateTime.now().difference(startTime!);
    }
    return Duration.zero;
  }*/

  // Phương thức để lấy tổng thời gian hiển thị (tổng thời gian đã chơi + thời gian phiên hiện tại)
  Duration get displayTotalTime {
    if (startTime == null) return Duration.zero;
    if (isOccupied) {
      // Nếu bàn đang chơi, tính thời gian từ startTime đến hiện tại
      return DateTime.now().difference(startTime!);
    } else if (endTime != null) {
      // Nếu bàn đã dừng, tính thời gian từ startTime đến endTime đã ghi nhận
      return endTime!.difference(startTime!);
    }
    return Duration.zero; // Nếu không chơi và không có endTime (ví dụ: vừa reset)
  }
}