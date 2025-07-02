// lib/widgets/table_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Để dùng .firstWhereOrNull

import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/models/ordered_item.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';

class TableDetailsDialog extends StatelessWidget {
  final BilliardTable table;

  const TableDetailsDialog({
    super.key,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng Consumer để chỉ phần nội dung của dialog được rebuild khi AppDataProvider thay đổi
    return Consumer<AppDataProvider>(
      builder: (context, appDataProvider, child) {
        // Lấy lại thông tin bàn được cập nhật từ provider để đảm bảo dữ liệu mới nhất
        final updatedTable = appDataProvider.billiardTables.firstWhere((t) => t.id == table.id);

        final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
        final double hourlyCost = appDataProvider.getHourlyCostForTable(updatedTable.id,  updatedTable.displayTotalTime);

        double totalOrderedItemsCost = 0;
        for (var orderedItem in updatedTable.orderedItems) {
          final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull((menu) => menu.id == orderedItem.itemId);
          if (item != null) {
            totalOrderedItemsCost += item.price * orderedItem.quantity;
          }
        }
        final currentTotalBill = hourlyCost + totalOrderedItemsCost;

        return AlertDialog(
          title: Text('Chi tiết Bàn ${updatedTable.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trạng thái: ${updatedTable.isOccupied ? 'Đang chơi' : 'Trống'}'),
                if (updatedTable.startTime != null)
                  Text('Bắt đầu: ${DateFormat('HH:mm').format(updatedTable.startTime!)}'),
                Text('Thời gian chơi: ${updatedTable.displayTotalTime.inHours}h ${updatedTable.displayTotalTime.inMinutes % 60}m'),
                Text('Tiền bàn: ${currencyFormat.format(hourlyCost)}'),
                const Divider(),
                const Text('Đồ ăn/uống đã gọi:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (updatedTable.orderedItems.isEmpty)
                  const Text('Chưa có đồ ăn/uống nào được gọi.'),
                ...updatedTable.orderedItems.map((orderedItem) {
                  final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull((menu) => menu.id == orderedItem.itemId);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item?.name ?? 'Unknown'} x${orderedItem.quantity}')),
                      Text(currencyFormat.format((item?.price ?? 0) * orderedItem.quantity)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () {
                          // Giảm số lượng
                          appDataProvider.updateTableOrderedItems(updatedTable, item!, -1);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () {
                          // Tăng số lượng
                          appDataProvider.updateTableOrderedItems(updatedTable, item!, 1);
                        },
                      ),
                    ],
                  );
                }).toList(),
                const Divider(),
                Text(
                  'Tổng tiền đồ ăn: ${currencyFormat.format(totalOrderedItemsCost)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Text(
                  'TỔNG CỘNG: ${currencyFormat.format(currentTotalBill)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Mở dialog để thêm món mới
                    _showAddOrderedItemDialog(context, updatedTable, appDataProvider);
                  },
                  child: const Text('Thêm món'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset Bàn'),
              onPressed: () {
                // Xác nhận trước khi reset
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận Reset Bàn'),
                    content: const Text('Bạn có chắc chắn muốn reset bàn này không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Không'),
                      ),
                      TextButton(
                        onPressed: () {
                          appDataProvider.resetBilliardTable(table);
                          Navigator.of(ctx).pop(); // Đóng dialog xác nhận
                          Navigator.of(context).pop(); // Đóng dialog chi tiết bàn
                        },
                        child: const Text('Có'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Hàm _showAddOrderedItemDialog này vẫn cần được định nghĩa ở đây
  // vì nó là một phần của logic tương tác trong TableDetailsDialog.
  Future<void> _showAddOrderedItemDialog(BuildContext context, BilliardTable table, AppDataProvider appDataProvider) async {
    MenuItem? selectedMenuItem;
    int quantity = 1;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Thêm món vào bàn'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<MenuItem>(
                    decoration: const InputDecoration(labelText: 'Chọn món'),
                    value: selectedMenuItem,
                    items: appDataProvider.menuItems.map((item) {
                      return DropdownMenuItem<MenuItem>(
                        value: item,
                        child: Text('${item.name} (${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(item.price)})'),
                      );
                    }).toList(),
                    onChanged: (MenuItem? newValue) {
                      setState(() {
                        selectedMenuItem = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                    keyboardType: TextInputType.number,
                    initialValue: quantity.toString(),
                    onChanged: (value) {
                      quantity = int.tryParse(value) ?? 1;
                    },
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Thêm'),
              onPressed: () {
                if (selectedMenuItem != null && quantity > 0) {
                  appDataProvider.updateTableOrderedItems(table, selectedMenuItem!, quantity);
                  Navigator.of(dialogContext).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn món và nhập số lượng hợp lệ.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
