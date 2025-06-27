// lib/screens/transaction_history_screen.dart
import 'package:bill_calculator_app/helper/extensions.dart';
import 'package:flutter/material.dart';
import 'package:bill_calculator_app/models/transaction.dart';
import 'package:bill_calculator_app/models/menu_item.dart'; // Để hiển thị tên món
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final List<MenuItem> menuItems; // Cần menuItems để hiển thị tên món trong OrderedItem

  const TransactionHistoryScreen({
    super.key,
    required this.transactions,
    required this.menuItems,
  });

  String _formatCurrency(double amount) {
    final oCcy = NumberFormat("#,##0", "vi_VN");
    return '${oCcy.format(amount.round())} VNĐ';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
    }
    return "${twoDigitMinutes}m ${twoDigitSeconds}s";
  }

  @override
  Widget build(BuildContext context) {
    // Sắp xếp giao dịch theo thời gian giảm dần (mới nhất lên đầu)
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.transactionTime.compareTo(a.transactionTime));

    // Tính tổng doanh thu
    final double totalRevenue = sortedTransactions.fold(0.0, (sum, transaction) => sum + transaction.finalBillAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Giao Dịch'),
        centerTitle: true,
      ),
      body: sortedTransactions.isEmpty
          ? const Center(
        child: Text('Chưa có giao dịch nào được ghi lại.'),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng Doanh Thu:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatCurrency(totalRevenue),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: sortedTransactions.length,
              itemBuilder: (context, index) {
                final transaction = sortedTransactions[index];
                final transactionDate = DateFormat('dd/MM/yyyy HH:mm').format(transaction.transactionTime);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4.0,
                  child: ExpansionTile(
                    title: Text(
                      'Bàn ${transaction.tableId} - ${transactionDate}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Tổng cộng: ${_formatCurrency(transaction.finalBillAmount)}',
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thời gian chơi: ${_formatDuration(transaction.totalPlayTime)}'),
                            Text('Tiền giờ: ${_formatCurrency(transaction.billAmount)}'),
                            if (transaction.orderedItems.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text('Đồ ăn đã gọi:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...transaction.orderedItems.map((orderedItem) {
                                final menuItem = menuItems.firstWhereOrNull((item) => item.id == orderedItem.itemId);
                                return Text(
                                  ' - ${menuItem?.name ?? orderedItem.itemId}: ${orderedItem.quantity} x ${_formatCurrency(menuItem?.price ?? 0.0)}',
                                  style: const TextStyle(fontSize: 14),
                                );
                              }).toList(),
                              Text('Tổng tiền đồ ăn: ${_formatCurrency(transaction.totalOrderedItemsAmount)}'),
                            ],
                            const Divider(),
                            Text(
                              'Tổng hóa đơn: ${_formatCurrency(transaction.finalBillAmount)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}