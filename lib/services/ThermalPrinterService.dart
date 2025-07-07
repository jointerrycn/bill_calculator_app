import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart' hide CapabilityProfile, Generator, PaperSize;
import 'package:flutter_bluetooth_printer_platform_interface/flutter_bluetooth_printer_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:bill_calculator_app/models/invoice.dart';
import 'package:intl/intl.dart';

enum PrintResult { success, error, noDeviceSelected }

enum PaperSizeOption { mm58, mm80 }

class ThermalPrinterService with ChangeNotifier {
  bool _isScanning = false;
  List<BluetoothDevice> _scanResults = [];
  BluetoothDevice? _selectedDevice;
  BluetoothDevice? _defaultDevice;

  bool get isScanning => _isScanning;
  List<BluetoothDevice> get scanResults => _scanResults;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  BluetoothDevice? get defaultDevice => _defaultDevice;

  ThermalPrinterService() {
    _loadDefaultDevice();
  }

  Future<void> _loadDefaultDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('default_printer_address');
    final name = prefs.getString('default_printer_name');
    if (address != null) {
      _defaultDevice = BluetoothDevice(name: name, address: address);
      notifyListeners();
    }
  }

  Future<void> _saveDefaultDevice() async {
    final prefs = await SharedPreferences.getInstance();
    if (_defaultDevice != null) {
      await prefs.setString('default_printer_address', _defaultDevice!.address!);
      await prefs.setString('default_printer_name', _defaultDevice!.name ?? '');
    } else {
      await prefs.remove('default_printer_address');
      await prefs.remove('default_printer_name');
    }
  }

  void selectDevice(BluetoothDevice device) {
    _selectedDevice = device;
    notifyListeners();
  }

  Future<void> setDefaultDevice(BluetoothDevice? device) async {
    _defaultDevice = device;
    await _saveDefaultDevice();
    notifyListeners();
  }

  Future<void> startScan() async {
    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    // ✅ Yêu cầu quyền
    final status = await Permission.bluetoothScan.request();
    final locationStatus = await Permission.locationWhenInUse.request();
    if (!status.isGranted || !locationStatus.isGranted) {
      debugPrint('Không có quyền Bluetooth hoặc Location');
      _isScanning = false;
      notifyListeners();
      return;
    }

    // ✅ Bắt đầu quét
    FlutterBluetoothPrinter.discovery.listen((state) {
      debugPrint('DiscoveryState: $state');
      // Tạm chưa xử lý device
    });

    Timer(const Duration(seconds: 5), () {
      if (_isScanning) stopScan();
    });
  }

  void stopScan() {
    _isScanning = false;
    notifyListeners();
  }

  Future<void> savePaperSize(PaperSizeOption size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paper_size', size.toString());
  }

  Future<PaperSizeOption> loadPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('paper_size');
    return saved == PaperSizeOption.mm80.toString() ? PaperSizeOption.mm80 : PaperSizeOption.mm58;
  }

  Future<PrintResult> printTicket(List<int> ticket, {BluetoothDevice? device}) async {
    final deviceToPrint = device ?? _defaultDevice;

    if (deviceToPrint == null) {
      debugPrint("Lỗi: Không có máy in nào được chọn hoặc đặt làm mặc định.");
      return PrintResult.noDeviceSelected;
    }

    try {
      final bool? result = await FlutterBluetoothPrinter.printBytes(
        address: deviceToPrint.address!,
        data: Uint8List.fromList(ticket),
        keepConnected: false,
      );

      return result == true ? PrintResult.success : PrintResult.error;
    } catch (e) {
      debugPrint("Đã xảy ra lỗi khi in: $e");
      return PrintResult.error;
    }
  }

  /// ✅ Chuyển tiếng Việt có dấu thành không dấu
  String removeVietnameseDiacritics(String str) {
    const withDiacritics =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễ'
        'ìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄ'
        'ÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';

    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaa'
        'eeeeeeeeeee'
        'iiiii'
        'ooooooooooooooooo'
        'uuuuuuuuuuu'
        'yyyyyd'
        'AAAAAAAAAAAAAAAAA'
        'EEEEEEEEEEE'
        'IIIII'
        'OOOOOOOOOOOOOOOOO'
        'UUUUUUUUUUU'
        'YYYYYD';

    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }

  Future<List<int>> generateReceiptFromInvoice(Invoice invoice) async {
    final paperSize = await loadPaperSize();
    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(
      paperSize == PaperSizeOption.mm80 ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );

    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    List<int> bytes = [];

    // ✅ Tạo nội dung in không dấu
    bytes += generator.text(
      removeVietnameseDiacritics('HOA DON THANH TOAN'),
      styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    );

    bytes += generator.text(
      removeVietnameseDiacritics('Ban: ${invoice.tableName}'),
      styles: PosStyles(align: PosAlign.center),
    );

    bytes += generator.text(
      removeVietnameseDiacritics('Bat dau: ${DateFormat('HH:mm').format(invoice.startTime)}'),
    );
    bytes += generator.text(
      removeVietnameseDiacritics('Ket thuc: ${DateFormat('HH:mm').format(invoice.endTime)}'),
    );
    bytes += generator.text(
      removeVietnameseDiacritics('Thoi gian choi: ${invoice.playedDuration.inMinutes} phut'),
    );
    bytes += generator.text(
      removeVietnameseDiacritics('Gia gio: ${currencyFormat.format(invoice.hourlyRateAtTimeOfBill)}'),
    );
    bytes += generator.text(
      removeVietnameseDiacritics('Tien ban: ${currencyFormat.format(invoice.totalTableCost)}'),
    );

    if (invoice.orderedItems.isNotEmpty) {
      bytes += generator.text(removeVietnameseDiacritics('--- Mon da goi ---'), styles: PosStyles(bold: true));
      for (final item in invoice.orderedItems) {
        final line = '${item.name} x${item.quantity} - ${currencyFormat.format(item.price * item.quantity)}';
        bytes += generator.text(removeVietnameseDiacritics(line));
      }
      bytes += generator.text(
        removeVietnameseDiacritics('Tien mon: ${currencyFormat.format(invoice.totalOrderedItemsCost)}'),
      );
    }

    bytes += generator.text(removeVietnameseDiacritics('Giam gia: ${currencyFormat.format(invoice.discountAmount)}'));
    bytes += generator.text(
      removeVietnameseDiacritics('Tong cong: ${currencyFormat.format(invoice.finalAmount)}'),
      styles: PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    );
    bytes += generator.text(
      removeVietnameseDiacritics('Cam on quy khach!'),
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
