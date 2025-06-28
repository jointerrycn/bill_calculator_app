// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Để định dạng tiền tệ và thời gian

import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/menu_item.dart'; // Cần cho firstWhereOrNull trong _buildTableCard
import 'package:bill_calculator_app/models/ordered_item.dart'; // Không trực tiếp cần nhưng có thể giữ

import 'package:bill_calculator_app/providers/app_data_provider.dart';

// Import các màn hình quản lý đã tách
import 'package:bill_calculator_app/screens/statistics_screen.dart';
import 'package:bill_calculator_app/screens/menu_management_screen.dart';
import 'package:bill_calculator_app/screens/table_management_screen.dart';
import 'package:bill_calculator_app/screens/settings_screen.dart';

// Import các widget dialog đã tách
import 'package:bill_calculator_app/widgets/table_details_dialog.dart';
import 'package:bill_calculator_app/widgets/bill_payment_dialog.dart';
import 'package:collection/collection.dart'; // Dùng cho .firstWhereOrNull


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Index của tab được chọn trong BottomNavigationBar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch AppDataProvider ở đây để HomeScreen tự động rebuild khi có thay đổi (ví dụ: số lượng bàn)
    final appDataProvider = context.watch<AppDataProvider>();

    // Danh sách các Widget tương ứng với mỗi tab
    // Tạo trực tiếp trong build method để đảm bảo chúng có thể truy cập appDataProvider đã được "watch"
    final List<Widget> widgetOptions = <Widget>[
      _buildTableGrid(appDataProvider), // Màn hình chính hiển thị các bàn
      const StatisticsScreen(),
      const MenuManagementScreen(),
      const TableManagementScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Các actions (nút) đã được chuyển sang các màn hình riêng biệt hoặc SettingsScreen
        // AppBar của HomeScreen giờ đây đơn giản hơn
      ),
      body: widgetOptions.elementAt(_selectedIndex), // Hiển thị Widget tương ứng với tab đã chọn
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_bar),
            label: 'Bàn', // Màn hình chính hiển thị lưới bàn
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Món ăn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart), // Hoặc icon khác như Icons.chair
            label: 'Quản lý bàn', // Nhãn cho màn hình quản lý bàn
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Giúp các item không bị mất nhãn khi nhiều
      ),
    );
  }

  // --- Hàm xây dựng lưới các bàn bi-a ---
  Widget _buildTableGrid(AppDataProvider appDataProvider) {
    // Sắp xếp các bàn theo trạng thái (đang chơi lên trước) và sau đó theo tên
    final List<BilliardTable> sortedTables = appDataProvider.billiardTables.toList();
    sortedTables.sort((a, b) {
      // Bàn đang chơi lên trước
      if (a.isOccupied && !b.isOccupied) return -1;
      if (!a.isOccupied && b.isOccupied) return 1;
      // Nếu cùng trạng thái, sắp xếp theo tên
      return a.name.compareTo(b.name);
    });

    // Lấy thông tin hướng màn hình
    // Đảm bảo các biến này được khai báo VÀ sử dụng trong cùng một scope
    final Orientation orientation = MediaQuery.of(context).orientation;

    // Xác định số cột dựa trên hướng màn hình
    final int crossAxisCount = orientation == Orientation.portrait ? 2 : 3;

    // Điều chỉnh tỉ lệ khung hình cho từng hướng
    // Giá trị 0.5 cho dọc (2 cột), 0.7 cho ngang (3 cột). Bạn có thể tinh chỉnh lại.
    final double aspectRatio = orientation == Orientation.portrait ? 0.65: 1.2;

    // Nếu không có bàn nào, hiển thị thông báo
    if (sortedTables.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có bàn nào được tạo. Vui lòng vào tab "Quản lý bàn" để thêm bàn mới!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( // <-- Bỏ 'const' ở đây
        crossAxisCount: crossAxisCount, // <-- Sử dụng biến đã khai báo
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: aspectRatio, // <-- Sử dụng biến đã khai báo
      ),
      itemCount: sortedTables.length,
      itemBuilder: (context, index) {
        final table = sortedTables[index];
        return _buildTableCard(context, table, appDataProvider);
      },
    );
  }

  // --- Hàm xây dựng thẻ hiển thị thông tin bàn ---
  Widget _buildTableCard(BuildContext context, BilliardTable table, AppDataProvider appDataProvider) {
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Tính toán chi phí bàn và đồ ăn cho thẻ hiển thị nhanh
    final double playTimeHours = table.displayTotalTime.inMinutes / 60.0;
    final double hourlyCost = playTimeHours * appDataProvider.hourlyRate;

    double totalOrderedItemsCost = 0;
    for (var orderedItem in table.orderedItems) {
      // Sử dụng .firstWhereOrNull từ package collection
      final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull((menu) => menu.id == orderedItem.itemId);
      if (item != null) {
        totalOrderedItemsCost += item.price * orderedItem.quantity;
      }
    }
    final double totalBill = hourlyCost + totalOrderedItemsCost;

    return Card(
      elevation: 6,
      color: table.isOccupied ? Colors.red.shade50 : Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: table.isOccupied ? Colors.red : Colors.green,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showTableDetailsDialog(context, table, appDataProvider),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên bàn
              Text(
                table.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // Giảm font size
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4), // Giảm khoảng cách
              // Trạng thái
              Row(
                children: [
                  Icon(
                    table.isOccupied ? Icons.play_arrow : Icons.stop,
                    size: 14, // Giảm icon size
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    table.isOccupied ? 'Đang chơi' : 'Trống',
                    style: TextStyle(
                      fontSize: 13, // Giảm font size
                      color: table.isOccupied ? Colors.red.shade800 : Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4), // Giảm khoảng cách
              // Thời gian bắt đầu/Tổng thời gian
              if (table.startTime != null)
                Text(
                  table.isOccupied
                      ? 'Bắt đầu: ${DateFormat('HH:mm').format(table.startTime!)}'
                      : 'Tổng TG: ${table.displayTotalTime.inHours}h ${table.displayTotalTime.inMinutes % 60}m',
                  style: const TextStyle(fontSize: 11, color: Colors.black54), // Giảm font size
                ),
              const SizedBox(height: 4), // Giảm khoảng cách
              // Tiền bàn và tiền đồ ăn
              Text(
                'Tiền bàn: ${currencyFormat.format(hourlyCost)}',
                style: const TextStyle(fontSize: 11, color: Colors.black87), // Giảm font size
              ),
              Text(
                'Tiền đồ ăn: ${currencyFormat.format(totalOrderedItemsCost)}',
                style: const TextStyle(fontSize: 11, color: Colors.black87), // Giảm font size
              ),
              const SizedBox(height: 4), // Giảm khoảng cách
              // Tổng cộng
              Text(
                'Tổng cộng: ${currencyFormat.format(totalBill)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black), // Giảm font size
              ),
              const SizedBox(height: 8), // Thay Spacer() bằng SizedBox để tránh overflow
              const Spacer(),
              // Các nút hành động
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => appDataProvider.toggleTableStatus(table),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: table.isOccupied ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6), // Giảm padding nút
                        textStyle: const TextStyle(fontSize: 11), // Giảm font size nút
                      ),
                      child: Text(table.isOccupied ? 'Dừng' : 'Bắt đầu'),
                    ),
                  ),
                  const SizedBox(width: 8), // Khoảng cách giữa các nút
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAddBillDialog(context, table, totalBill, appDataProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6), // Giảm padding nút
                        textStyle: const TextStyle(fontSize: 11), // Giảm font size nút
                      ),
                      child: const Text('Thanh toán'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Hàm hiển thị dialog chi tiết bàn ---
  Future<void> _showTableDetailsDialog(BuildContext context, BilliardTable table, AppDataProvider appDataProvider) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Gọi widget TableDetailsDialog đã tách ra
        return TableDetailsDialog(table: table);
      },
    );
  }

  // --- Hàm hiển thị dialog thanh toán ---
  Future<void> _showAddBillDialog(BuildContext context, BilliardTable table, double currentTotalBill, AppDataProvider appDataProvider) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Gọi widget BillPaymentDialog đã tách ra
        return BillPaymentDialog(
          table: table,
          initialTotalBill: currentTotalBill,
        );
      },
    );
  }
}