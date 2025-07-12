// lib/services/thermal_printer_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bill_calculator_app/helper/extensions.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart' as ftp;
import 'package:flutter_thermal_printer/utils/printer.dart' as ftp_utils;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:bill_calculator_app/models/invoice.dart';
import 'package:intl/intl.dart';


// Imports cho PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // ✅ Vẫn sử dụng Printer từ gói này cho USB/System
import 'package:bill_calculator_app/models/custom_paper_size.dart';


enum PrintResult { success, error, noDeviceSelected }

enum PaperSizeOption { mm58, mm80 }

enum DefaultPrinterType {
  none,
  bluetooth,
  usb,
  network,
}

class ThermalPrinterService with ChangeNotifier {
  bool _isScanning = false;
  List<ftp_utils.Printer> _scanResults = [];
  ftp_utils.Printer? _selectedPrinter; // Cho Bluetooth/Network (flutter_thermal_printer)
  ftp_utils.Printer? _defaultThermalPrinter; // ✅ Đổi tên biến để rõ ràng hơn

  // ✅ Thêm thuộc tính để lưu cổng mặc định cho máy in mạng (chỉ dùng cho network printer)
  int _defaultNetworkPrinterPort = 9100;

  List<Printer> _availableUsbPrinters = []; // Cho USB/System (printing)
  Printer? _selectedUsbPrinter;
  Printer? _defaultUsbPrinter; // Cho USB/System (printing)

  DefaultPrinterType _defaultPrinterType = DefaultPrinterType.none;

  final ftp.FlutterThermalPrinter _thermalPrinter = ftp.FlutterThermalPrinter.instance;
  StreamSubscription? _scanSubscription;

  bool get isScanning => _isScanning;
  List<ftp_utils.Printer> get scanResults => _scanResults;
  ftp_utils.Printer? get selectedPrinter => _selectedPrinter;
  ftp_utils.Printer? get defaultThermalPrinter => _defaultThermalPrinter; // ✅ Getter mới

  int get defaultNetworkPrinterPort => _defaultNetworkPrinterPort;

  List<Printer> get availableUsbPrinters => _availableUsbPrinters;
  Printer? get selectedUsbPrinter => _selectedUsbPrinter;
  Printer? get defaultUsbPrinter => _defaultUsbPrinter;

  String? get defaultNetworkPrinterIp => _defaultThermalPrinter?.connectionType == ftp_utils.ConnectionType.NETWORK ? _defaultThermalPrinter?.address : null;


  DefaultPrinterType get defaultPrinterType => _defaultPrinterType;

  final AppDataProvider _appDataProvider;

  ThermalPrinterService(this._appDataProvider) {
    _loadDefaultThermalPrinter(); // ✅ Tải máy in nhiệt
    _loadDefaultNetworkPrinterPort(); // ✅ Tải cổng riêng
    _loadDefaultUsbPrinter(); // Tải máy in USB
    _loadDefaultPrinterType();
  }

  // --- Các hàm Load/Save cho Máy in nhiệt (Bluetooth/Network) ---

  Future<void> _loadDefaultThermalPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('default_thermal_printer_address'); // ✅ Key mới
    final name = prefs.getString('default_thermal_printer_name'); // ✅ Key mới
    final typeString = prefs.getString('default_thermal_printer_type_enum'); // ✅ Key mới

