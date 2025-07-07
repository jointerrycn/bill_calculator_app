// lib/providers/app_data_provider.dart
import 'dart:convert';

import 'package:bill_calculator_app/helper/extensions.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Required for File and Directory
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
// Import các model
import '../models/billiard_table.dart';
import '../models/custom_paper_size.dart';
import '../models/invoice.dart';
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
  List<Invoice> _invoices = [];
  double _hourlyRate = 0.0;
  bool _isLoading = true;

  // Getters để truy cập dữ liệu từ bên ngoài (chỉ đọc)
  List<MenuItem> get menuItems => _menuItems;
  List<Invoice> get invoices => _invoices; // <-- THÊM GETTER CHO HÓA ĐƠN
  List<Transaction> get transactions => _transactions;
  List<BilliardTable> get billiardTables => _billiardTables;
  double get hourlyRate => _hourlyRate;
  bool get isLoading => _isLoading;
  String _bankName = ''; // Tên ngân hàng
  String _bankAccountNumber = ''; // Số tài khoản
  String _bankAccountHolder = ''; // Tên chủ tài khoản
  String _qrImageUrl = ''; // URL của hình ảnh QR Code (ví dụ: từ Cloudinary, Imgur, hoặc bất kỳ dịch vụ lưu trữ ảnh nào)
  List<CustomPaperSize> _customPaperSizes = [];
  List<CustomPaperSize> get customPaperSizes => _customPaperSizes;


  String _selectedPaperSize = 'roll80'; // Biến để lưu kích thước giấy đã chọn
  String get selectedPaperSize => _selectedPaperSize; // Getter để truy cập giá trị
  String _shopName = 'Tên Quán Bi-a Của Bạn'; //
  String get shopName => _shopName;
  String _shopPhone = 'SĐT của quán'; //
  String get shopPhone  => _shopPhone;

  String _shopAddress = 'Địa chỉ quán của bạn'; //
  String get shopAddress => _shopAddress;


  String get bankName => _bankName;
  String get bankAccountNumber => _bankAccountNumber;
  String get bankAccountHolder => _bankAccountHolder;
  String get qrImageUrl => _qrImageUrl;
  AppDataProvider() {
    // Khởi tạo và tải dữ liệu ngay khi provider được tạo
    _loadData();
  }
