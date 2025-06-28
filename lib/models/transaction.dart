// lib/models/transaction.dart
import 'package:bill_calculator_app/models/ordered_item.dart'; // Đảm bảo đường dẫn đúng

class Transaction {
  final String id;
  final String tableId;
  final List<OrderedItem> orderedItems;
  final double initialBillAmount;
  final double discountAmount;
  final double finalBillAmount;
  final DateTime transactionTime;

  Transaction({
    required this.id,
    required this.tableId,
    required this.orderedItems,
    required this.initialBillAmount,
    required this.discountAmount,
    required this.finalBillAmount,
    required this.transactionTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tableId': tableId,
    'orderedItems': orderedItems.map((item) => item.toJson()).toList(),
    'initialBillAmount': initialBillAmount,
    'discountAmount': discountAmount,
    'finalBillAmount': finalBillAmount,
    'transactionTime': transactionTime.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      tableId: json['tableId'],
      orderedItems: (json['orderedItems'] as List)
          .map((itemJson) => OrderedItem.fromJson(itemJson))
          .toList(),
      initialBillAmount: json['initialBillAmount'].toDouble(),
      discountAmount: json['discountAmount'].toDouble(),
      finalBillAmount: json['finalBillAmount'].toDouble(),
      transactionTime: DateTime.parse(json['transactionTime']),
    );
  }
}