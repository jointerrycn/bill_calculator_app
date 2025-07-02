// lib/services/print_service.dart

import 'package:pdf/pdf.dart'; // Thư viện chính để tạo PDF
import 'package:pdf/widgets.dart' as pw; // Widget của thư viện PDF
import 'package:printing/printing.dart'; // Thư viện để in PDF
import 'package:intl/intl.dart'; // Để định dạng tiền tệ và ngày giờ
import 'package:flutter/services.dart' show rootBundle; // Để tải font từ assets
import 'package:collection/collection.dart'; // Để sử dụng firstWhereOrNull
import 'package:flutter/material.dart'; // Để dùng showDialog

import '../models/billiard_table.dart';
import '../models/menu_item.dart';
import '../models/ordered_item.dart';
import '../providers/app_data_provider.dart';
import '../models/custom_paper_size.dart'; // Import lớp CustomPaperSize

/// Lớp cung cấp các chức năng để tạo và in hóa đơn PDF.
class PrintService {
  /// Tạo và in một hóa đơn thanh toán.
  ///
  /// Tham số:
  /// - [table]: Đối tượng BilliardTable của bàn cần thanh toán.
  /// - [durationForBilling]: Tổng thời gian chơi của bàn để tính tiền giờ.
  /// - [totalOrderedItemsCost]: Tổng chi phí của các món ăn/đồ uống đã gọi.
  /// - [appDataProvider]: AppDataProvider để truy cập thông tin quán, menuItems và cài đặt giấy.
  /// - [discountAmount]: Số tiền được giảm giá.
  /// - [finalAmount]: Tổng số tiền cuối cùng sau khi đã áp dụng giảm giá.
  static Future<void> generateAndPrintInvoice({
    required BilliardTable table,
    required Duration durationForBilling,
    required double totalOrderedItemsCost,
    required AppDataProvider appDataProvider,
    required double discountAmount,
    required double finalAmount,
    BuildContext? context, // Thêm context để hiển thị dialog mờ
  }) async {
    // Hiển thị màn hình mờ và thông báo nếu có context
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Đang in hóa đơn...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      // 1. Tải Font hỗ trợ tiếng Việt
      // Đảm bảo file 'Roboto-Regular.ttf' có trong thư mục 'assets/fonts/'
      final fontData = await rootBundle.load("assets/fonts/Roboto.ttf");
      final ttfFont = pw.Font.ttf(fontData);

      // 2. Khởi tạo tài liệu PDF
      final pdf = pw.Document();
      final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

      // 3. Tính toán các giá trị cần thiết cho hóa đơn
      debugPrint('durationForBilling: $durationForBilling');
      final playedTimeString = '${durationForBilling.inHours} giờ ${durationForBilling.inMinutes % 60} phút';
      final double hourlyCost = (durationForBilling.inMinutes / 60.0) * table.price;
      final double initialBill = hourlyCost + totalOrderedItemsCost;
      debugPrint('Initial Bill: $initialBill, Hourly Cost: $hourlyCost, Total Ordered Items Cost: $totalOrderedItemsCost');
      // Thời gian bắt đầu và kết thúc
      final String? startTimeStr = table.startTime != null
          ? DateFormat('dd/MM/yyyy HH:mm:ss').format(table.startTime!)
          : '---';
      final String? endTimeStr = table.endTime != null
          ? DateFormat('dd/MM/yyyy HH:mm:ss').format(table.endTime!)
          : DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

      // 4. Xác định định dạng trang PDF dựa trên cài đặt của người dùng
      PdfPageFormat selectedFormat;
      final String currentPaperSizeKey = appDataProvider.selectedPaperSize;

      // Tìm kiếm trong danh sách giấy tùy chỉnh trước
      final CustomPaperSize? customSize = appDataProvider.customPaperSizes.firstWhereOrNull(
        (size) => size.name == currentPaperSizeKey,
      );

      if (customSize != null) {
        // Nếu tìm thấy giấy tùy chỉnh, sử dụng kích thước đó
        selectedFormat = PdfPageFormat(customSize.widthPoints, customSize.heightPoints);
      } else {
        // Nếu không phải giấy tùy chỉnh, sử dụng các khổ giấy chuẩn
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
            selectedFormat = PdfPageFormat.roll57;
            break;
          case 'roll80':
          default:
            selectedFormat = PdfPageFormat.roll80;
            break;
        }
      }

