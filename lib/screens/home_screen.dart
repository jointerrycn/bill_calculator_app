// lib/screens/home_screen.dart
import 'package:bill_calculator_app/screens/PrinterSettingsScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Để định dạng thời gian và tiền tệ

import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/models/ordered_item.dart';

import 'package:bill_calculator_app/providers/app_data_provider.dart';

// Import các màn hình quản lý (ĐẢM BẢO CÁC FILE NÀY TỒN TẠI VÀ ĐÚNG ĐƯỜNG DẪN)
import 'package:bill_calculator_app/screens/statistics_screen.dart';
import 'package:bill_calculator_app/screens/menu_management_screen.dart';
import 'package:bill_calculator_app/screens/table_management_screen.dart';
import 'package:bill_calculator_app/screens/settings_screen.dart';
import 'package:bill_calculator_app/screens/InvoiceHistoryScreen.dart'; // Đảm bảo đúng tên file

import 'package:bill_calculator_app/widgets/table_details_dialog.dart';
import 'package:bill_calculator_app/widgets/bill_payment_dialog.dart';
import 'package:collection/collection.dart'; // Để sử dụng firstWhereOrNull

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>   {
  int _selectedIndex = 0; // Index của tab được chọn trong BottomNavigationBar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Hàm hiển thị dialog chuyển bàn.
  /// Cho phép chọn bàn đích từ danh sách các bàn trống.
  void _showTransferTableDialog(
      BuildContext context,
      BilliardTable fromTable,
      AppDataProvider provider,
      ) {
    final availableTables = provider.billiardTables
        .where((t) => !t.isOccupied && t.id != fromTable.id)
        .toList();

    String? selectedTableId = availableTables.isNotEmpty
        ? availableTables.first.id
        : null;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chuyển từ "${fromTable.name}" sang bàn khác'),
        content: availableTables.isEmpty
            ? const Text('Không có bàn trống để chuyển.')
            : DropdownButtonFormField<String>(
          value: selectedTableId,
          items: availableTables
              .map(
                (t) => DropdownMenuItem(
              value: t.id,
              child: Text(
                '${t.name} (${t.price.toStringAsFixed(0)} VNĐ/giờ)',
              ),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() { // Cập nhật selectedTableId khi người dùng chọn
              selectedTableId = value;
            });
          },
          decoration: const InputDecoration(labelText: 'Chọn bàn đích'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          if (availableTables.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                if (selectedTableId != null) {
                  provider.transferTable(fromTable.id, selectedTableId!);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã chuyển sang bàn mới thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Chuyển bàn'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appDataProvider = context.watch<AppDataProvider>();
    // Danh sách các màn hình tương ứng với BottomNavigationBar
    final List<Widget> widgetOptions = <Widget>[
      _buildTableGrid(appDataProvider), // Màn hình chính hiển thị lưới bàn
      const StatisticsScreen(),
      const MenuManagementScreen(),
      const TableManagementScreen(),
      const InvoiceHistoryScreen(),
      const SettingsScreen(),
      const PrinterSettingsScreen()
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Không có nút chuyển bàn ở đây nữa, nó nằm trên từng thẻ bàn
        actions: const [
          // Thêm các nút khác vào AppBar nếu có
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.sports_bar), label: 'Bàn'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Món ăn'),
          BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: 'Bàn'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử HĐ'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
          BottomNavigationBarItem(icon: Icon(Icons.print), label: 'In ấn'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Đảm bảo các item không di chuyển khi chọn
      ),
    );
  }

  /// Xây dựng lưới các bàn bi-a.
  /// Sử dụng SliverGridDelegateWithMaxCrossAxisExtent để số cột tự điều chỉnh.
  Widget _buildTableGrid(AppDataProvider appDataProvider) {
    // Sắp xếp bàn: bàn đang chơi lên đầu
    final List<BilliardTable> sortedTables = appDataProvider.billiardTables.toList();
    sortedTables.sort((a, b) {
      if (a.isOccupied && !b.isOccupied) return -1;
      if (!a.isOccupied && b.isOccupied) return 1;
      return 0;
    });

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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250.0, // Chiều rộng tối đa của mỗi item theo trục ngang
        crossAxisSpacing: 16.0,   // Khoảng cách giữa các cột
        mainAxisSpacing: 16.0,    // Khoảng cách giữa các hàng
        // ĐÃ THAY ĐỔI: Tăng chiều cao của thẻ để chứa đủ nội dung và đẩy nút xuống
        childAspectRatio: 0.75,   // Tỷ lệ khung hình của mỗi thẻ (width / height)
        // Giá trị càng nhỏ, thẻ càng cao so với chiều rộng.
        // 0.65 là một giá trị tốt cho thẻ có nhiều nội dung.
      ),
      itemCount: sortedTables.length,
      itemBuilder: (context, index) {
        final table = sortedTables[index];
        // Sử dụng ChangeNotifierProvider.value để mỗi thẻ bàn lắng nghe riêng sự thay đổi
        return ChangeNotifierProvider.value(
          value: table,
          child: _buildTableCardContent(appDataProvider),
        );
      },
    );
  }

  /// Xây dựng nội dung của từng thẻ bàn.
  /// Đã loại bỏ SingleChildScrollView để các nút luôn bám đáy.
  Widget _buildTableCardContent(AppDataProvider appDataProvider) {
    return Consumer<BilliardTable>(
      builder: (context, currentTable, child) {
        final NumberFormat currencyFormat = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
        );

        // Tính toán chi phí bàn và đồ ăn
        final double hourlyCost = (currentTable.displayTotalTime.inMinutes / 60.0) * currentTable.price;

        double totalOrderedItemsCost = 0;
        for (var orderedItem in currentTable.orderedItems) {
          final MenuItem? item = appDataProvider.menuItems.firstWhereOrNull(
                (menu) => menu.id == orderedItem.itemId,
          );
          if (item != null) {
            totalOrderedItemsCost += item.price * orderedItem.quantity;
          }
        }
        final double totalBill = hourlyCost + totalOrderedItemsCost;

        return Card(
          elevation: 6,
          color: currentTable.isOccupied ? Colors.red.shade50 : Colors.green.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: currentTable.isOccupied ? Colors.red : Colors.green,
              width: 2,
            ),
          ),
          // Bọc nội dung Card trong Stack để định vị nút "Chuyển bàn" độc lập
          child: Stack(
            children: [
              // CON ĐẦU TIÊN CỦA STACK: Toàn bộ nội dung chính của thẻ bàn
              InkWell(
                onTap: () => _showTableDetailsDialog(context, currentTable, appDataProvider),
                // LOẠI BỎ SingleChildScrollView Ở ĐÂY
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    // Sử dụng mainAxisSize.max để Column chiếm toàn bộ chiều cao của Card
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên bàn (Flexible để tránh tràn văn bản)
                      Flexible(
                        child: Text(
                          currentTable.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis, // Hiển thị "..." nếu văn bản quá dài
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Trạng thái bàn
                      Row(
                        children: [
                          Icon(
                            currentTable.isOccupied ? Icons.play_arrow : Icons.stop,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentTable.isOccupied ? 'Đang chơi' : 'Trống',
                            style: TextStyle(
                              fontSize: 14,
                              color: currentTable.isOccupied
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Thời gian bắt đầu/Tổng thời gian
                      if (currentTable.startTime != null)
                        Flexible( // Flexible để tránh tràn nếu thông tin thời gian quá dài
                          child: Text(
                            currentTable.isOccupied
                                ? 'Bắt đầu: ${DateFormat('HH:mm').format(currentTable.startTime!)}'
                                : 'Tổng TG: ${currentTable.displayTotalTime.inHours}h ${currentTable.displayTotalTime.inMinutes % 60}m',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Tiền bàn
                      Flexible(
                        child: Text(
                          'Tiền bàn: ${currencyFormat.format(hourlyCost)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Tiền đồ ăn
                      Flexible(
                        child: Text(
                          'Tiền đồ ăn: ${currencyFormat.format(totalOrderedItemsCost)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Các nút hành động (Bắt đầu / Thanh toán)
                    ],
                  ),
                ),
              ),
              // CON THỨ HAI CỦA STACK: NÚT "CHUYỂN BÀN" Ở GÓC TRÊN BÊN PHẢI CỦA THẺ
              if (currentTable.isOccupied) // Chỉ hiển thị khi bàn đang có người chơi
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5), // Nền mờ cho nút
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(15), // Bo góc theo Card
                        bottomLeft: Radius.circular(10), // Bo góc dưới bên trái
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 20), // Icon màu trắng
                      tooltip: 'Chuyển bàn',
                      onPressed: () => _showTransferTableDialog(
                        context,
                        currentTable,
                        appDataProvider,
                      ),
                      visualDensity: VisualDensity.compact, // Giảm kích thước vùng chạm
                    ),
                  ),
                ),
              // CON THỨ BA CỦA STACK: CÁC NÚT HÀNH ĐỘNG ("Bắt đầu" / "Thanh toán") ĐẶT DƯỚI ĐÁY
              Positioned(
                bottom: 8.0, // Khoảng cách từ đáy thẻ (điều chỉnh nếu cần)
                left: 8.0,   // Khoảng cách từ cạnh trái thẻ
                right: 8.0,  // Khoảng cách từ cạnh phải thẻ
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (!currentTable.isOccupied)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => appDataProvider.toggleTableStatus(currentTable),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: const Text('Bắt đầu'),
                        ),
                      ),
                    if (currentTable.isOccupied)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showAddBillDialog(
                            context,
                            currentTable,
                            totalBill, // Truyền tổng tiền
                            appDataProvider,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: const Text('Thanh toán'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Hàm hiển thị dialog chi tiết bàn ---
  Future<void> _showTableDetailsDialog(
      BuildContext context,
      BilliardTable table,
      AppDataProvider appDataProvider,
      ) async {
    if (table.startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bàn ${table.name} đang trống. Không thể xem chi tiết.'),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Dừng hàm, không hiển thị dialog
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return TableDetailsDialog(table: table);
      },
    );
  }

  // --- Hàm hiển thị dialog thanh toán ---
  Future<void> _showAddBillDialog(
      BuildContext context,
      BilliardTable table,
      double currentTotalBill,
      AppDataProvider appDataProvider,
      ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return BillPaymentDialog(
          table: table,
          initialTotalBill: currentTotalBill,
        );
      },
    );
  }
}