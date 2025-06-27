import 'package:bill_calculator_app/helper/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/screens/bill_detail_screen.dart';
import 'dart:convert'; // Để sử dụng jsonEncode và jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // Để lưu trữ cục bộ
import 'package:bill_calculator_app/models/menu_item.dart'; // Import MenuItem
import 'package:bill_calculator_app/screens/menu_management_screen.dart';
import 'package:bill_calculator_app/screens/table_management_screen.dart';
import 'package:bill_calculator_app/models/transaction.dart';  //Dữ li giao dịch
import 'package:bill_calculator_app/screens/transaction_history_screen.dart'; // Thêm dòng này

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Tính tiền Bida',
      theme: ThemeData(
        primarySwatch: Colors.green, // Màu chủ đạo của ứng dụng
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BillCalculatorHomePage(), // Đây sẽ là màn hình chính của chúng ta
    );
  }
}

class BillCalculatorHomePage extends StatefulWidget {
  const BillCalculatorHomePage({super.key});

  @override
  State<BillCalculatorHomePage> createState() => _BillCalculatorHomePageState();
}

class _BillCalculatorHomePageState extends State<BillCalculatorHomePage> {
  // Danh sách các bàn bida của chúng ta
  List<BilliardTable> _tables = []; // Khởi tạo rỗng, sẽ được tải từ SharedPreferences

  // Giá thuê bida mỗi giờ (ví dụ: 50.000 VNĐ)
  double _hourlyRate = 50000.0; // Mặc định là 50.000 VNĐ

  // Danh sách menu đồ ăn/thức uống
  List<MenuItem> _menuItems = []; // Sẽ được tải từ SharedPreferences
  // Danh sách giao dịch
  List<Transaction> _transactions = [];

  // Keys để lưu trữ dữ liệu trong SharedPreferences
  static const String _hourlyRateKey = 'hourlyRate';
  static const String _tablesKey = 'billiardTables';
  static const String _menuItemsKey = 'menuItems'; // Key mới cho menu items
  static const String _transactionsKey = 'transactions'; // Key cho giao dịch

  // Timer để cập nhật thời gian hiển thị mỗi giây
  // Timer? _timer; // Không cần thiết nếu chỉ dùng setState trong stop/start

  @override
  void initState() {
    super.initState();
    // Có thể bắt đầu timer ở đây nếu muốn update UI liên tục mỗi giây
    // _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   // Cập nhật trạng thái để UI được vẽ lại
    //   setState(() {});
    // });
    _loadData(); // Tải dữ liệu khi ứng dụng khởi động
  }

  @override
  void dispose() {
    // _timer?.cancel(); // Hủy timer khi widget bị loại bỏ khỏi cây widget
    super.dispose();
  }

