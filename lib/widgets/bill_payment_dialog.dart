// lib/widgets/bill_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Để dùng .firstWhereOrNull

import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';

import '../models/ordered_item.dart';

class BillPaymentDialog extends StatefulWidget {
  final BilliardTable table;
  final double initialTotalBill; // Tổng tiền trước khi áp dụng giảm giá

  const BillPaymentDialog({
    super.key,
    required this.table,
    required this.initialTotalBill,
  });

  @override
  State<BillPaymentDialog> createState() => _BillPaymentDialogState();
}

class _BillPaymentDialogState extends State<BillPaymentDialog> {
  TextEditingController _discountController = TextEditingController(text: '0');
  double _discount = 0;
  double _finalAmount = 0;

  @override
  void initState() {
    super.initState();
    _finalAmount = widget.initialTotalBill;
    _discountController.addListener(_updateFinalAmount);
  }

  @override
  void dispose() {
    _discountController.removeListener(_updateFinalAmount);
    _discountController.dispose();
    super.dispose();
  }

  void _updateFinalAmount() {
    setState(() {
      _discount = double.tryParse(_discountController.text) ?? 0;
      _finalAmount = widget.initialTotalBill - _discount;
      if (_finalAmount < 0) _finalAmount = 0; // Đảm bảo tiền không âm
    });
  }

  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context); // Không cần watch ở đây vì setState đã cập nhật
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Cần lấy lại thông tin bàn được cập nhật nhất từ provider
    final updatedTable = appDataProvider.billiardTables.firstWhere((t) => t.id == widget.table.id);

    final double playTimeHours = updatedTable.displayTotalTime.inMinutes / 60.0;
    final double hourlyCost = playTimeHours * appDataProvider.hourlyRate;

    double totalOrderedItemsCost = 0;
    for (var orderedItem in updatedTable.orderedItems) {
      final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull((menu) => menu.id == orderedItem.itemId);
      if (item != null) {
        totalOrderedItemsCost += item.price * orderedItem.quantity;
      }
    }
    // Tính lại initialBill một lần nữa để đảm bảo chính xác nhất
    final currentCalculatedInitialBill = hourlyCost + totalOrderedItemsCost;


    return AlertDialog(
      title: Text('Thanh toán cho Bàn ${updatedTable.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiền bàn: ${currencyFormat.format(hourlyCost)}'),
            Text('Tiền đồ ăn/uống: ${currencyFormat.format(totalOrderedItemsCost)}'),
            Text('Tổng ban đầu: ${currencyFormat.format(currentCalculatedInitialBill)}'),
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(labelText: 'Giảm giá (VNĐ)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Text(
              'Tổng cộng (sau giảm giá): ${currencyFormat.format(_finalAmount)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Hủy'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Xác nhận thanh toán'),
          onPressed: () {
            // Lấy lại dữ liệu cuối cùng trước khi thanh toán
            final updatedTableForTransaction = appDataProvider.billiardTables.firstWhere((t) => t.id == widget.table.id);
            final double playTimeHoursFinal = updatedTableForTransaction.displayTotalTime.inMinutes / 60.0;
            final double hourlyCostFinal = playTimeHoursFinal * appDataProvider.hourlyRate;
            double totalOrderedItemsCostFinal = 0;
            for (var orderedItem in updatedTableForTransaction.orderedItems) {
              final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull((menu) => menu.id == orderedItem.itemId);
              if (item != null) {
                totalOrderedItemsCostFinal += item.price * orderedItem.quantity;
              }
            }
            final initialBillFinal = hourlyCostFinal + totalOrderedItemsCostFinal;
            final finalBillAmount = initialBillFinal - _discount;

            appDataProvider.addTransaction(
              updatedTableForTransaction.id,
              List<OrderedItem>.from(updatedTableForTransaction.orderedItems), // Tạo bản sao
              initialBillFinal,
              _discount,
              finalBillAmount,
            );
            appDataProvider.resetBilliardTable(updatedTableForTransaction); // Reset bàn sau khi thanh toán
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã thanh toán thành công cho bàn ${updatedTableForTransaction.name}!')),
            );
          },
        ),
      ],
    );
  }
}