      // 5. Xây dựng nội dung hóa đơn
      pdf.addPage(
        pw.Page(
          pageFormat: selectedFormat,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Thông tin quán (Tên, Địa chỉ)
                pw.Center(
                  child: pw.Text(
                    appDataProvider.shopName,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfFont),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    appDataProvider.shopAddress,
                    style: pw.TextStyle(fontSize: 10, font: ttfFont),
                  ),
                ),
                // Bạn có thể thêm số điện thoại hoặc thông tin khác ở đây nếu muốn
                pw.Center(
                  child: pw.Text(
                    appDataProvider.shopPhone, // Thay thế bằng số điện thoại thật
                    style: pw.TextStyle(fontSize: 10, font: ttfFont),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Tiêu đề hóa đơn và thông tin bàn
                pw.Text(
                  'HÓA ĐƠN THANH TOÁN',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Bàn: ${table.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                pw.Text('Ngày in: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}', style: pw.TextStyle(font: ttfFont)),
                pw.SizedBox(height: 10),

                // Thời gian bắt đầu, kết thúc, đã chơi
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bắt đầu:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                    pw.Text(table.startTime != null ? DateFormat('HH:mm:ss').format(table.startTime!) : '---', style: pw.TextStyle(font: ttfFont)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kết thúc:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                    pw.Text(table.endTime != null ? DateFormat('HH:mm:ss').format(table.endTime!) : DateFormat('HH:mm:ss').format(DateTime.now()) , style: pw.TextStyle(font: ttfFont)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Thời gian đã chơi:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                    pw.Text(playedTimeString, style: pw.TextStyle(font: ttfFont)),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Chi tiết tiền giờ
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Giá giờ:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                    pw.Text('${currencyFormat.format(table.price)}/giờ', style: pw.TextStyle(font: ttfFont)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tổng tiền giờ:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                    pw.Text(currencyFormat.format(hourlyCost), style: pw.TextStyle(font: ttfFont)),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Chi tiết đồ ăn/uống
                pw.Text('Chi tiết đồ ăn/uống:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                pw.SizedBox(height: 5),
                if (table.orderedItems.isEmpty)
                  pw.Text('Không có món nào được gọi.', style: pw.TextStyle(fontSize: 10, font: ttfFont))
                else
                  pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('Tên món', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont))),
                          pw.Text('SL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                          pw.SizedBox(width: 10),
                          pw.Text('Đơn giá', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                          pw.SizedBox(width: 10),
                          pw.Text('Thành tiền', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                        ],
                      ),
                      ...table.orderedItems.map((orderedItem) {
                        final menuItem = appDataProvider.menuItems.firstWhereOrNull((item) => item.id == orderedItem.itemId);
                        final String itemName = menuItem?.name ?? 'Không rõ';
                        final double itemPrice = menuItem?.price ?? 0;
                        final double itemTotal = itemPrice * orderedItem.quantity;
                        return pw.Row(
                          children: [
                            pw.Expanded(child: pw.Text(itemName, style: pw.TextStyle(font: ttfFont))),
                            pw.Text('x${orderedItem.quantity}', style: pw.TextStyle(font: ttfFont)),
                            pw.SizedBox(width: 10),
                            pw.Text(currencyFormat.format(itemPrice), style: pw.TextStyle(font: ttfFont)),
                            pw.SizedBox(width: 10),
                            pw.Text(currencyFormat.format(itemTotal), style: pw.TextStyle(font: ttfFont)),
                          ],
                        );
                      }).toList(),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Tổng tiền món ăn:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                          pw.Text(currencyFormat.format(totalOrderedItemsCost), style: pw.TextStyle(font: ttfFont)),
                        ],
                      ),
                    ],
                  ),
                pw.Divider(),

                // Tổng kết hóa đơn
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tổng ban đầu:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                    pw.Text(currencyFormat.format(initialBill), style: pw.TextStyle(font: ttfFont)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Giảm giá:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfFont)),
                    pw.Text(currencyFormat.format(discountAmount), style: pw.TextStyle(font: ttfFont)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TỔNG CỘNG:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: ttfFont)),
                    pw.Text(currencyFormat.format(finalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: ttfFont)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // 6. Hiển thị hóa đơn để in
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      // Đóng dialog "Đang in hóa đơn..." nếu đang mở
      if (context != null) {
        Navigator.of(context, rootNavigator: true).pop();
        // Hiển thị dialog báo lỗi
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Lỗi in hóa đơn'),
            content: Text('Đã xảy ra lỗi khi in hóa đơn:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } finally {
      // Đóng dialog "Đang in hóa đơn..." nếu vẫn còn mở (tránh lỗi pop nhiều lần)
      if (context != null && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}