  // Hàm định dạng Duration thành chuỗi HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitHours = twoDigits(duration.inHours);
    return "${twoDigitHours}:${twoDigitMinutes}:${twoDigitSeconds}";
  }
  // Hàm tính tiền dựa trên Duration và giá theo giờ
  double _calculateBill(Duration duration) {
    // Chuyển đổi duration sang giờ (có thể có phần thập phân)
    final double totalHours = duration.inMinutes / 60.0;
    return totalHours * _hourlyRate;
  }
  // Hàm định dạng tiền tệ Việt Nam (VND) sử dụng intl
  String _formatCurrency(double amount) {
    final oCcy = NumberFormat("#,##0", "vi_VN"); // Định dạng số Việt Nam
    return '${oCcy.format(amount.round())} VNĐ';
  }
  // Hàm tải dữ liệu từ SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _hourlyRate = prefs.getDouble(_hourlyRateKey) ?? 50000.0;
    });

    // Tải danh sách bàn bida
    final String? tablesJsonString = prefs.getString(_tablesKey);
    if (tablesJsonString != null) {
      final List<dynamic> tablesJsonList = jsonDecode(tablesJsonString);
      setState(() {
        _tables = tablesJsonList
            .map((json) => BilliardTable.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } else {
      setState(() {
        _tables = [
          BilliardTable(id: 'Bàn 1'),
          BilliardTable(id: 'Bàn 2'),
          BilliardTable(id: 'Bàn 3'),
          BilliardTable(id: 'Bàn 4'),
          BilliardTable(id: 'Bàn 5'),
          BilliardTable(id: 'Bàn 6'),
        ];
      });
    }

    // Tải danh sách menu items
    final String? menuItemsJsonString = prefs.getString(_menuItemsKey);
    if (menuItemsJsonString != null) {
      final List<dynamic> menuItemsJsonList = jsonDecode(menuItemsJsonString);
      setState(() {
        _menuItems = menuItemsJsonList
            .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } else {
      // Nếu chưa có dữ liệu, khởi tạo menu mặc định
      setState(() {
        _menuItems = [
          MenuItem(id: 'nuoc_ngot', name: 'Nước Ngọt', price: 15000.0),
          MenuItem(id: 'cafe_den', name: 'Cà Phê Đen', price: 20000.0),
          MenuItem(id: 'mi_tom', name: 'Mì Tôm', price: 25000.0),
          MenuItem(id: 'bia', name: 'Bia', price: 25000.0),
        ];
      });
    }
    // Tải transactions (MỚI THÊM)
    final String? transactionsJsonString = prefs.getString(_transactionsKey);
    if (transactionsJsonString != null) {
      final List<dynamic> transactionsJsonList = jsonDecode(transactionsJsonString);
      setState(() {
        _transactions = transactionsJsonList
            .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    }

  }

  // Hàm lưu dữ liệu vào SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_hourlyRateKey, _hourlyRate);

    final List<Map<String, dynamic>> tablesJsonList =
    _tables.map((table) => table.toJson()).toList();
    await prefs.setString(_tablesKey, jsonEncode(tablesJsonList));

    final List<Map<String, dynamic>> menuItemsJsonList =
    _menuItems.map((item) => item.toJson()).toList();
    await prefs.setString(_menuItemsKey, jsonEncode(menuItemsJsonList));
    // Lưu transactions (MỚI THÊM)
    final String transactionsJsonString = jsonEncode(_transactions.map((transaction) => transaction.toJson()).toList());
    await prefs.setString(_transactionsKey, transactionsJsonString);
    debugPrint('Dữ liệu đã được lưu!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Bida'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
          IconButton( 
            icon: const Icon(Icons.menu_book),
            onPressed: () async { // Thêm async
              // Điều hướng đến màn hình quản lý menu
              final updatedMenuItems = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuManagementScreen(
                    initialMenuItems: _menuItems, // Truyền danh sách menu hiện tại
                    onSave: (List<MenuItem> newMenuItems) {
                      // Callback này được gọi khi màn hình quản lý menu lưu
                      setState(() {
                        _menuItems = newMenuItems; // Cập nhật danh sách menu chính
                      });
                      _saveData(); // Lưu dữ liệu sau khi menu được cập nhật
                    },
                  ),
                ),
              );
              // Nếu bạn muốn xử lý khi người dùng chỉ pop mà không lưu,
              // thì updatedMenuItems sẽ là null nếu onSave không được gọi.
              // Trong trường hợp của chúng ta, onSave luôn được gọi trước khi pop.
            },
          ),
        // Nút quản lý bàn mới
          IconButton(
            icon: const Icon(Icons.table_bar), // Hoặc Icons.table_chart
            onPressed: () async {
              final updatedTables = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TableManagementScreen(
                    initialTables: _tables, // Truyền danh sách bàn hiện tại
                    onSave: (List<BilliardTable> newTables) {
                      setState(() {
                        _tables = newTables; // Cập nhật danh sách bàn chính
                      });
                      _saveData(); // Lưu dữ liệu sau khi bàn được cập nhật
                    },
                  ),
                ),
              );
            },
          ),
          // Nút Lịch sử Giao dịch mới
          IconButton(
            icon: const Icon(Icons.history), // Hoặc Icons.receipt_long
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    transactions: _transactions, // Truyền danh sách giao dịch
                    menuItems: _menuItems, // Truyền menuItems để hiển thị chi tiết đồ ăn
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Kiểm tra _tables hoặc _menuItems đã được tải chưa.
      // Nếu chưa, hiển thị CircularProgressIndicator.
      body: _tables.isEmpty || _menuItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _tables.length,
        itemBuilder: (context, index) {
          final table = _tables[index];
          final currentBill = _calculateBill(table.displayTotalTime);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${table.id}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trạng thái: ${table.isOccupied ? 'Đang chơi' : 'Trống'}',
                    style: TextStyle(
                        fontSize: 16,
                        color: table.isOccupied ? Colors.red : Colors.green),
                  ),
                  const SizedBox(height: 8),
                  // Sử dụng StreamBuilder để cập nhật thời gian theo thời gian thực
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                    builder: (context, snapshot) {
                      return Text(
                        'Tổng thời gian: ${_formatDuration(table.displayTotalTime)}',
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tổng tiền: ${_formatCurrency(currentBill)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),

                  // Thêm danh sách đồ ăn đã gọi
                  if (table.orderedItems.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Đồ ăn đã gọi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...table.orderedItems.map((orderedItem) {
                      final menuItem = _menuItems.firstWhereOrNull((item) => item.id == orderedItem.itemId);
                      if (menuItem == null) return const SizedBox.shrink(); // Bỏ qua nếu không tìm thấy món
                      return Text(
                        ' - ${menuItem.name}: ${orderedItem.quantity} x ${_formatCurrency(menuItem.price)}',
                        style: const TextStyle(fontSize: 14),
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Nút Bắt đầu/Dừng (Thay thế ElevatedButton.icon bằng IconButton)
                      IconButton(
                        icon: Icon(table.isOccupied ? Icons.stop : Icons.play_arrow),
                        tooltip: table.isOccupied ? 'Dừng bàn' : 'Bắt đầu bàn', // Thêm tooltip
                        color: table.isOccupied ? Colors.red : Colors.green,
                        onPressed: table.isOccupied
                            ? () {
                          setState(() {
                            table.stop();
                          });
                          _saveData();
                        }
                            : () {
                          setState(() {
                            table.start();
                          });
                          _saveData();
                        },
                      ),
                      // Nút Thêm món
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        tooltip: 'Thêm món', // Thêm tooltip
                        color: Colors.blue,
                        onPressed: () async { // <-- THÊM 'async' VÀO ĐÂY
                          await _showAddItemDialog(table); // <-- THÊM 'await' VÀO ĐÂY
                          setState(() {
                            // Gọi setState để cập nhật UI của màn hình chính
                            // Không cần thay đổi gì cụ thể ở đây, chỉ cần gọi để UI rebuild
                          });
                          _saveData(); // <-- Gọi _saveData() SAU KHI setState() để đảm bảo dữ liệu được lưu sau khi UI cập nhật
                        },
                      ),
                      // Nút Hóa đơn
                      IconButton(
                        icon: const Icon(Icons.receipt_long),
                        tooltip: 'Xem hóa đơn & Thanh toán', // Thêm tooltip
                        color: Colors.purple,
                        onPressed: !table.isOccupied
                            ? null // Vô hiệu hóa nút nếu bàn chưa được bắt đầu
                            : () async {
                          await Navigator.push(// Chờ màn hình BillDetailScreen đóng lại
                            context,
                            MaterialPageRoute(
                              builder: (context) => BillDetailScreen(
                                table: table,
                                hourlyRate: _hourlyRate,
                                menuItems: _menuItems,
                                // Hàm onConfirmPayment này sẽ được gọi KHI THANH TOÁN THÀNH CÔNG
                                onConfirmPayment: (BilliardTable confirmedTable) {
                                  // Vùng code này chỉ chạy khi người dùng bấm THANH TOÁN trên BillDetailScreen
                                  if (confirmedTable.startTime != null && confirmedTable.endTime != null) {
                                    final double playTimeBill = _calculateBill(confirmedTable.displayTotalTime);
                                    final double itemsBill = confirmedTable.orderedItems.fold(
                                      0.0,
                                          (sum, orderedItem) {
                                        final menuItem = _menuItems.firstWhereOrNull((item) => item.id == orderedItem.itemId);
                                        return sum + (menuItem?.price ?? 0.0) * orderedItem.quantity;
                                      },
                                    );

                                    final newTransaction = Transaction(
                                      tableId: confirmedTable.id,
                                      startTime: confirmedTable.startTime!,
                                      endTime: confirmedTable.endTime!, // Sử dụng endTime từ table đã được stop()
                                      totalPlayTime: confirmedTable.displayTotalTime,
                                      billAmount: playTimeBill,
                                      orderedItems: List.from(confirmedTable.orderedItems),
                                      totalOrderedItemsAmount: itemsBill,
                                      finalBillAmount: playTimeBill + itemsBill,
                                      transactionTime: DateTime.now(),
                                    );

                                    setState(() {
                                      _transactions.add(newTransaction);
                                    });
                                  } else {
                                    debugPrint('Lỗi: startTime hoặc endTime của bàn ${confirmedTable.id} bị null khi xác nhận thanh toán.');
                                  }
                                  setState(() {
                                    confirmedTable.reset();
                                  });
                                  _saveData();
                                },
                              ),
                            ),
                          );
                          // SAU KHI BillDetailScreen ĐÓNG (dù là thanh toán hay hủy), CẬP NHẬT LẠI UI CHÍNH
                          setState(() {
                            // Không cần thay đổi gì cụ thể ở đây, chỉ cần gọi để UI rebuild
                            // và hiển thị trạng thái hiện tại của bàn (đang chạy hoặc đã reset)
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  // Hàm hiển thị dialog thêm món ăn/thức uống
  Future<void> _showAddItemDialog(BilliardTable currentTable) {
    final _searchController = TextEditingController();
    List<MenuItem> filteredItems = List.from(_menuItems);

    return  showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Thêm Món'),
              // BẮT ĐẦU PHẦN CHỈNH SỬA CONTENT
              content: SizedBox( // <-- THÊM SIZEDBOX Ở ĐÂY
                height: MediaQuery.of(context).size.height * 0.6, // Chiều cao tối đa là 60% màn hình
                width: MediaQuery.of(context).size.width * 0.8,   // Chiều rộng tối đa là 80% màn hình (tốt cho cả portrait & landscape)
                child: Column( // <-- BỎ mainAxisSize: MainAxisSize.min ở đây
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Tìm kiếm món ăn',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (query) {
                        setInnerState(() {
                          filteredItems = _menuItems
                              .where((item) =>
                              item.name.toLowerCase().contains(query.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final orderedQuantity = currentTable.orderedItems
                              .firstWhereOrNull((oi) => oi.itemId == item.id)?.quantity ?? 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text(_formatCurrency(item.price), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle),
                                      color: Colors.red,
                                      onPressed: orderedQuantity > 0
                                          ? () {
                                        setInnerState(() {
                                          currentTable.addOrUpdateOrderedItem(item.id, -1);
                                        });
                                      }
                                          : null,
                                    ),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '$orderedQuantity',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle),
                                      color: Colors.green,
                                      onPressed: () {
                                        setInnerState(() {
                                          currentTable.addOrUpdateOrderedItem(item.id, 1);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // KẾT THÚC PHẦN CHỈNH SỬA CONTENT
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Hoàn tất'),
                  onPressed: () {
                    _saveData();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showSettingsDialog() {
    double tempRate = _hourlyRate;
    TextEditingController _controller = TextEditingController(text: _hourlyRate.round().toString()); // Tạo controller ở đây

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cài đặt Giá thuê'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Giá mỗi giờ (VNĐ)',
              border: OutlineInputBorder(),
            ),
            controller: _controller, // Gán controller
            onChanged: (value) {
              tempRate = double.tryParse(value) ?? _hourlyRate;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                _controller.dispose(); // Hủy controller khi thoát dialog
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Lưu'),
              onPressed: () {
                setState(() {
                  _hourlyRate = tempRate;
                });
                _saveData(); // Lưu dữ liệu sau khi thay đổi giá
                _controller.dispose(); // Hủy controller khi thoát dialog
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      _controller.dispose(); // Đảm bảo dispose controller nếu dialog bị đóng ngoài ý muốn
    });
  }

}