// THÊM PHƯƠNG THỨC PUBLIC NÀY VÀO ĐÂY
  Future<void> reloadData() async {
    debugPrint('AppDataProvider: Đang tải lại dữ liệu...');
    await _loadData(); // Gọi lại hàm tải dữ liệu private
  }

  // Hàm tải dữ liệu ban đầu
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners(); // Thông báo cho UI biết đang tải dữ liệu

    _menuItems = await _dataService.loadMenuItems();
    _transactions = await _dataService.loadTransactions();
    _billiardTables = await _dataService.loadBilliardTables();

    final prefs = await SharedPreferences.getInstance();

    // Tải các loại giấy tùy chỉnh
    final String? customPaperSizesJson = prefs.getString('customPaperSizes');
    if (customPaperSizesJson != null) {
      final List<dynamic> decodedCustomSizes = jsonDecode(customPaperSizesJson);
      _customPaperSizes = decodedCustomSizes.map((json) => CustomPaperSize.fromJson(json)).toList();
    } else {
      _customPaperSizes = [];
    }

    _shopName = prefs.getString('shopName') ?? 'Tên Quán Bi-a Của Bạn'; // <-- TẢI TÊN QUÁN
    _shopAddress = prefs.getString('shopAddress') ?? 'Địa chỉ quán của bạn'; // <-- TẢI ĐỊA CHỈ
    _shopPhone= prefs.getString('shopPhone') ?? 'SĐT của quán của bạn'; // <-- TẢI ĐỊA CHỈ
    _hourlyRate = prefs.getDouble('hourlyRate') ?? 50000.0;
    _selectedPaperSize = prefs.getString('selectedPaperSize') ?? 'roll80';

    // Tải thông tin QR thanh toán <-- THÊM PHẦN NÀY
    _bankName = prefs.getString('bankName') ?? '';
    _bankAccountNumber = prefs.getString('bankAccountNumber') ?? '';
    _bankAccountHolder = prefs.getString('bankAccountHolder') ?? '';
    _qrImageUrl = prefs.getString('qrImageUrl') ?? '';
    // Khởi tạo dữ liệu mặc định nếu trống
    if (_menuItems.isEmpty) {
      _menuItems = [
        MenuItem(id: _uuid.v4(), name: 'Phở Bò', price: 50000),
        MenuItem(id: _uuid.v4(), name: 'Bún Chả', price: 45000),
        MenuItem(id: _uuid.v4(), name: 'Cà Phê Sữa', price: 25000),
        MenuItem(id: _uuid.v4(), name: 'Trà Đá', price: 10000),
        MenuItem(id: _uuid.v4(), name: 'Bánh Mì', price: 20000),
      ];
      await _dataService.saveMenuItems(_menuItems);
    }

    if (_billiardTables.isEmpty) {
      _billiardTables = [
        BilliardTable(id: _uuid.v4(), name: 'Bàn A1', price: 50000),
        BilliardTable(id: _uuid.v4(), name: 'Bàn A2', price: 50000),
        BilliardTable(id: _uuid.v4(), name: 'Bàn VIP B3', price: 100000),
      ];
      await _dataService.saveBilliardTables(_billiardTables);
    }
    // Tải danh sách hóa đơn <-- THÊM PHẦN NÀY
    final invoicesJson = prefs.getStringList('invoices');
    if (invoicesJson != null) {
      _invoices = invoicesJson
          .map((jsonString) => Invoice.fromJson(json.decode(jsonString)))
          .toList();
    }
    // Sắp xếp lại hóa đơn theo thời gian mới nhất lên đầu sau khi tải
    _invoices.sort((a, b) => b.billDateTime.compareTo(a.billDateTime));

    // Gọi hàm dọn dẹp hóa đơn cũ ngay sau khi tải dữ liệu
    cleanUpOldInvoices(); // <-- GỌI HÀM DỌN DẸP Ở ĐÂY
    _isLoading = false;

    notifyListeners(); // Thông báo đã tải xong dữ liệu, UI có thể hiển thị
  }

  // Hàm lưu tất cả dữ liệu
  Future<void> _saveAllData() async {
    await _dataService.saveTransactions(_transactions);
    await _dataService.saveMenuItems(_menuItems);
    await _dataService.saveBilliardTables(_billiardTables);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('shopAddress', _shopAddress); // <-- LƯU ĐỊA CHỈ
    await prefs.setString('shopName', _shopName); // <-- LƯU TÊN QUÁN
    await prefs.setString('shopPhone', _shopPhone); // <-- LƯU SĐT
    await prefs.setString('selectedPaperSize', _selectedPaperSize);
    // Lưu các loại giấy tùy chỉnh
    final String customPaperSizesJson = jsonEncode(_customPaperSizes.map((size) => size.toJson()).toList());
    await prefs.setString('customPaperSizes', customPaperSizesJson);
  }
  // Phương thức lưu hóa đơn
  Future<void> saveInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = _invoices.map((invoice) => json.encode(invoice.toJson())).toList();
    await prefs.setStringList('invoices', invoicesJson);
  }

  // Phương thức thêm hóa đơn mới
  void addInvoice(Invoice invoice) {
    _invoices.add(invoice);
    _invoices.sort((a, b) => b.billDateTime.compareTo(a.billDateTime)); // Sắp xếp theo thời gian mới nhất lên đầu
    saveInvoices();
    notifyListeners(); // Thông báo AppDataProvider có thay đổi
  }
  // Phương thức xóa một hóa đơn cụ thể
  void removeInvoice(String invoiceId) {
    _invoices.removeWhere((invoice) => invoice.id == invoiceId);
    saveInvoices(); // Lưu lại sau khi xóa
    notifyListeners(); // Thông báo AppDataProvider có thay đổi
  }
  // DỌN DẸP HÓA ĐƠN CŨ ---
  void cleanUpOldInvoices() {
    final DateTime now = DateTime.now();
    // Đặt ngưỡng thời gian: hóa đơn cũ hơn 30 ngày sẽ bị xóa
    final DateTime cutoffDate = now.subtract(const Duration(days: 30)); // Hoặc 31 ngày tùy ý bạn

    final int initialCount = _invoices.length;
    _invoices.removeWhere((invoice) => invoice.billDateTime.isBefore(cutoffDate));

    if (_invoices.length < initialCount) {
      // Chỉ lưu lại và thông báo nếu có hóa đơn bị xóa
      saveInvoices();
      notifyListeners();
      debugPrint('Đã xóa ${initialCount - _invoices.length} hóa đơn cũ hơn ${DateFormat('dd/MM/yyyy').format(cutoffDate)}.');
    }
  }
  // Phương thức xóa tất cả hóa đơn
  void clearAllInvoices() {
    _invoices.clear();
    saveInvoices(); // Lưu lại sau khi xóa
    notifyListeners(); // Thông báo AppDataProvider có thay đổi
  }
  // Phương thức cập nhật thông tin cửa hàng và thêm thông tin QR thanh toán
  Future<void> updateShopInfo2(
      String name,
      String address,
      String phone,
      String bankName, // <-- THÊM THAM SỐ MỚI
      String bankAccountNumber, // <-- THÊM THAM SỐ MỚI
      String bankAccountHolder, // <-- THÊM THAM SỐ MỚI
      String qrImageUrl, // <-- THÊM THAM SỐ MỚI
      ) async {
    _shopName = name;
    _shopAddress = address;
    _shopPhone = phone;
    _bankName = bankName;
    _bankAccountNumber = bankAccountNumber;
    _bankAccountHolder = bankAccountHolder;
    _qrImageUrl = qrImageUrl; // Cập nhật

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', _shopName);
    await prefs.setString('shopAddress', _shopAddress);
    await prefs.setString('shopPhone', _shopPhone);
    await prefs.setString('bankName', _bankName); // Lưu
    await prefs.setString('bankAccountNumber', _bankAccountNumber); // Lưu
    await prefs.setString('bankAccountHolder', _bankAccountHolder); // Lưu
    await prefs.setString('qrImageUrl', _qrImageUrl); // Lưu

    notifyListeners(); // Thông báo khi thông tin quán hoặc QR thay đổi
  }
