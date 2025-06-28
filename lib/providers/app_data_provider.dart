// lib/providers/app_data_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Required for File and Directory
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

// Import các model
import '../models/billiard_table.dart';
import '../models/ordered_item.dart';
import '../models/menu_item.dart';
import '../models/transaction.dart';

// Import data service
import '../data/data_service.dart';

class AppDataProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final DataService _dataService = DataService();

  List<MenuItem> _menuItems = [];
  List<Transaction> _transactions = [];
  List<BilliardTable> _billiardTables = [];
  double _hourlyRate = 0.0;
  bool _isLoading = true;

  // Getters để truy cập dữ liệu từ bên ngoài (chỉ đọc)
  List<MenuItem> get menuItems => _menuItems;
  List<Transaction> get transactions => _transactions;
  List<BilliardTable> get billiardTables => _billiardTables;
  double get hourlyRate => _hourlyRate;
  bool get isLoading => _isLoading;

  AppDataProvider() {
    // Khởi tạo và tải dữ liệu ngay khi provider được tạo
    _loadData();
  }

  // Hàm tải dữ liệu ban đầu
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners(); // Thông báo cho UI biết đang tải dữ liệu

    _menuItems = await _dataService.loadMenuItems();
    _transactions = await _dataService.loadTransactions();
    _billiardTables = await _dataService.loadBilliardTables();

    final prefs = await SharedPreferences.getInstance();
    _hourlyRate = prefs.getDouble('hourlyRate') ?? 50000.0;

    // Khởi tạo dữ liệu mặc định nếu trống
    if (_menuItems.isEmpty) {
      _menuItems = [
        MenuItem(id: _uuid.v4(), name: 'Phở Bò', price: 50000, category: 'Món Chính'),
        MenuItem(id: _uuid.v4(), name: 'Bún Chả', price: 45000, category: 'Món Chính'),
        MenuItem(id: _uuid.v4(), name: 'Cà Phê Sữa', price: 25000, category: 'Đồ Uống'),
        MenuItem(id: _uuid.v4(), name: 'Trà Đá', price: 10000, category: 'Đồ Uống'),
        MenuItem(id: _uuid.v4(), name: 'Bánh Mì', price: 20000, category: 'Ăn Kèm'),
      ];
      await _dataService.saveMenuItems(_menuItems);
    }

    if (_billiardTables.isEmpty) {
      _billiardTables = [
        BilliardTable(id: _uuid.v4(), name: 'Bàn A1'),
        BilliardTable(id: _uuid.v4(), name: 'Bàn A2'),
        BilliardTable(id: _uuid.v4(), name: 'Bàn VIP B3'),
      ];
      await _dataService.saveBilliardTables(_billiardTables);
    }

    _isLoading = false;
    notifyListeners(); // Thông báo đã tải xong dữ liệu, UI có thể hiển thị
  }

  // Hàm lưu tất cả dữ liệu
  Future<void> _saveAllData() async {
    await _dataService.saveTransactions(_transactions);
    await _dataService.saveMenuItems(_menuItems);
    await _dataService.saveBilliardTables(_billiardTables);
  }

  // --- HÀM QUẢN LÝ TIỀN 1 GIỜ CHƠI ---
  Future<void> setHourlyRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hourlyRate', rate);
    _hourlyRate = rate;
    notifyListeners(); // Thông báo thay đổi
  }

  // --- HÀM QUẢN LÝ GIAO DỊCH ---
  void addTransaction(String tableId, List<OrderedItem> items, double initialAmount, double discount, double finalAmount) {
    _transactions.add(
      Transaction(
        id: _uuid.v4(),
        tableId: tableId,
        orderedItems: items,
        initialBillAmount: initialAmount,
        discountAmount: discount,
        finalBillAmount: finalAmount,
        transactionTime: DateTime.now(),
      ),
    );
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  void deleteTransaction(String transactionId) {
    _transactions.removeWhere((t) => t.id == transactionId);
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  // --- HÀM QUẢN LÝ MÓN ĂN ---
  void addMenuItem(String name, double price, String category) {
    _menuItems.add(MenuItem(id: _uuid.v4(), name: name, price: price, category: category));
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  void updateMenuItem(String id, String newName, double newPrice, String newCategory) {
    final index = _menuItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _menuItems[index] = MenuItem(
        id: id,
        name: newName,
        price: newPrice,
        category: newCategory,
      );
      _saveAllData();
      notifyListeners(); // Thông báo thay đổi
    }
  }

  void deleteMenuItem(String id) {
    _menuItems.removeWhere((item) => item.id == id);
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  // --- HÀM QUẢN LÝ BÀN BILLIARD ---
  void addBilliardTable(String name) {
    _billiardTables.add(BilliardTable(id: _uuid.v4(), name: name));
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  void updateBilliardTable(String id, String newName) {
    final index = _billiardTables.indexWhere((table) => table.id == id);
    if (index != -1) {
      // Giữ lại các trạng thái chơi khi cập nhật tên
      _billiardTables[index] = BilliardTable(
        id: id,
        name: newName,
        isOccupied: _billiardTables[index].isOccupied,
        startTime: _billiardTables[index].startTime,
        endTime: _billiardTables[index].endTime,
        orderedItems: _billiardTables[index].orderedItems,
      );
      _saveAllData();
      notifyListeners(); // Thông báo thay đổi
    }
  }

  void deleteBilliardTable(String id) {
    _billiardTables.removeWhere((table) => table.id == id);
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  // Hàm để khởi động hoặc dừng bàn
  void toggleTableStatus(BilliardTable table) {
    // Cần tìm đúng đối tượng bàn trong danh sách _billiardTables để cập nhật
    final tableToUpdate = _billiardTables.firstWhere((t) => t.id == table.id);
    if (tableToUpdate.isOccupied) {
      tableToUpdate.stop();
    } else {
      tableToUpdate.start();
    }
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  // Hàm để reset bàn
  void resetBilliardTable(BilliardTable table) {
    // Cần tìm đúng đối tượng bàn trong danh sách _billiardTables để cập nhật
    final tableToUpdate = _billiardTables.firstWhere((t) => t.id == table.id);
    tableToUpdate.reset();
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  // Hàm để cập nhật OrderedItem cho một bàn cụ thể
  void updateTableOrderedItems(BilliardTable table, MenuItem item, int quantityChange) {
    // Cần tìm đúng đối tượng bàn trong danh sách _billiardTables để cập nhật
    final tableToUpdate = _billiardTables.firstWhere((t) => t.id == table.id);
    tableToUpdate.addOrUpdateOrderedItem(item.id, quantityChange);
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  // --- SAO LƯU VÀ PHỤC HỒI DỮ LIỆU ---
  // Các hàm này bây giờ nhận BuildContext để hiển thị SnackBar
  Future<void> backupData(BuildContext context) async {
    final backupJsonString = await _dataService.backupAllDataToJsonString();
    if (backupJsonString != null) {
      final fileName = 'bill_calculator_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      try {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String appDocPath = appDocDir.path;
        final File tempFile = File('$appDocPath/$fileName');
        await tempFile.writeAsString(backupJsonString);

        await Share.shareXFiles([XFile(tempFile.path)], text: 'Dữ liệu sao lưu từ ứng dụng Bill Calculator');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã sao lưu dữ liệu thành công!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi sao lưu dữ liệu: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể sao lưu dữ liệu. Có lỗi xảy ra.')),
      );
    }
  }

  Future<void> restoreData(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final String jsonString = await file.readAsString();
        final bool success = await _dataService.restoreAllDataFromJsonString(jsonString);

        if (success) {
          await _loadData(); // Tải lại dữ liệu sau khi phục hồi
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã phục hồi dữ liệu thành công!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phục hồi dữ liệu thất bại. File không hợp lệ?')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đọc file phục hồi: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy chọn file phục hồi.')),
      );
    }
  }
}