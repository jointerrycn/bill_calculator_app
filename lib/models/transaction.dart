// lib/models/transaction.dart
import 'package:bill_calculator_app/models/ordered_item.dart'; // Đảm bảo import OrderedItem

class Transaction {
  final String tableId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration totalPlayTime;
  final double billAmount; // Tổng tiền bàn
  final List<OrderedItem> orderedItems; // Danh sách đồ ăn đã gọi
  final double totalOrderedItemsAmount; // Tổng tiền đồ ăn
  final double finalBillAmount; // Tổng tiền cuối cùng (bàn + đồ ăn)
  final DateTime transactionTime; // Thời điểm giao dịch được ghi lại

  Transaction({
    required this.tableId,
    required this.startTime,
    required this.endTime,
    required this.totalPlayTime,
    required this.billAmount,
    required this.orderedItems,
    required this.totalOrderedItemsAmount,
    required this.finalBillAmount,
    required this.transactionTime,
  });

  // Factory constructor để tạo Transaction từ JSON (khi load từ shared_preferences)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      tableId: json['tableId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      totalPlayTime: Duration(microseconds: json['totalPlayTime'] as int),
      billAmount: json['billAmount'] as double,
      orderedItems: (json['orderedItems'] as List<dynamic>)
          .map((itemJson) => OrderedItem.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
      totalOrderedItemsAmount: json['totalOrderedItemsAmount'] as double,
      finalBillAmount: json['finalBillAmount'] as double,
      transactionTime: DateTime.parse(json['transactionTime'] as String),
    );
  }

  // Phương thức chuyển đổi Transaction thành JSON (khi lưu vào shared_preferences)
  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalPlayTime': totalPlayTime.inMicroseconds, // Lưu Duration dưới dạng microseconds
      'billAmount': billAmount,
      'orderedItems': orderedItems.map((item) => item.toJson()).toList(),
      'totalOrderedItemsAmount': totalOrderedItemsAmount,
      'finalBillAmount': finalBillAmount,
      'transactionTime': transactionTime.toIso8601String(),
    };
  }
}