// --- Phương thức cập nhật tên quán và địa chỉ ---

  void updateSelectedPaperSize(String newSize) {
    if (_selectedPaperSize != newSize) {
      _selectedPaperSize = newSize;
      _saveAllData();
      notifyListeners();
    }
  }
  // --- Phương thức quản lý giấy tùy chỉnh ---
  void addCustomPaperSize(CustomPaperSize newSize) {
    _customPaperSizes.add(newSize);
    _saveAllData();
    notifyListeners();
  }

  void removeCustomPaperSize(String name) {
    _customPaperSizes.removeWhere((size) => size.name == name);
    _saveAllData();
    notifyListeners();
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
  void addMenuItem(String name, double price) {
    _menuItems.add(MenuItem(id: _uuid.v4(), name: name, price: price));
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  void updateMenuItem(String id, String newName, double newPrice) {
    final index = _menuItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _menuItems[index] = MenuItem(
        id: id,
        name: newName,
        price: newPrice,
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
  void addBilliardTable(String name, double price) {
    final table = BilliardTable(
      id: UniqueKey().toString(),
      name: name,
      price: price,
    );
    _billiardTables.add(table);
    _saveAllData();
    notifyListeners();
  }

  void updateBilliardTable(String id, String name, double price) {
    final index = _billiardTables.indexWhere((t) => t.id == id);
    if (index != -1) {
      _billiardTables[index].name = name;
      _billiardTables[index].price = price;
      notifyListeners();
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
    tableToUpdate.addOrUpdateOrderedItem(item.id, quantityChange,item.name,item.price);
    _saveAllData();
    notifyListeners(); // Thông báo thay đổi
  }

  // --- SAO LƯU VÀ PHỤC HỒI DỮ LIỆU ---
  // Các hàm này bây giờ nhận BuildContext để hiển thị SnackBar

  Future<void> backupData(BuildContext context) async {
    try {
      // 1. Lấy tất cả dữ liệu cần sao lưu
      final Map<String, dynamic> dataToBackup = {
        'shopName': _shopName,
        'shopAddress': _shopAddress,
        'shopPhone': _shopPhone,
        'bankName': _bankName,
        'bankAccountNumber': _bankAccountNumber,
        'bankAccountHolder': _bankAccountHolder,
        'qrImageUrl': _qrImageUrl,
        'selectedPaperSize': _selectedPaperSize,
        'hourlyRate': _hourlyRate,
        'customPaperSizes': _customPaperSizes.map((s) => s.toJson()).toList(),
        'menuItems': _menuItems.map((item) => item.toJson()).toList(),
        'transactions': _transactions.map((t) => t.toJson()).toList(),
        'billiardTables': _billiardTables.map((b) => b.toJson()).toList(),
        'invoices': _invoices.map((i) => i.toJson()).toList(),
      };

      final String jsonString = jsonEncode(dataToBackup);

      // 2. Tạo tên file
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String fileName = 'Bi-a_Smart_Backup_$timestamp.json';

      // 3. Ghi file vào thư mục cache của ứng dụng
      // Đây là thư mục riêng tư của ứng dụng, không cần quyền đặc biệt
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // 4. Sử dụng share_plus để chia sẻ file
      // Điều này sẽ mở hộp thoại chia sẻ của hệ thống.
      // Người dùng có thể chọn các ứng dụng khác nhau
      // để lưu file (ví dụ: "Lưu vào Tệp", Google Drive, Zalo, Email, v.v.)
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dữ liệu sao lưu ứng dụng Bi-a Smart',
        subject: 'Sao lưu dữ liệu ứng dụng Bi-a Smart', // Tiêu đề cho email/tin nhắn
      );

      // Hiển thị thông báo sau khi hộp thoại chia sẻ được mở
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo file sao lưu. Vui lòng chọn ứng dụng để lưu hoặc chia sẻ.')),
      );

      // Tùy chọn: Bạn có thể xóa file tạm thời nếu muốn
      // file.delete(); // Bỏ comment nếu muốn xóa file sau khi chia sẻ

    } catch (e, stacktrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi sao lưu dữ liệu: $e'),
          backgroundColor: Colors.orange,),
      );
      debugPrint('Lỗi chi tiết khi sao lưu: $e');
      debugPrint('Stacktrace: $stacktrace');
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
            const SnackBar(content: Text('Phục hồi dữ liệu thất bại. File không hợp lệ?'),
              backgroundColor: Colors.orange,),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đọc file phục hồi: $e'),
            backgroundColor: Colors.orange,),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy chọn file phục hồi.'),
          backgroundColor: Colors.orange,),
      );
    }
  }

  double getHourlyCostForTable(String tableId, Duration playedDuration) {
    final BilliardTable? table = _billiardTables.firstWhereOrNull((t) => t.id == tableId);
    if (table == null) {
      return 0.0; // Hoặc ném lỗi nếu bàn không tồn tại
    }
    final double playedHours = playedDuration.inMinutes / 60.0;
    debugPrint('Giá bàn ${table.name} là ${table.price}, thời gian chơi là $playedHours giờ');
    return playedHours * table.price; // <-- SỬ DỤNG GIÁ RIÊNG CỦA BÀN
  }

  /// Chuyển trạng thái, thời gian, orderedItems từ bàn này sang bàn khác
  void transferTable(String fromTableId, String toTableId) {
    final fromTable = _billiardTables.firstWhereOrNull((t) => t.id == fromTableId);
    final toTable = _billiardTables.firstWhereOrNull((t) => t.id == toTableId);

    if (fromTable == null || toTable == null) return;
    if (!fromTable.isOccupied || toTable.isOccupied) return; // Chỉ chuyển nếu bàn nguồn đang chơi và bàn đích đang trống

    // Chuyển trạng thái, thời gian, orderedItems
    toTable.isOccupied = true;
    toTable.startTime = fromTable.startTime;
    toTable.totalPlayedTime = fromTable.totalPlayedTime;
    toTable.orderedItems = List<OrderedItem>.from(fromTable.orderedItems);

    // Reset bàn cũ
    fromTable.isOccupied = false;
    fromTable.startTime = null;
    fromTable.endTime = null;
    fromTable.totalPlayedTime = Duration.zero;
    fromTable.orderedItems.clear();

    _saveAllData();
    notifyListeners();
  }
}