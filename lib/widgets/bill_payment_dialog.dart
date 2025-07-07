import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';

import '../models/invoice.dart';
import '../models/ordered_item.dart';
import '../services/ThermalPrinterService.dart';

class BillPaymentDialog extends StatefulWidget {
  final BilliardTable table;
  final double initialTotalBill;

  const BillPaymentDialog({
    super.key,
    required this.table,
    required this.initialTotalBill,
  });

  @override
  State<BillPaymentDialog> createState() => _BillPaymentDialogState();
}

class _BillPaymentDialogState extends State<BillPaymentDialog> {
  final TextEditingController _discountController = TextEditingController(text: '0');
  double _discount = 0;
  double _finalAmount = 0;

  @override
  void initState() {
    super.initState();
    _finalAmount = widget.initialTotalBill - _discount;
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
      if (_finalAmount < 0) _finalAmount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context);
    final String bankName = appDataProvider.bankName;
    final String bankAccountNumber = appDataProvider.bankAccountNumber;
    final String bankAccountHolder = appDataProvider.bankAccountHolder;
    final String qrImageUrl = appDataProvider.qrImageUrl;

    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final BilliardTable updatedTable = appDataProvider.billiardTables.firstWhere((t) => t.id == widget.table.id);
    final double playTimeHours = updatedTable.displayTotalTime.inMinutes / 60.0;
    final double hourlyCost = playTimeHours * updatedTable.price;

    double totalOrderedItemsCost = 0;
    List<Widget> orderedItemsDetails = [];
    for (var orderedItem in updatedTable.orderedItems) {
      final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull((menu) => menu.id == orderedItem.itemId);
      if (item != null) {
        final itemTotal = item.price * orderedItem.quantity;
        totalOrderedItemsCost += itemTotal;
        orderedItemsDetails.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Expanded(child: Text(item.name)),
                Text('x${orderedItem.quantity}'),
                const SizedBox(width: 10),
                Text(currencyFormat.format(item.price)),
                const SizedBox(width: 10),
                Text(currencyFormat.format(itemTotal)),
              ],
            ),
          ),
        );
      }
    }

    final playedDuration = updatedTable.displayTotalTime;
    final playedTimeString = '${playedDuration.inHours} giờ ${playedDuration.inMinutes % 60} phút';

    return AlertDialog(
      title: Text('Thanh toán cho Bàn ${updatedTable.name}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thời gian chơi:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(playedTimeString),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tiền giờ:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(currencyFormat.format(hourlyCost)),
              ],
            ),
            const Divider(height: 24),
            const Text('Chi tiết món ăn đã gọi:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (orderedItemsDetails.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Không có món ăn nào.'),
              )
            else
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: const [
                        Expanded(child: Text('Tên món')),
                        Text('SL'),
                        SizedBox(width: 10),
                        Text('Đơn giá'),
                        SizedBox(width: 10),
                        Text('Thành tiền'),
                      ],
                    ),
                  ),
                  ...orderedItemsDetails,
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền món ăn:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(currencyFormat.format(totalOrderedItemsCost)),
                    ],
                  ),
                ],
              ),
            const Divider(height: 24),
            Text('Tổng ban đầu: ${currencyFormat.format(widget.initialTotalBill)}'),
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
            const SizedBox(height: 15),
            if (bankName.isNotEmpty && bankAccountNumber.isNotEmpty && bankAccountHolder.isNotEmpty && qrImageUrl.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text('Thanh toán qua chuyển khoản:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Ngân hàng / Ví: $bankName'),
                  Text('STK / SĐT: $bankAccountNumber'),
                  Text('Chủ TK: $bankAccountHolder'),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: CachedNetworkImage(
                        imageUrl: qrImageUrl,
                        width: 180,
                        height: 180,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error, size: 50, color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nội dung chuyển khoản: Tên bàn (VD: Ban A)',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: <Widget>[
        Row(
          children: [
            Expanded(
              child: TextButton(
                child: const Text('Hủy'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Thanh toán'),
                onPressed: () async {
                  final BilliardTable tableToBill = appDataProvider.billiardTables.firstWhere((t) => t.id == widget.table.id);
                  final DateTime billDateTime = DateTime.now();
                  final DateTime startTime = tableToBill.startTime ?? billDateTime;
                  final DateTime endTime = tableToBill.endTime ?? billDateTime;
                  final Duration playedDuration = tableToBill.displayTotalTime;
                  final double hourlyRateAtTimeOfBill = tableToBill.price;
                  final double totalTableCost = (playedDuration.inMinutes / 60.0) * hourlyRateAtTimeOfBill;

                  double totalOrderedItemsCostFinal = 0;
                  for (var orderedItem in tableToBill.orderedItems) {
                    final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull((menu) => menu.id == orderedItem.itemId);
                    if (item != null) {
                      totalOrderedItemsCostFinal += item.price * orderedItem.quantity;
                    }
                  }

                  final invoice = Invoice(
                    tableName: tableToBill.name,
                    billDateTime: billDateTime,
                    startTime: startTime,
                    endTime: endTime,
                    playedDuration: playedDuration,
                    hourlyRateAtTimeOfBill: hourlyRateAtTimeOfBill,
                    totalTableCost: totalTableCost,
                    orderedItems: List<OrderedItem>.from(tableToBill.orderedItems),
                    totalOrderedItemsCost: totalOrderedItemsCostFinal,
                    discountAmount: _discount,
                    finalAmount: _finalAmount,
                  );

                  appDataProvider.addInvoice(invoice);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: Colors.black.withOpacity(0.3),
                    builder: (_) => WillPopScope(
                      onWillPop: () async => false,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Đang in hóa đơn...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                  try {
                    final bytes = await ThermalPrinterService().generateReceiptFromInvoice(invoice);
                    final result = await ThermalPrinterService().printTicket(bytes);

                    Navigator.of(context, rootNavigator: true).pop();

                    if (result == PrintResult.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hóa đơn đã được in thành công.')),
                      );
                    } else if (result == PrintResult.noDeviceSelected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chưa chọn máy in Bluetooth.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lỗi khi in hóa đơn.')),
                      );
                    }
                  } catch (e) {
                    if (Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi in hóa đơn: $e')),
                    );
                    debugPrint('Lỗi in hóa đơn Bluetooth: $e');
                  }

                  appDataProvider.addTransaction(
                    tableToBill.id,
                    List<OrderedItem>.from(tableToBill.orderedItems),
                    widget.initialTotalBill,
                    _discount,
                    _finalAmount,
                  );
                  appDataProvider.resetBilliardTable(tableToBill);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thanh toán thành công cho bàn ${tableToBill.name}!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
