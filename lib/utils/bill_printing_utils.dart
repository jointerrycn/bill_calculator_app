/*
import 'package:flutter/services.dart'; // Cần cho Uint8List
import 'package:pdf/pdf.dart'; // Để định nghĩa kích thước PDF
import 'package:pdf/widgets.dart' as pw; // Để xây dựng các widget PDF
import 'package:printing/printing.dart'; // Để tải font Google Fonts (PdfGoogleFonts)
import 'package:path_provider/path_provider.dart'; // Để lưu file tạm thời
import 'package:share_plus/share_plus.dart'; // Để chia sẻ file PDF
import 'dart:io'; // Để làm việc với File
import 'package:intl/intl.dart'; // Để định dạng tiền tệ và ngày tháng
import 'package:http/http.dart' as http; // Để tải ảnh QR từ URL
import 'package:flutter/foundation.dart' show debugPrint; // Để debug trong Flutter

// Import các model và provider của bạn
import '../models/custom_paper_size.dart';
import '../models/invoice.dart';
import '../providers/app_data_provider.dart'; // Chứa AppDataProvider

/// Generates the PDF bytes for an invoice.
///
/// This function takes an [invoice] object and an [appDataProvider]
/// to gather all necessary data for rendering the invoice in PDF format.
///
/// Returns a [Future<Uint8List>] containing the PDF document bytes.
///
/// **Note:** This utility only generates the PDF content.
/// The actual printing or sharing functionality is handled elsewhere (e.g., ThermalPrinterService).
Future<Uint8List> generateInvoicePdfBytes({
  required Invoice invoice, // Đối tượng hóa đơn chứa chi tiết
  required AppDataProvider appDataProvider, // Provider chứa thông tin cửa hàng, giá giờ, QR code, kích thước giấy
}) async {
  final pdf = pw.Document();

  // Lấy thông tin cần thiết từ AppDataProvider
  final ShopInfo shopInfo = appDataProvider.shopInfo;
  final double hourlyRate = appDataProvider.hourlyRate;
  final String qrImageUrl = appDataProvider.qrImageUrl;
  final CustomPaperSize selectedPaperSize = appDataProvider.customPaperSizes.firstWhere(
        (element) => element.name == appDataProvider.selectedPaperSize,
    orElse: () => CustomPaperSize(name: 'roll80', widthPoints: 226.77, heightPoints: 800.0), // Kích thước giấy mặc định nếu không tìm thấy
  );

  // Định dạng trang PDF
  // Giả định một kích thước giấy cuộn nhỏ cho hóa đơn
  // Chiều cao có thể động tùy thuộc vào nội dung
  final pageFormat = PdfPageFormat(
    selectedPaperSize.widthPoints, // Ví dụ: 80mm = 226.77 points
    selectedPaperSize.heightPoints, // Chiều cao có thể lớn để phù hợp với nội dung dài
    margin: const PdfEdgeInsets.all(20), // Đặt lề cho trang
  );

  // Tải font (đảm bảo font NotoSansThaiBold đã được thêm vào pubspec.yaml và assets)
  // Font này hỗ trợ tiếng Việt
  final font = await PdfGoogleFonts.notoSansThaiBold();

  // Tải ảnh QR Code nếu có URL
  pw.MemoryImage? qrCodeImage;
  if (qrImageUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(qrImageUrl));
      if (response.statusCode == 200) {
        qrCodeImage = pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Error loading QR image for PDF: $e');
      // Có thể thêm logic xử lý lỗi UI tại đây nếu cần
    }
  }

  // Thêm trang vào tài liệu PDF
  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Phần thông tin cửa hàng và tiêu đề hóa đơn
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(shopInfo.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: font)),
                  pw.Text(shopInfo.address, style: pw.TextStyle(fontSize: 12, font: font)),
                  pw.Text('SĐT: ${shopInfo.phone}', style: pw.TextStyle(fontSize: 12, font: font)),
                  pw.SizedBox(height: 10),
                  pw.Text('HÓA ĐƠN THANH TOÁN', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font)),
                  pw.Text('Mã HĐ: ${invoice.id}', style: pw.TextStyle(fontSize: 12, font: font)),
                  pw.Text('Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 12, font: font)),
                  pw.Divider(),
                ],
              ),
            ),
            // Thông tin thời gian thuê/sử dụng
            pw.Text('Thời gian vào: ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.startTime)}', style: pw.TextStyle(font: font)),
            pw.Text('Thời gian ra: ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.endTime)}', style: pw.TextStyle(font: font)),
            pw.Text('Tổng thời gian: ${invoice.hourlyRateAtTimeOfBill.toStringAsFixed(2)} giờ', style: pw.TextStyle(font: font)),
            pw.Text('Giá mỗi giờ: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(hourlyRate)}', style: pw.TextStyle(font: font)),
            pw.Divider(),

            // Bảng chi tiết mặt hàng/dịch vụ
            pw.Text('Chi tiết:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
            pw.Table.fromTextArray(
              headers: ['Mục', 'Số lượng', 'Đơn giá', 'Thành tiền'],
              data: invoice.id.map((item) => [
                item.name,
                item.quantity.toString(),
                NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(item.price),
                NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(item.total),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
              cellStyle: pw.TextStyle(font: font),
              border: null, // Không có viền bảng
              columnWidths: { // Tùy chỉnh độ rộng cột
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2.5),
              },
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),

            // Tóm tắt thanh toán
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tổng cộng:', style: pw.TextStyle(font: font)),
                pw.Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(invoice.totalAmount), style: pw.TextStyle(font: font)),
              ],
            ),
            if (invoice.discountAmount > 0) // Hiển thị giảm giá nếu có
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Giảm giá:', style: pw.TextStyle(font: font)),
                  pw.Text('${invoice.discountAmount.toStringAsFixed(0)}%', style: pw.TextStyle(font: font)),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Thành tiền:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                pw.Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(invoice.finalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tiền khách đưa:', style: pw.TextStyle(font: font)),
                pw.Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(invoice.discountAmount), style: pw.TextStyle(font: font)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tiền thừa:', style: pw.TextStyle(font: font)),
                pw.Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(invoice.discountAmount), style: pw.TextStyle(font: font)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Phương thức:', style: pw.TextStyle(font: font)),
                pw.Text(invoice.paymentMethod, style: pw.TextStyle(font: font)),
              ],
            ),
            if (invoice.note.isNotEmpty) pw.Text('Ghi chú: ${invoice.note}', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 20),

            // Thông tin chuyển khoản và QR Code
            if (shopInfo.bankName.isNotEmpty) ...[
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Chuyển khoản:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                    pw.Text('${shopInfo.bankName}: ${shopInfo.bankAccountNumber}', style: pw.TextStyle(font: font)),
                    pw.Text('Chủ TK: ${shopInfo.bankAccountHolder}', style: pw.TextStyle(font: font)),
                    if (qrCodeImage != null) ...[
                      pw.SizedBox(height: 10),
                      pw.Image(qrCodeImage, width: 100, height: 100),
                      pw.Text('Quét mã QR để thanh toán', style: pw.TextStyle(fontSize: 10, font: font)),
                    ],
                    pw.SizedBox(height: 10),
                  ],
                ),
              ),
            ],
            pw.Spacer(), // Đẩy nội dung sau lên trên cùng của trang

            // Lời cảm ơn
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Cảm ơn quý khách và hẹn gặp lại!', style: pw.TextStyle(fontSize: 12, font: font)),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
  return pdf.save(); // Trả về bytes của tài liệu PDF
}

/// Prints the PDF invoice directly using the system's print dialog.
///
/// This function generates the PDF bytes for the given [invoice] and
/// then presents the system's print dialog to the user.
///
/// **Moved here for convenience, but ideally called from ThermalPrinterService's printInvoice.**
Future<void> printPdfBill({
  required Invoice invoice,
  required AppDataProvider appDataProvider,
}) async {
  try {
    // Tạo bytes PDF từ hóa đơn và thông tin appDataProvider
    final Uint8List pdfBytes = await generateInvoicePdfBytes(
      invoice: invoice,
      appDataProvider: appDataProvider,
    );
    // Sử dụng gói 'printing' để mở hộp thoại in của hệ thống
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'HoaDon_${invoice.id.replaceAll('/', '_')}.pdf', // Tên file hiển thị trong hộp thoại in
    );
    debugPrint('Successfully opened system print dialog for PDF.');
  } catch (e) {
    debugPrint('Error printing PDF bill: $e');
    throw Exception('Lỗi khi in PDF: ${e.toString()}'); // Ném lỗi để caller xử lý
  }
}

/// Saves the PDF invoice to a temporary directory and allows sharing it.
///
/// This function generates the PDF bytes, saves them to a temporary file,
/// and then uses the 'share_plus' package to open the system's share sheet.
Future<void> saveAndSharePdfBill({
  required Invoice invoice,
  required AppDataProvider appDataProvider,
}) async {
  try {
    // Tạo bytes PDF từ hóa đơn và thông tin appDataProvider
    final Uint8List pdfBytes = await generateInvoicePdfBytes(
      invoice: invoice,
      appDataProvider: appDataProvider,
    );
    // Lấy thư mục tạm thời để lưu file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/HoaDon_${invoice.id.replaceAll('/', '_')}.pdf');
    // Ghi bytes PDF vào file
    await file.writeAsBytes(pdfBytes);
    // Sử dụng gói 'share_plus' để chia sẻ file
    await Share.shareXFiles([XFile(file.path)], text: 'Hóa đơn thanh toán của bạn:');
    debugPrint('PDF invoice saved and shared successfully.');
  } catch (e) {
    debugPrint('Error saving or sharing PDF bill: $e');
    throw Exception('Lỗi khi lưu hoặc chia sẻ PDF: ${e.toString()}'); // Ném lỗi để caller xử lý
  }
}*/