    if (address != null && typeString != null) {
      final ftp_utils.ConnectionType? type = _stringToConnectionType(typeString);
      if (type != null) {
        _defaultThermalPrinter = ftp_utils.Printer(
          address: address,
          name: name,
          connectionType: type,
        );
      }
    } else {
      _defaultThermalPrinter = null;
    }
    notifyListeners();
  }

  Future<void> _saveDefaultThermalPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    if (_defaultThermalPrinter != null) {
      await prefs.setString('default_thermal_printer_address', _defaultThermalPrinter!.address ?? '');
      await prefs.setString('default_thermal_printer_name', _defaultThermalPrinter!.name ?? '');
      await prefs.setString('default_thermal_printer_type_enum', _defaultThermalPrinter!.connectionTypeString);
    } else {
      await prefs.remove('default_thermal_printer_address');
      await prefs.remove('default_thermal_printer_name');
      await prefs.remove('default_thermal_printer_type_enum');
    }
  }

  // --- Các hàm Load/Save cho Cổng máy in mạng ---
  // ✅ Các hàm này chỉ liên quan đến cổng của máy in mạng
  Future<void> _loadDefaultNetworkPrinterPort() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultNetworkPrinterPort = prefs.getInt('default_network_printer_port') ?? 9100;
    notifyListeners();
  }

  Future<void> _saveDefaultNetworkPrinterPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    _defaultNetworkPrinterPort = port;
    await prefs.setInt('default_network_printer_port', port);
    notifyListeners();
  }

  ftp_utils.ConnectionType? _stringToConnectionType(String? typeString) {
    if (typeString == null) return null;
    switch (typeString) {
      case 'BLE':
        return ftp_utils.ConnectionType.BLE;
      case 'USB': // "USB" trong ConnectionType của ftp_utils
        return ftp_utils.ConnectionType.USB;
      case 'NETWORK':
        return ftp_utils.ConnectionType.NETWORK;
      default:
        return null;
    }
  }

  // --- Các hàm Load/Save cho Máy in USB/Hệ thống ---
  Future<void> _loadDefaultUsbPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('default_usb_printer_url');
    final name = prefs.getString('default_usb_printer_name');
    if (url != null) {
      _defaultUsbPrinter = Printer(url: url, name: name);
      notifyListeners();
    }
  }

  Future<void> _saveDefaultUsbPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    if (_defaultUsbPrinter != null) {
      await prefs.setString(
        'default_usb_printer_url',
        _defaultUsbPrinter!.url,
      );
      await prefs.setString('default_usb_printer_name', _defaultUsbPrinter!.name ?? '');
    } else {
      await prefs.remove('default_usb_printer_url');
      await prefs.remove('default_usb_printer_name');
    }
  }

  // --- Các hàm Load/Save cho Loại máy in mặc định (tổng thể) ---
  Future<void> _loadDefaultPrinterType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeString = prefs.getString('default_printer_type');
    _defaultPrinterType = DefaultPrinterType.values.firstWhere(
          (e) => e.toString() == typeString,
      orElse: () => DefaultPrinterType.none,
    );
    notifyListeners();
  }

  Future<void> _saveDefaultPrinterType() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_printer_type', _defaultPrinterType.toString());
  }

  // --- Các hàm Set/Select ---

  void selectPrinter(ftp_utils.Printer printer) {
    _selectedPrinter = printer;
    notifyListeners();
  }

  // ✅ Hàm mới: setDefaultThermalPrinter
  Future<void> setDefaultThermalPrinter(ftp_utils.Printer? printer) async {
    _defaultThermalPrinter = printer;
    await _saveDefaultThermalPrinter();
    notifyListeners();
  }

  // ✅ Hàm setDefaultNetworkPrinterPort giữ nguyên
  Future<void> setDefaultNetworkPrinterPort(int port) async {
    await _saveDefaultNetworkPrinterPort(port);
  }

  void selectUsbPrinter(Printer printer) {
    _selectedUsbPrinter = printer;
    notifyListeners();
  }

  Future<void> setDefaultUsbPrinter(Printer? printer) async {
    _defaultUsbPrinter = printer;
    await _saveDefaultUsbPrinter();
    notifyListeners();
  }

  Future<void> setDefaultPrinterType(DefaultPrinterType type) async {
    _defaultPrinterType = type;
    await _saveDefaultPrinterType();

    // ✅ Quan trọng: Khi đổi loại máy in mặc định, hãy xóa máy in cũ của loại khác
    if (type == DefaultPrinterType.bluetooth || type == DefaultPrinterType.network) {
      // Nếu chuyển sang Bluetooth/Network, xóa USB
      await setDefaultUsbPrinter(null);
    } else if (type == DefaultPrinterType.usb) {
      // Nếu chuyển sang USB, xóa Bluetooth/Network
      await setDefaultThermalPrinter(null);
      // ✅ Không xóa cổng máy in mạng ở đây, nó độc lập với việc chọn máy in USB.
      // Chỉ xóa cổng khi máy in mạng mặc định bị gỡ bỏ, điều này được xử lý trong _saveDefaultThermalPrinter.
    } else if (type == DefaultPrinterType.none) {
      // Nếu không chọn gì, xóa tất cả
      await setDefaultThermalPrinter(null);
      await setDefaultUsbPrinter(null);
    }

    notifyListeners();
  }

  Future<void> listAvailableUsbPrinters() async {
    try {
      _availableUsbPrinters = await Printing.listPrinters();
      debugPrint('Found USB/System printers: ${_availableUsbPrinters.map((p) => p.name).join(', ')}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error listing USB/System printers: $e');
      _availableUsbPrinters = [];
      notifyListeners();
    }
  }

  Future<void> startScan({required ftp_utils.ConnectionType scanType}) async {
    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    PermissionStatus bluetoothScanStatus = await Permission.bluetoothScan.request();
    PermissionStatus bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    PermissionStatus locationStatus = await Permission.locationWhenInUse.request();

    if (!bluetoothScanStatus.isGranted || !bluetoothConnectStatus.isGranted || !locationStatus.isGranted) {
      debugPrint('Không có đủ quyền Bluetooth hoặc Location. Vui lòng cấp quyền.');
      _isScanning = false;
      notifyListeners();
      return;
    }

    if (scanType == ftp_utils.ConnectionType.BLE && !Platform.isWindows) {
      bool bluetoothEnabled = await _thermalPrinter.isBleTurnedOn();
      if (!bluetoothEnabled) {
        debugPrint('Bluetooth is off. Please enable it manually.');
        _isScanning = false;
        notifyListeners();
        return;
      }
    }

    try {
      debugPrint('Starting ${scanType.name} discovery...');

      _scanSubscription = _thermalPrinter.devicesStream.listen(
            (List<ftp_utils.Printer> printers) {
          final filteredPrinters = printers.where((p) => p.connectionType == scanType).toList();
          _scanResults.clear();
          _scanResults.addAll(filteredPrinters);
          debugPrint('Found ${filteredPrinters.length} ${scanType.name} printers.');
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Error in discovery stream: $e');
        },
        onDone: () {
          debugPrint('Printer discovery stream finished.');
          _isScanning = false;
          notifyListeners();
        },
      );

      await _thermalPrinter.getPrinters(
        connectionTypes: [scanType],
        refreshDuration: const Duration(seconds: 2),
        androidUsesFineLocation: true,
      );

      Timer(const Duration(seconds: 15), () {
        if (_isScanning) {
          stopScan();
          debugPrint('Printer scan stopped automatically after 15 seconds.');
        }
      });

    } catch (e) {
      debugPrint('Error during printer scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  void stopScan() async {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    await _thermalPrinter.stopScan();
    _isScanning = false;
    notifyListeners();
    debugPrint('Printer scan stopped.');
  }

  Future<void> savePaperSize(PaperSizeOption size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paper_size', size.toString());
  }

  Future<PaperSizeOption> loadPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('paper_size');
    return saved == PaperSizeOption.mm80.toString()
        ? PaperSizeOption.mm80
        : PaperSizeOption.mm58;
  }

  String removeVietnameseDiacritics(String str) {
    const withDiacritics =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễ'
        'ìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẠẺẼÊỀẾỆỂỄ'
        'ÌÍỊỈĨÒÓỌỎÕÔồốộổỗơờớợởỡÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';

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

  // Các hàm generateReceiptFromInvoice và generatePdfInvoice (giữ nguyên)
  Future<List<int>> generateReceiptFromInvoice(Invoice invoice) async {
    final paperSize = await loadPaperSize();
    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(
      paperSize == PaperSizeOption.mm80 ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );

    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );
    List<int> bytes = [];

    final String shopName = _appDataProvider.shopName;
    final String shopAddress = _appDataProvider.shopAddress;
    final String shopPhone = _appDataProvider.shopPhone;

    final String startTimeStr = DateFormat(
      'HH:mm:ss',
    ).format(invoice.startTime);
    final String endTimeStr = DateFormat('HH:mm:ss').format(invoice.endTime);
    final String playedTimeString =
        '${invoice.playedDuration.inHours} giờ ${invoice.playedDuration.inMinutes % 60} phút';

    if (shopName.isNotEmpty) {
      bytes += generator.text(
        removeVietnameseDiacritics(shopName),
        styles: PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2),
      );
    }

    if (shopAddress.isNotEmpty) {
      bytes += generator.text(
        removeVietnameseDiacritics(shopAddress),
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1),
      );
    }

    if (shopPhone.isNotEmpty) {
      bytes += generator.text(
        removeVietnameseDiacritics(shopPhone),
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1),
      );
    }
    bytes += generator.feed(1);
    bytes += generator.hr();
    bytes += generator.feed(1);

    bytes += generator.text(
      removeVietnameseDiacritics('HOA DON THANH TOAN'),
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      removeVietnameseDiacritics('Ban: ${invoice.tableName}'),
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.text(
      removeVietnameseDiacritics(
        'Ngay in: ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.billDateTime)}',
      ),
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(text: removeVietnameseDiacritics('Bat dau:'), width: 6),
      PosColumn(
        text: removeVietnameseDiacritics(startTimeStr),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: removeVietnameseDiacritics('Ket thuc:'), width: 6),
      PosColumn(
        text: removeVietnameseDiacritics(endTimeStr),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: removeVietnameseDiacritics('Thoi gian da choi:'),
        width: 6,
      ),
      PosColumn(
        text: removeVietnameseDiacritics(playedTimeString),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(
        text: removeVietnameseDiacritics('Gia gio:'),
        width: 6,
        styles: PosStyles(bold: true),
      ),
      PosColumn(
        text: removeVietnameseDiacritics(
          '${currencyFormat.format(invoice.hourlyRateAtTimeOfBill)}/gio',
        ),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: removeVietnameseDiacritics('Tong tien gio:'),
        width: 6,
        styles: PosStyles(bold: true),
      ),
      PosColumn(
        text: currencyFormat.format(invoice.totalTableCost),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.feed(1);

    bytes += generator.text(
      removeVietnameseDiacritics('Chi tiet do an/uong:'),
      styles: PosStyles(bold: true),
    );
    bytes += generator.feed(1);

    if (invoice.orderedItems.isEmpty) {
      bytes += generator.text(
        removeVietnameseDiacritics('Khong co mon nao duoc goi.'),
        styles: PosStyles(height: PosTextSize.size1),
      );
    } else {
      bytes += generator.row([
        PosColumn(
          text: removeVietnameseDiacritics('Ten mon'),
          width: 6,
          styles: PosStyles(bold: true),
        ),
        PosColumn(
          text: removeVietnameseDiacritics('SL'),
          width: 2,
          styles: PosStyles(bold: true, align: PosAlign.center),
        ),
        PosColumn(
          text: removeVietnameseDiacritics('D.gia'),
          width: 2,
          styles: PosStyles(bold: true, align: PosAlign.right),
        ),
        PosColumn(
          text: removeVietnameseDiacritics('T.tien'),
          width: 2,
          styles: PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.hr();
      bytes += generator.feed(1);

      for (final item in invoice.orderedItems) {
        final menuItem = _appDataProvider.menuItems.firstWhereOrNull(
              (m) => m.id == item.itemId,
        );
        final String itemName = removeVietnameseDiacritics(menuItem?.name ?? 'Khong ro');
        final double itemPrice = menuItem?.price ?? 0;
        final double itemTotal = itemPrice * item.quantity;

        bytes += generator.row([
          PosColumn(text: itemName, width: 6),
          PosColumn(
            text: 'x${item.quantity}',
            width: 2,
            styles: PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: currencyFormat.format(itemPrice),
            width: 2,
            styles: PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: currencyFormat.format(itemTotal),
            width: 2,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]);
        bytes += generator.feed(1);
      }
      bytes += generator.hr();
      bytes += generator.feed(1);

      bytes += generator.row([
        PosColumn(
          text: removeVietnameseDiacritics('Tong tien mon an:'),
          width: 6,
          styles: PosStyles(bold: true),
        ),
        PosColumn(
          text: currencyFormat.format(invoice.totalOrderedItemsCost),
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.feed(1);
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        text: removeVietnameseDiacritics('Tong ban dau:'),
        width: 6,
        styles: PosStyles(bold: true),
      ),
      PosColumn(
        text: currencyFormat.format(
          invoice.totalTableCost + invoice.totalOrderedItemsCost,
        ),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    if (invoice.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(
          text: removeVietnameseDiacritics('Giam gia:'),
          width: 6,
          styles: PosStyles(bold: true),
        ),
        PosColumn(
          text: currencyFormat.format(invoice.discountAmount),
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.feed(1);
    bytes += generator.row([
      PosColumn(
        text: removeVietnameseDiacritics('TONG CONG:'),
        width: 6,
        styles: PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: currencyFormat.format(invoice.finalAmount),
        width: 6,
        styles: PosStyles(
          bold: true,
          align: PosAlign.right,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]);
    bytes += generator.feed(2);

    bytes += generator.text(
      removeVietnameseDiacritics('Cam on quy khach va hen gap lai!'),
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  Future<Uint8List> generatePdfInvoice(Invoice invoice) async {
    final pdf = pw.Document();
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    final fontData = await rootBundle.load("assets/fonts/Roboto.ttf");
    final ttfFont = pw.Font.ttf(fontData);

    final String shopName = _appDataProvider.shopName;
    final String shopAddress = _appDataProvider.shopAddress;
    final String shopPhone = _appDataProvider.shopPhone;

    final String startTimeStr = DateFormat(
      'HH:mm:ss',
    ).format(invoice.startTime);
    final String endTimeStr = DateFormat('HH:mm:ss').format(invoice.endTime);
    final String playedTimeString =
        '${invoice.playedDuration.inHours} giờ ${invoice.playedDuration.inMinutes % 60} phút';

    PdfPageFormat selectedFormat;
    final String currentPaperSizeKey = _appDataProvider.selectedPaperSize;

    final CustomPaperSize? customSize = _appDataProvider.customPaperSizes.firstWhereOrNull(
          (size) => size.name == currentPaperSizeKey,
    );

    if (customSize != null) {
      selectedFormat = PdfPageFormat(customSize.widthPoints, customSize.heightPoints);
    } else {
      switch (currentPaperSizeKey) {
        case 'a4':
          selectedFormat = PdfPageFormat.a4;
          break;
        case 'a5':
          selectedFormat = PdfPageFormat.a5;
          break;
        case 'letter':
          selectedFormat = PdfPageFormat.letter;
          break;
        case 'roll57':
          selectedFormat = const PdfPageFormat(57 * PdfPageFormat.mm, double.infinity);
          break;
        case 'roll80':
          selectedFormat = const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity);
          break;
        default:
          selectedFormat = PdfPageFormat.a4;
          break;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: selectedFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (shopName.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    removeVietnameseDiacritics(shopName),
                    style: pw.TextStyle(
                      font: ttfFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              if (shopAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    removeVietnameseDiacritics(shopAddress),
                    style: pw.TextStyle(font: ttfFont, fontSize: 10),
                  ),
                ),
              if (shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    removeVietnameseDiacritics(shopPhone),
                    style: pw.TextStyle(font: ttfFont, fontSize: 10),
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Divider(height: 1, thickness: 1),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  removeVietnameseDiacritics('HOA DON THANH TOAN'),
                  style: pw.TextStyle(
                    font: ttfFont,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                removeVietnameseDiacritics('Ban: ${invoice.tableName}'),
                style: pw.TextStyle(
                  font: ttfFont,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                removeVietnameseDiacritics(
                  'Ngay in: ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.billDateTime)}',
                ),
                style: pw.TextStyle(font: ttfFont, fontSize: 12),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(removeVietnameseDiacritics('Bat dau:'), style: pw.TextStyle(font: ttfFont, fontSize: 12)),
                  pw.Text(removeVietnameseDiacritics(startTimeStr), style: pw.TextStyle(font: ttfFont, fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(removeVietnameseDiacritics('Ket thuc:'), style: pw.TextStyle(font: ttfFont, fontSize: 12)),
                  pw.Text(removeVietnameseDiacritics(endTimeStr), style: pw.TextStyle(font: ttfFont, fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(removeVietnameseDiacritics('Thoi gian da choi:'), style: pw.TextStyle(font: ttfFont, fontSize: 12)),
                  pw.Text(removeVietnameseDiacritics(playedTimeString), style: pw.TextStyle(font: ttfFont, fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    removeVietnameseDiacritics('Gia gio:'),
                    style: pw.TextStyle(
                      font: ttfFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    removeVietnameseDiacritics(
                      '${currencyFormat.format(invoice.hourlyRateAtTimeOfBill)}/gio',
                    ),
                    style: pw.TextStyle(font: ttfFont, fontSize: 12),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    removeVietnameseDiacritics('Tong tien gio:'),
                    style: pw.TextStyle(
                      font: ttfFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    removeVietnameseDiacritics(
                      currencyFormat.format(invoice.totalTableCost),
                    ),
                    style: pw.TextStyle(font: ttfFont, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                removeVietnameseDiacritics('Chi tiet do an/uong:'),
                style: pw.TextStyle(
                  font: ttfFont,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              if (invoice.orderedItems.isEmpty)
                pw.Text(
                  removeVietnameseDiacritics('Khong co mon nao duoc goi.'),
                  style: pw.TextStyle(font: ttfFont, fontSize: 10),
                )
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 6,
                          child: pw.Text(
                            removeVietnameseDiacritics('Ten mon'),
                            style: pw.TextStyle(
                                font: ttfFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            removeVietnameseDiacritics('SL'),
                            style: pw.TextStyle(
                                font: ttfFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            removeVietnameseDiacritics('D.gia'),
                            style: pw.TextStyle(
                                font: ttfFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            removeVietnameseDiacritics('T.tien'),
                            style: pw.TextStyle(
                                font: ttfFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.Divider(height: 5, thickness: 0.5),
                    pw.SizedBox(height: 5),
                    ...invoice.orderedItems.map((orderedItem) {
                      final menuItem = _appDataProvider.menuItems.firstWhereOrNull(
                              (item) => item.id == orderedItem.itemId);
                      final String itemName = removeVietnameseDiacritics(menuItem?.name ?? 'Khong ro');
                      final double itemPrice = menuItem?.price ?? 0;
                      final double itemTotal = itemPrice * orderedItem.quantity;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                                flex: 6,
                                child: pw.Text(itemName,
                                    style: pw.TextStyle(font: ttfFont, fontSize: 10))),
                            pw.Expanded(
                                flex: 2,
                                child: pw.Text('x${orderedItem.quantity}',
                                    style: pw.TextStyle(font: ttfFont, fontSize: 10),
                                    textAlign: pw.TextAlign.center)),
                            pw.Expanded(
                                flex: 2,
                                child: pw.Text(currencyFormat.format(itemPrice),
                                    style: pw.TextStyle(font: ttfFont, fontSize: 10),
                                    textAlign: pw.TextAlign.right)),
                            pw.Expanded(
                                flex: 2,
                                child: pw.Text(currencyFormat.format(itemTotal),
                                    style: pw.TextStyle(font: ttfFont, fontSize: 10),
                                    textAlign: pw.TextAlign.right)),
                          ],
                        ),
                      );
                    }).toList(),
                    pw.SizedBox(height: 5),
                    pw.Divider(height: 5, thickness: 0.5),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          removeVietnameseDiacritics('Tong tien mon an:'),
                          style: pw.TextStyle(
                              font: ttfFont,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          removeVietnameseDiacritics(currencyFormat.format(invoice.totalOrderedItemsCost)),
                          style: pw.TextStyle(font: ttfFont, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              pw.SizedBox(height: 10),
              pw.Divider(height: 1, thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    removeVietnameseDiacritics('Tong ban dau:'),
                    style: pw.TextStyle(
                        font: ttfFont,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    removeVietnameseDiacritics(
                      currencyFormat.format(
                        invoice.totalTableCost + invoice.totalOrderedItemsCost,
                      ),
                    ),
                    style: pw.TextStyle(font: ttfFont, fontSize: 12),
                  ),
                ],
              ),
              if (invoice.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      removeVietnameseDiacritics('Giam gia:'),
                      style: pw.TextStyle(
                          font: ttfFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      removeVietnameseDiacritics(
                        '-${currencyFormat.format(invoice.discountAmount)}',
                      ),
                      style: pw.TextStyle(font: ttfFont, fontSize: 12),
                    ),
                  ],
                ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    removeVietnameseDiacritics('TONG CONG:'),
                    style: pw.TextStyle(
                        font: ttfFont,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    removeVietnameseDiacritics(currencyFormat.format(invoice.finalAmount)),
                    style: pw.TextStyle(
                        font: ttfFont,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  removeVietnameseDiacritics('Cam on quy khach va hen gap lai!'),
                  style: pw.TextStyle(
                    font: ttfFont,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }


  Future<PrintResult> printToThermalPrinter(
      List<int> ticketBytes, {
        ftp_utils.Printer? printer,
      }) async {
    final printerToPrint = printer ?? _defaultThermalPrinter; // ✅ Sử dụng _defaultThermalPrinter

    if (printerToPrint == null) {
      debugPrint("Lỗi: Không có máy in nhiệt (Bluetooth/Network) nào được chọn hoặc đặt làm mặc định.");
      return PrintResult.noDeviceSelected;
    }

    try {
      bool isConnected = false;
      // Dù lớp Printer của flutter_thermal_printer không có trường 'port',
      // khi kết nối NetworkPrinter, thư viện này thường sử dụng cổng mặc định (9100).
      // Nếu bạn muốn hỗ trợ cổng tùy chỉnh *thực sự*, bạn cần sửa đổi gói flutter_thermal_printer
      // hoặc sử dụng lớp NetworkPrinter của nó trực tiếp và cung cấp cổng.
      // Hiện tại, _defaultNetworkPrinterPort ở đây chỉ được dùng trong UI và lưu cài đặt của bạn,
      // chứ không trực tiếp ảnh hưởng đến _thermalPrinter.connect().
      isConnected = await _thermalPrinter.connect(printerToPrint);


      if (isConnected) {
        debugPrint("Đã kết nối thành công tới máy in: ${printerToPrint.name ?? printerToPrint.address}. Loại: ${printerToPrint.connectionType?.name}");

        await _thermalPrinter.printData(printerToPrint, ticketBytes);
        debugPrint("Đã gửi dữ liệu in.");
        debugPrint("Không thực hiện ngắt kết nối rõ ràng (thư viện có thể tự quản lý).");
        return PrintResult.success;
      } else {
        debugPrint("Không thể kết nối đến máy in: ${printerToPrint.name ?? printerToPrint.address}.");
        return PrintResult.error;
      }
    } catch (e) {
      debugPrint("Đã xảy ra lỗi khi in đến máy in nhiệt: $e");
      return PrintResult.error;
    }
  }


  Future<PrintResult> printPdfInvoiceDirectly(Invoice invoice) async {
    if (_defaultUsbPrinter == null) {
      debugPrint("Lỗi: Không có máy in USB mặc định nào được chọn.");
      return PrintResult.noDeviceSelected;
    }

    try {
      final pdfBytes = await generatePdfInvoice(invoice);

      final bool printed = await Printing.directPrintPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'HoaDonThanhToan_${invoice.tableName}_${DateFormat('yyyyMMdd_HHmmss').format(invoice.billDateTime)}',
        printer: _defaultUsbPrinter!,
      );

      if (printed) {
        debugPrint("Hóa đơn đã được in trực tiếp đến máy in USB: ${_defaultUsbPrinter!.name}");
        return PrintResult.success;
      } else {
        debugPrint("Không thể in trực tiếp đến máy in USB: ${_defaultUsbPrinter!.name} (có thể do lỗi cấu hình hoặc driver)");
        return PrintResult.error;
      }
    } on Exception catch (e) {
      debugPrint("Lỗi khi in trực tiếp PDF qua USB: $e");
      return PrintResult.error;
    } catch (e) {
      debugPrint("Đã xảy ra lỗi không xác định khi in trực tiếp PDF qua USB: $e");
      return PrintResult.error;
    }
  }

  Future<PrintResult> printInvoice(Invoice invoice) async {
    final thermalBytes = await generateReceiptFromInvoice(invoice);

    switch (_defaultPrinterType) {
      case DefaultPrinterType.bluetooth:
        if (_defaultThermalPrinter?.connectionType == ftp_utils.ConnectionType.BLE) {
          return await printToThermalPrinter(thermalBytes, printer: _defaultThermalPrinter);
        } else {
          debugPrint("Máy in mặc định được chọn là Bluetooth nhưng không đúng loại hoặc chưa cài đặt.");
          return PrintResult.noDeviceSelected;
        }
      case DefaultPrinterType.network:
        if (_defaultThermalPrinter?.connectionType == ftp_utils.ConnectionType.NETWORK) {
          return await printToThermalPrinter(thermalBytes, printer: _defaultThermalPrinter);
        } else {
          debugPrint("Máy in mặc định được chọn là Mạng nhưng không đúng loại hoặc chưa cài đặt.");
          return PrintResult.noDeviceSelected;
        }
      case DefaultPrinterType.usb:
        return await printPdfInvoiceDirectly(invoice);
      case DefaultPrinterType.none:
        debugPrint("Không có loại máy in mặc định nào được chọn.");
        return PrintResult.noDeviceSelected;
    }
  }
}