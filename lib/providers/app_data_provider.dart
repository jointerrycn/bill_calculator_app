// lib/providers/app_data_provider.dart
import 'dart:convert';

import 'package:bill_calculator_app/helper/extensions.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_thermal_printer/utils/printer.dart'; // ✅ Xóa bỏ import này nếu không dùng lớp Printer từ gói này
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
// import '../models/printer.dart'; // ✅ Xóa bỏ import model Printer của bạn nếu không dùng
import '../models/transaction.dart';

// Import data service
import '../data/data_service.dart';
import '../services/ThermalPrinterService.dart';
// import '../services/ThermalPrinterService.dart'; // ✅ Xóa bỏ import này vì AppDataProvider không cần biết về ThermalPrinterService

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
  List<Invoice> get invoices => _invoices;
  List<Transaction> get transactions => _transactions;
  List<BilliardTable> get billiardTables => _billiardTables;
  double get hourlyRate => _hourlyRate;
  bool get isLoading => _isLoading;

  String _bankName = '';
  String _bankAccountNumber = '';
  String _bankAccountHolder = '';
  String _qrImageUrl = '';
  List<CustomPaperSize> _customPaperSizes = [];
  List<CustomPaperSize> get customPaperSizes => _customPaperSizes;

  String _selectedPaperSize = 'roll80';
  String get selectedPaperSize => _selectedPaperSize;
  String _shopName = 'Tên Quán Bi-a Của Bạn';
  String get shopName => _shopName;
  String _shopPhone = 'SĐT của quán';
  String get shopPhone => _shopPhone;
  String _shopAddress = 'Địa chỉ quán của bạn';
  String get shopAddress => _shopAddress;

  String get bankName => _bankName;
  String get bankAccountNumber => _bankAccountNumber;
  String get bankAccountHolder => _bankAccountHolder;
  String get qrImageUrl => _qrImageUrl;

  // ✅ LOẠI BỎ CÁC THUỘC TÍNH VÀ GETTER SAU VÌ ĐÃ CHUYỂN SANG THERMALPRINTERSERVICE:
  // String? _defaultUsbPrinterUrl;
  // String? _defaultUsbPrinterName;
  // DefaultPrinterType _defaultPrinterType = DefaultPrinterType.none;
  // String? get defaultUsbPrinterUrl => _defaultUsbPrinterUrl;
  // String? get defaultUsbPrinterName => _defaultUsbPrinterName;
  // DefaultPrinterType get defaultPrinterType => _defaultPrinterType;


  AppDataProvider() {
    _loadData();
  }

  Future<void> reloadData() async {
    debugPrint('AppDataProvider: Đang tải lại dữ liệu...');
    await _loadData();
  }

  // Hàm tải dữ liệu ban đầu
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _menuItems = await _dataService.loadMenuItems();
    _transactions = await _dataService.loadTransactions();
    _billiardTables = await _dataService.loadBilliardTables();

    final prefs = await SharedPreferences.getInstance();

    final String? customPaperSizesJson = prefs.getString('customPaperSizes');
    if (customPaperSizesJson != null) {
      final List<dynamic> decodedCustomSizes = jsonDecode(customPaperSizesJson);
      _customPaperSizes = decodedCustomSizes.map((json) => CustomPaperSize.fromJson(json)).toList();
    } else {
      _customPaperSizes = [];
    }

    _shopName = prefs.getString('shopName') ?? 'Tên Quán Bi-a Của Bạn';
    _shopAddress = prefs.getString('shopAddress') ?? 'Địa chỉ quán của bạn';
    _shopPhone = prefs.getString('shopPhone') ?? 'SĐT của quán của bạn';
    _hourlyRate = prefs.getDouble('hourlyRate') ?? 50000.0;
    _selectedPaperSize = prefs.getString('selectedPaperSize') ?? 'roll80';

    _bankName = prefs.getString('bankName') ?? '';
    _bankAccountNumber = prefs.getString('bankAccountNumber') ?? '';
    _bankAccountHolder = prefs.getString('bankAccountHolder') ?? '';
    _qrImageUrl = prefs.getString('qrImageUrl') ?? '';

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

    final invoicesJson = prefs.getStringList('invoices');
    if (invoicesJson != null) {
      _invoices = invoicesJson
          .map((jsonString) => Invoice.fromJson(json.decode(jsonString)))
          .toList();
    }
    _invoices.sort((a, b) => b.billDateTime.compareTo(a.billDateTime));

    cleanUpOldInvoices();
    _isLoading = false;

    // ✅ LOẠI BỎ CÁC DÒNG SAU VÌ ĐÃ CHUYỂN SANG THERMALPRINTERSERVICE:
    // _defaultUsbPrinterUrl = prefs.getString('defaultUsbPrinterUrl');
    // _defaultUsbPrinterName = prefs.getString('defaultUsbPrinterName');
    // final printerTypeString = prefs.getString('defaultPrinterType');
    // _defaultPrinterType = DefaultPrinterType.values.firstWhere(
    //       (e) => e.toString() == printerTypeString,
    //   orElse: () => DefaultPrinterType.none,
    // );
    notifyListeners();
  }

  // Hàm lưu tất cả dữ liệu
  Future<void> _saveAllData() async {
    await _dataService.saveTransactions(_transactions);
    await _dataService.saveMenuItems(_menuItems);
    await _dataService.saveBilliardTables(_billiardTables);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('shopAddress', _shopAddress);
    await prefs.setString('shopName', _shopName);
    await prefs.setString('shopPhone', _shopPhone);
    await prefs.setString('selectedPaperSize', _selectedPaperSize);

    final String customPaperSizesJson = jsonEncode(_customPaperSizes.map((size) => size.toJson()).toList());
    await prefs.setString('customPaperSizes', customPaperSizesJson);

    // ✅ LOẠI BỎ CÁC DÒNG SAU VÌ ĐÃ CHUYỂN SANG THERMALPRINTERSERVICE:
    // if (_defaultUsbPrinterUrl != null) {
    //   await prefs.setString('defaultUsbPrinterUrl', _defaultUsbPrinterUrl!);
    //   await prefs.setString('defaultUsbPrinterName', _defaultUsbPrinterName ?? '');
    // } else {
    //   await prefs.remove('defaultUsbPrinterUrl');
    //   await prefs.remove('defaultUsbPrinterName');
    // }
    // await prefs.setString('defaultPrinterType', _defaultPrinterType.toString());
    notifyListeners();
  }

  // ✅ LOẠI BỎ CÁC SETTER SAU VÌ ĐÃ CHUYỂN SANG THERMALPRINTERSERVICE:
  // set defaultUsbPrinter(Printer? printer) {
  //   _defaultUsbPrinterUrl = printer?.url;
  //   _defaultUsbPrinterName = printer?.name;
  //   _saveAllData(); // Hoặc bạn có thể cân nhắc gọi _saveAllData() nếu bạn muốn lưu ngay lập tức
  // }
  // set defaultPrinterType(DefaultPrinterType type) {
  //   _defaultPrinterType = type;
  //   _saveAllData(); // Hoặc bạn có thể cân nhắc gọi _saveAllData() nếu bạn muốn lưu ngay lập tức
  // }


  Future<PaperSizeOption> loadPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedPaperSize');
    return saved == PaperSizeOption.mm80.toString()
        ? PaperSizeOption.mm80
        : PaperSizeOption.mm58;
  }

  Future<void> saveInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = _invoices.map((invoice) => json.encode(invoice.toJson())).toList();
    await prefs.setStringList('invoices', invoicesJson);
  }

  void addInvoice(Invoice invoice) {
    _invoices.add(invoice);
    _invoices.sort((a, b) => b.billDateTime.compareTo(a.billDateTime));
    saveInvoices();
    notifyListeners();
  }

  void removeInvoice(String invoiceId) {
    _invoices.removeWhere((invoice) => invoice.id == invoiceId);
    saveInvoices();
    notifyListeners();
  }

  void cleanUpOldInvoices() {
    final DateTime now = DateTime.now();
    final DateTime cutoffDate = now.subtract(const Duration(days: 30));

    final int initialCount = _invoices.length;
    _invoices.removeWhere((invoice) => invoice.billDateTime.isBefore(cutoffDate));

    if (_invoices.length < initialCount) {
      saveInvoices();
      notifyListeners();
      debugPrint('Đã xóa ${initialCount - _invoices.length} hóa đơn cũ hơn ${DateFormat('dd/MM/yyyy').format(cutoffDate)}.');
    }
  }

  void clearAllInvoices() {
    _invoices.clear();
    saveInvoices();
    notifyListeners();
  }

  Future<void> updateShopInfo2(
      String name,
      String address,
      String phone,
      String bankName,
      String bankAccountNumber,
      String bankAccountHolder,
      String qrImageUrl,
      ) async {
    _shopName = name;
    _shopAddress = address;
    _shopPhone = phone;
    _bankName = bankName;
    _bankAccountNumber = bankAccountNumber;
    _bankAccountHolder = bankAccountHolder;
    _qrImageUrl = qrImageUrl;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', _shopName);
    await prefs.setString('shopAddress', _shopAddress);
    await prefs.setString('shopPhone', _shopPhone);
    await prefs.setString('bankName', _bankName);
    await prefs.setString('bankAccountNumber', _bankAccountNumber);
    await prefs.setString('bankAccountHolder', _bankAccountHolder);
    await prefs.setString('qrImageUrl', _qrImageUrl);

    notifyListeners();
  }

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

  Future<void> setHourlyRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hourlyRate', rate);
    _hourlyRate = rate;
    notifyListeners();
  }

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
    notifyListeners();
  }

  void deleteTransaction(String transactionId) {
    _transactions.removeWhere((t) => t.id == transactionId);
    _saveAllData();
    notifyListeners();
  }

  void addMenuItem(String name, double price) {
    _menuItems.add(MenuItem(id: _uuid.v4(), name: name, price: price));
    _saveAllData();
    notifyListeners();
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
      notifyListeners();
    }
  }

  void deleteMenuItem(String id) {
    _menuItems.removeWhere((item) => item.id == id);
    _saveAllData();
    notifyListeners();
  }

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
    notifyListeners();
  }

  void toggleTableStatus(BilliardTable table) {
    final tableToUpdate = _billiardTables.firstWhere((t) => t.id == table.id);
    if (tableToUpdate.isOccupied) {
      tableToUpdate.stop();
    } else {
      tableToUpdate.start();
    }
    _saveAllData();
    notifyListeners();
  }

  void resetBilliardTable(BilliardTable table) {
    final tableToUpdate = _billiardTables.firstWhere((t) => t.id == table.id);
    tableToUpdate.reset();
    _saveAllData();
    notifyListeners();
  }

  void updateTableOrderedItems(BilliardTable table, MenuItem item, int quantityChange) {
    final tableToUpdate = _billiardTables.firstWhere((t) => t.id == table.id);
    tableToUpdate.addOrUpdateOrderedItem(item.id, quantityChange,item.name,item.price);
    _saveAllData();
    notifyListeners();
  }

  Future<void> backupData(BuildContext context) async {
    try {
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
        // ✅ KHÔNG BAO GỒM CÁC THÔNG TIN MÁY IN MẶC ĐỊNH Ở ĐÂY
      };

      final String jsonString = jsonEncode(dataToBackup);

      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String fileName = 'Bi-a_Smart_Backup_$timestamp.json';

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dữ liệu sao lưu ứng dụng Bi-a Smart',
        subject: 'Sao lưu dữ liệu ứng dụng Bi-a Smart',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo file sao lưu. Vui lòng chọn ứng dụng để lưu hoặc chia sẻ.')),
      );

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
          await _loadData();
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
      return 0.0;
    }
    final double playedHours = playedDuration.inMinutes / 60.0;
    debugPrint('Giá bàn ${table.name} là ${table.price}, thời gian chơi là $playedHours giờ');
    return playedHours * table.price;
  }

  void transferTable(String fromTableId, String toTableId) {
    final fromTable = _billiardTables.firstWhereOrNull((t) => t.id == fromTableId);
    final toTable = _billiardTables.firstWhereOrNull((t) => t.id == toTableId);

    if (fromTable == null || toTable == null) return;
    if (!fromTable.isOccupied || toTable.isOccupied) return;

    toTable.isOccupied = true;
    toTable.startTime = fromTable.startTime;
    toTable.totalPlayedTime = fromTable.totalPlayedTime;
    toTable.orderedItems = List<OrderedItem>.from(fromTable.orderedItems);

    fromTable.isOccupied = false;
    fromTable.startTime = null;
    fromTable.endTime = null;
    fromTable.totalPlayedTime = Duration.zero;
    fromTable.orderedItems.clear();

    _saveAllData();
    notifyListeners();
  }
}