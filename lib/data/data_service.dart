import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import các model từ thư mục models
import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/ordered_item.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/models/transaction.dart';

class DataService {
  // Tên các file JSON để lưu trữ dữ liệu
  static const String _transactionsFileName = 'transactions.json';
  static const String _menuItemsFileName = 'menu_items.json';
  static const String _billiardTablesFileName = 'billiard_tables.json';
  // Key cho SharedPreferences để lưu trữ giá tiền theo giờ
  static const String _hourlyRateKey = 'hourlyRate';

  // --- Lấy đường dẫn và File cục bộ ---

  /// Trả về đường dẫn đến thư mục tài liệu của ứng dụng.
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Trả về đối tượng File cho dữ liệu giao dịch.
  Future<File> get _localTransactionsFile async {
    final path = await _localPath;
    return File('$path/$_transactionsFileName');
  }

  /// Trả về đối tượng File cho dữ liệu món ăn.
  Future<File> get _localMenuItemsFile async {
    final path = await _localPath;
    return File('$path/$_menuItemsFileName');
  }

  /// Trả về đối tượng File cho dữ liệu bàn billiard.
  Future<File> get _localBilliardTablesFile async {
    final path = await _localPath;
    return File('$path/$_billiardTablesFileName');
  }

  // --- Lưu dữ liệu cục bộ ---

  /// Lưu danh sách các giao dịch vào tệp JSON.
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final file = await _localTransactionsFile;
    // Chuyển đổi danh sách các đối tượng Transaction thành một danh sách Map JSON
    final String jsonString = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  /// Lưu danh sách các món ăn vào tệp JSON.
  Future<void> saveMenuItems(List<MenuItem> menuItems) async {
    final file = await _localMenuItemsFile;
    // Chuyển đổi danh sách các đối tượng MenuItem thành một danh sách Map JSON
    final String jsonString = jsonEncode(menuItems.map((m) => m.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  /// Lưu danh sách các bàn billiard vào tệp JSON.
  Future<void> saveBilliardTables(List<BilliardTable> billiardTables) async {
    final file = await _localBilliardTablesFile;
    // Chuyển đổi danh sách các đối tượng BilliardTable thành một danh sách Map JSON
    final String jsonString = jsonEncode(billiardTables.map((t) => t.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  // --- Tải dữ liệu cục bộ ---

  /// Tải danh sách các giao dịch từ tệp JSON.
  Future<List<Transaction>> loadTransactions() async {
    try {
      final file = await _localTransactionsFile;
      // Nếu file không tồn tại, trả về danh sách rỗng
      if (!await file.exists()) {
        return [];
      }
      final String jsonString = await file.readAsString();
      // Giải mã chuỗi JSON thành List<dynamic> và sau đó chuyển đổi thành List<Transaction>
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      // In lỗi ra console nếu có vấn đề khi tải
      print('Lỗi khi tải giao dịch: $e');
      return [];
    }
  }

  /// Tải danh sách các món ăn từ tệp JSON.
  Future<List<MenuItem>> loadMenuItems() async {
    try {
      final file = await _localMenuItemsFile;
      if (!await file.exists()) {
        return [];
      }
      final String jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Lỗi khi tải món ăn: $e');
      return [];
    }
  }

  /// Tải danh sách các bàn billiard từ tệp JSON.
  Future<List<BilliardTable>> loadBilliardTables() async {
    try {
      final file = await _localBilliardTablesFile;
      if (!await file.exists()) {
        return [];
      }
      final String jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => BilliardTable.fromJson(json)).toList();
    } catch (e) {
      print('Lỗi khi tải bàn billiard: $e');
      return [];
    }
  }

  // --- Sao lưu dữ liệu (bao gồm cả Shared Preferences) ---

  /// Hàm tiện ích để đọc nội dung file JSON nếu tồn tại.
  Future<String?> _getDataJsonString(File file) async {
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// Tạo một chuỗi JSON chứa tất cả dữ liệu ứng dụng để sao lưu.
  Future<String?> backupAllDataToJsonString() async {
    try {
      final transactionsJson = await _getDataJsonString(await _localTransactionsFile);
      final menuItemsJson = await _getDataJsonString(await _localMenuItemsFile);
      final billiardTablesJson = await _getDataJsonString(await _localBilliardTablesFile);

      final prefs = await SharedPreferences.getInstance();
      final double? hourlyRate = prefs.getDouble(_hourlyRateKey);

      final Map<String, dynamic> backupData = {
        'transactions': transactionsJson != null ? jsonDecode(transactionsJson) : [],
        'menuItems': menuItemsJson != null ? jsonDecode(menuItemsJson) : [],
        'billiardTables': billiardTablesJson != null ? jsonDecode(billiardTablesJson) : [],
        'hourlyRate': hourlyRate,
        'backupTime': DateTime.now().toIso8601String(), // Thêm thời gian sao lưu để dễ theo dõi
      };
      return jsonEncode(backupData);
    } catch (e) {
      print('Lỗi khi sao lưu dữ liệu: $e');
      return null;
    }
  }

  // --- Phục hồi dữ liệu (bao gồm cả Shared Preferences) ---

  /// Phục hồi tất cả dữ liệu ứng dụng từ một chuỗi JSON đã sao lưu.
  /// Trả về `true` nếu thành công, `false` nếu thất bại.
  Future<bool> restoreAllDataFromJsonString(String jsonBackupData) async {
    try {
      final Map<String, dynamic> backupData = jsonDecode(jsonBackupData);

      // Phục hồi Transactions
      final List<dynamic> transactionsList = backupData['transactions'] ?? [];
      final List<Transaction> restoredTransactions = transactionsList.map((json) => Transaction.fromJson(json)).toList();
      await saveTransactions(restoredTransactions);

      // Phục hồi MenuItems
      final List<dynamic> menuItemsList = backupData['menuItems'] ?? [];
      final List<MenuItem> restoredMenuItems = menuItemsList.map((json) => MenuItem.fromJson(json)).toList();
      await saveMenuItems(restoredMenuItems);

      // Phục hồi BilliardTables
      final List<dynamic> billiardTablesList = backupData['billiardTables'] ?? [];
      final List<BilliardTable> restoredBilliardTables = billiardTablesList.map((json) => BilliardTable.fromJson(json)).toList();
      await saveBilliardTables(restoredBilliardTables);

      // Phục hồi HourlyRate từ SharedPreferences
      final double? restoredHourlyRate = backupData['hourlyRate'];
      if (restoredHourlyRate != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_hourlyRateKey, restoredHourlyRate);
      }

      return true; // Phục hồi thành công
    } catch (e) {
      print('Lỗi khi phục hồi dữ liệu: $e');
      return false; // Phục hồi thất bại
    }
  }
}