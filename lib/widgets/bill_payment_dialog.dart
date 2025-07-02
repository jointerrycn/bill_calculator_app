// lib/widgets/bill_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Để dùng .firstWhereOrNull
import 'package:cached_network_image/cached_network_image.dart';

import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';

import '../models/invoice.dart';
import '../models/ordered_item.dart';
import '../services/print_service.dart';

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
    final appDataProvider = Provider.of<AppDataProvider>(
      context,
    ); // Không cần watch ở đây vì setState đã cập nhật
    // Lấy thông tin QR từ AppDataProvider
    final String bankName = appDataProvider.bankName;
    final String bankAccountNumber = appDataProvider.bankAccountNumber;
    final String bankAccountHolder = appDataProvider.bankAccountHolder;
    final String qrImageUrl = appDataProvider.qrImageUrl;
    debugPrint('QR Image URL: $qrImageUrl');
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    // Cần lấy lại thông tin bàn được cập nhật nhất từ provider
    final updatedTable = appDataProvider.billiardTables.firstWhere(
      (t) => t.id == widget.table.id,
    );

    final double playTimeHours = updatedTable.displayTotalTime.inMinutes / 60.0;
    final double hourlyCost = playTimeHours * updatedTable.price;

    double totalOrderedItemsCost = 0;
    List<Widget> orderedItemsDetails = [];
    for (var orderedItem in updatedTable.orderedItems) {
      final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull(
        (menu) => menu.id == orderedItem.itemId,
      );
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
    // Tính lại initialBill một lần nữa để đảm bảo chính xác nhất
    final currentCalculatedInitialBill = hourlyCost + totalOrderedItemsCost;

    // Thời gian chơi chi tiết
    final playedDuration = updatedTable.displayTotalTime;
    final playedTimeString =
        '${playedDuration.inHours} giờ ${playedDuration.inMinutes % 60} phút';

    return AlertDialog(
      title: Text('Thanh toán cho Bàn ${updatedTable.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thời gian đã chơi
            const Text(
              'Thời gian chơi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(playedTimeString),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiền giờ:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(currencyFormat.format(hourlyCost)),
              ],
            ),
            const Divider(height: 24),
            // Chi tiết món ăn đã gọi
            const Text(
              'Chi tiết món ăn đã gọi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                      const Text(
                        'Tổng tiền món ăn:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(currencyFormat.format(totalOrderedItemsCost)),
                    ],
                  ),
                ],
              ),
            const Divider(height: 24),
            // Tổng ban đầu, giảm giá, tổng cộng
            Text(
              'Tổng ban đầu: ${currencyFormat.format(currentCalculatedInitialBill)}',
            ),
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

            // --- HIỂN THỊ THÔNG TIN QR THANH TOÁN <-- PHẦN MỚI
            if (bankName.isNotEmpty && bankAccountNumber.isNotEmpty && bankAccountHolder.isNotEmpty&&qrImageUrl.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Thanh toán qua chuyển khoản:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Ngân hàng / Ví: $bankName'),
                  Text('STK / SĐT: $bankAccountNumber'),
                  Text('Chủ TK: $bankAccountHolder'),
                  const SizedBox(height: 10),

                  if (qrImageUrl.isNotEmpty)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: CachedNetworkImage(
                          imageUrl: qrImageUrl,
                          width: 180, // Kích thước hiển thị QR
                          height: 180,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.error, size: 50, color: Colors.red),
                        ),
                      ),
                    ),
                  if (qrImageUrl.isEmpty)
                    const Text(
                      'Vui lòng cài đặt URL hình ảnh QR Code trong Cài đặt.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nội dung chuyển khoản: Tên bàn (VD: Ban A)', // Hướng dẫn khách nhập nội dung
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Màu nổi bật cho nút xác nhận
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Thanh toán'),
                onPressed: () async {
                  // Lấy lại dữ liệu cuối cùng trước khi thanh toán
                  final updatedTableForTransaction = appDataProvider
                      .billiardTables
                      .firstWhere((t) => t.id == widget.table.id);
                  final double playTimeHoursFinal =
                      updatedTableForTransaction.displayTotalTime.inMinutes /
                      60.0;

                  double totalOrderedItemsCostFinal = 0;
                  for (var orderedItem
                      in updatedTableForTransaction.orderedItems) {
                    final MenuItem? item = appDataProvider.menuItems
                        .firstWhereOrNull(
                          (menu) => menu.id == orderedItem.itemId,
                        );
                    if (item != null) {
                      totalOrderedItemsCostFinal +=
                          item.price * orderedItem.quantity;
                    }
                  }
                  final initialBillFinal = hourlyCost + totalOrderedItemsCostFinal;
                  final finalBillAmount = initialBillFinal - _discount;
                  // --- TẠO VÀ LƯU HÓA ĐƠN TRƯỚC KHI IN VÀ RESET BÀN ---
                  final invoice = Invoice(
                    tableName: updatedTableForTransaction.name,
                    billDateTime: DateTime.now(),
                    playedDuration: updatedTableForTransaction.displayTotalTime,
                    hourlyRateAtTimeOfBill: updatedTableForTransaction.price,
                    totalTableCost: hourlyCost,
                    orderedItems: List.from(updatedTableForTransaction.orderedItems), // Tạo bản sao để tránh tham chiếu
                    totalOrderedItemsCost: totalOrderedItemsCost,
                    discountAmount: _discount,
                    finalAmount: finalBillAmount,
                  );
                  appDataProvider.addInvoice(invoice); // <-- LƯU HÓA ĐƠN VÀO APPDATAPROVIDER
                  // --- GỌI HÀM IN HÓA ĐƠN TẠI ĐÂY ---
                  await PrintService.generateAndPrintInvoice(
                    table: updatedTable,
                    durationForBilling: playedDuration,
                    totalOrderedItemsCost: totalOrderedItemsCostFinal,
                    appDataProvider: appDataProvider,
                    discountAmount: _discount,
                    // Truyền số tiền giảm giá
                    finalAmount: finalBillAmount,
                    // Truyền tổng cuối cùng
                    context: context, // Truyền context để hiện màn hình mờ
                  );
                  // ------------------------------------
                  appDataProvider.addTransaction(
                    updatedTableForTransaction.id,
                    List<OrderedItem>.from(
                      updatedTableForTransaction.orderedItems,
                    ), // Tạo bản sao
                    initialBillFinal,
                    _discount,
                    finalBillAmount,
                  );
                  appDataProvider.resetBilliardTable(
                    updatedTableForTransaction,
                  ); // Reset bàn sau khi thanh toán
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã thanh toán thành công cho bàn ${updatedTableForTransaction.name}!',
                      ),
                    ),
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
