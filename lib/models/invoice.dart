// lib/models/invoice.dart
import 'package:uuid/uuid.dart';
import 'package:bill_calculator_app/models/ordered_item.dart'; // Import nếu OrderedItem được sử dụng trực tiếp trong Invoice

class Invoice {
  final String id;
  final String tableName; // Tên bàn khi giao dịch xảy ra
  final DateTime billDateTime; // Thời gian thanh toán
  final Duration playedDuration; // Tổng thời gian chơi của bàn
  final double hourlyRateAtTimeOfBill; // Giá giờ của bàn tại thời điểm thanh toán
  final double totalTableCost; // Tổng tiền bàn
  final List<OrderedItem> orderedItems; // Danh sách món đã gọi
  final double totalOrderedItemsCost; // Tổng tiền đồ ăn
  final double discountAmount; // Số tiền giảm giá
  final double finalAmount; // Tổng số tiền khách trả sau giảm giá

  Invoice({
    String? id,
    required this.tableName,
    required this.billDateTime,
    required this.playedDuration,
    required this.hourlyRateAtTimeOfBill,
    required this.totalTableCost,
    required this.orderedItems,
    required this.totalOrderedItemsCost,
    required this.discountAmount,
    required this.finalAmount,
  }) : id = id ?? const Uuid().v4();

  // Chuyển đổi Invoice thành Map để lưu vào SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableName': tableName,
      'billDateTime': billDateTime.toIso8601String(),
      'playedDuration': playedDuration.inMicroseconds,
      'hourlyRateAtTimeOfBill': hourlyRateAtTimeOfBill,
      'totalTableCost': totalTableCost,
      'orderedItems': orderedItems.map((item) => item.toJson()).toList(),
      'totalOrderedItemsCost': totalOrderedItemsCost,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
    };
  }

  // Chuyển đổi Map thành đối tượng Invoice
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      tableName: json['tableName'],
      billDateTime: DateTime.parse(json['billDateTime']),
      playedDuration: Duration(microseconds: json['playedDuration']),
      hourlyRateAtTimeOfBill: json['hourlyRateAtTimeOfBill'],
      totalTableCost: json['totalTableCost'],
      orderedItems: (json['orderedItems'] as List)
          .map((itemJson) => OrderedItem.fromJson(itemJson))
          .toList(),
      totalOrderedItemsCost: json['totalOrderedItemsCost'],
      discountAmount: json['discountAmount'],
      finalAmount: json['finalAmount'],
    );
  }
}