// lib/screens/bill_detail_screen.dart
import 'package:bill_calculator_app/helper/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Để định dạng tiền tệ
import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/menu_item.dart'; // Import MenuItem
import 'package:bill_calculator_app/models/ordered_item.dart'; // Import OrderedItem

class BillDetailScreen extends StatelessWidget {
  final BilliardTable table;
  final double hourlyRate; // Giá thuê bàn mỗi giờ
  final List<MenuItem> menuItems; // Thêm danh sách menu items để tra cứu giá
  final Function(BilliardTable) onConfirmPayment; // Callback khi xác nhận thanh toán

  const BillDetailScreen({
    super.key,
    required this.table,
    required this.hourlyRate,
    required this.menuItems, // Yêu cầu truyền menuItems
    required this.onConfirmPayment,
  });



  // Hàm định dạng Duration thành HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitHours = twoDigits(duration.inHours);
    return "${twoDigitHours}:${twoDigitMinutes}:${twoDigitSeconds}";
  }

  // Hàm định dạng tiền tệ Việt Nam (sử dụng intl)
  String _formatCurrency(double amount) {
    final oCcy = NumberFormat("#,##0", "vi_VN");
    return '${oCcy.format(amount.round())} VNĐ';
  }

  // Hàm tính tiền bàn
  double _calculateTableBill() {
    final double totalHours = table.totalPlayedTime.inMinutes / 60.0;
    return totalHours * hourlyRate;
  }

  double _calculateOrderedItemsBill() {
    double total = 0.0;
    for (var orderedItem in table.orderedItems) {
      // Tìm MenuItem tương ứng để lấy giá
      final MenuItem? menuItem = menuItems.firstWhereOrNull(
            (item) => item.id == orderedItem.itemId,
      );
      if (menuItem != null) {
        total += menuItem.price * orderedItem.quantity;
      }
    }
    return total;
  }

  // Helper to find a menu item by its ID
  MenuItem? _findMenuItemById(String id) {
    return menuItems.firstWhereOrNull((item) => item.id == id);
  }

  @override
  Widget build(BuildContext context) {
    final double tableBill = _calculateTableBill();
    final double orderedItemsBill = _calculateOrderedItemsBill(); // Tính tiền đồ ăn
    final double totalBill = tableBill + orderedItemsBill; // Tổng hóa đơn

    return Scaffold(
      appBar: AppBar(
        title: Text('Hóa đơn ${table.id}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết hóa đơn ${table.id}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildBillItem(
              'Thời gian chơi',
              _formatDuration(table.totalPlayedTime),
            ),
            _buildBillItem(
              'Giá thuê / giờ',
              _formatCurrency(hourlyRate),
            ),
            _buildBillItem(
              'Tiền bàn',
              _formatCurrency(tableBill),
              isBold: true,
              color: Colors.blueAccent,
            ),
            if (table.orderedItems.isNotEmpty) ...[ // Chỉ hiển thị nếu có đồ ăn
              const Divider(height: 30, thickness: 1),
              const Text(
                'Đồ ăn/Thức uống:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...table.orderedItems.map((orderedItem) {
                final menuItem = _findMenuItemById(orderedItem.itemId);
                if (menuItem == null) return const SizedBox.shrink(); // Bỏ qua nếu không tìm thấy món
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${orderedItem.quantity} x ${menuItem.name}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        _formatCurrency(menuItem.price * orderedItem.quantity),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
              _buildBillItem(
                'Tổng tiền đồ ăn',
                _formatCurrency(orderedItemsBill),
                isBold: true,
                color: Colors.purple,
              ),
            ],
            const Divider(height: 30, thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatCurrency(totalBill),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onConfirmPayment(table);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Xác nhận Thanh toán',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper để xây dựng một dòng trong hóa đơn
  Widget _buildBillItem(String label, String value,
      {bool isBold = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

}