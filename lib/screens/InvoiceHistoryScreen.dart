// lib/screens/invoice_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';
import 'package:bill_calculator_app/models/invoice.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:collection/collection.dart';

// Import PrintService
import 'package:bill_calculator_app/services/print_service.dart'; // Đảm bảo đường dẫn đúng

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  DateTime? _selectedDate; // Ngày được chọn để lọc

  // Hàm chọn ngày từ DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Không cho chọn ngày trong tương lai
      helpText: 'Chọn ngày hóa đơn',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, // Màu chính
              onPrimary: Colors.white, // Màu chữ trên màu chính
              surface: Colors.white, // Màu nền của DatePicker
              onSurface: Colors.black87, // Màu chữ trên nền
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary, // Màu chữ cho nút Cancel/OK
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Hàm xóa một hóa đơn cụ thể
  void _confirmDeleteInvoice(BuildContext context, Invoice invoice, AppDataProvider appDataProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa Hóa Đơn'),
        content: Text('Bạn có chắc chắn muốn xóa hóa đơn của bàn "${invoice.tableName}" vào lúc ${DateFormat('HH:mm dd/MM').format(invoice.billDateTime)} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              appDataProvider.removeInvoice(invoice.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa hóa đơn thành công!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Hàm xóa tất cả hóa đơn
  void _confirmClearAllInvoices(BuildContext context, AppDataProvider appDataProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa Toàn Bộ Lịch Sử'),
        content: const Text('Bạn có chắc chắn muốn xóa TẤT CẢ các hóa đơn đã lưu không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              appDataProvider.clearAllInvoices();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa toàn bộ lịch sử hóa đơn!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa Tất Cả', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BẮT ĐẦU: Các hàm mới cho chức năng IN HÓA ĐƠN
  // =========================================================================

  // Hàm xử lý việc in hóa đơn (trong _InvoiceHistoryScreenState)
  // Hàm này sẽ gọi PrintService
  Future<void> _handlePrintInvoice(BuildContext context, Invoice invoice, AppDataProvider appDataProvider) async {
    // Hiển thị dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => WillPopScope( // Ngăn không cho đóng dialog bằng nút Back
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
                  'Đang tạo hóa đơn...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Gọi PrintService để tạo bytes của PDF
      final pdfBytes = await PrintService.generateInvoicePdfBytes(
        invoice: invoice,
        appDataProvider: appDataProvider,
      );

      // Đóng dialog loading
      Navigator.of(context, rootNavigator: true).pop();

      // Gọi PrintService để hiển thị giao diện in
      await PrintService.printPdf(context, pdfBytes);

      // Hiển thị SnackBar thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hóa đơn đã được gửi đến máy in.')),
      );
    } catch (e) {
      // Đóng dialog loading nếu có lỗi và nó vẫn đang mở
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      // Hiển thị SnackBar lỗi (hoặc AlertDialog chi tiết hơn)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chuẩn bị in hóa đơn: $e')),
      );
      print('Lỗi in: $e'); // In lỗi ra console để debug
    }
  }

  // =========================================================================
  // KẾT THÚC: Các hàm mới cho chức năng IN HÓA ĐƠN
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Hóa Đơn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
        actions: [
          // Nút chọn ngày
          IconButton(
            icon: Icon(_selectedDate == null ? Icons.calendar_today : Icons.event_note),
            onPressed: () => _selectDate(context),
            tooltip: 'Lọc theo ngày',
          ),
          // Nút xóa bộ lọc ngày
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
              },
              tooltip: 'Xóa bộ lọc ngày',
            ),
          // Nút xóa tất cả hóa đơn
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmClearAllInvoices(context, context.read<AppDataProvider>()),
            tooltip: 'Xóa tất cả hóa đơn',
          ),
        ],
      ),
      body: Consumer<AppDataProvider>(
        builder: (context, appDataProvider, child) {
          // Lọc danh sách hóa đơn theo ngày đã chọn
          final List<Invoice> filteredInvoices = appDataProvider.invoices.where((invoice) {
            // Cập nhật logic: Nếu _selectedDate là null, hiển thị TẤT CẢ hóa đơn.
            // Nếu bạn muốn mặc định là "hôm nay", hãy thay đổi lại logic này.
            if (_selectedDate == null) {
              return true; // Hiển thị TẤT CẢ hóa đơn khi không có bộ lọc ngày
            }
            // So sánh chỉ ngày, tháng, năm
            return invoice.billDateTime.year == _selectedDate!.year &&
                invoice.billDateTime.month == _selectedDate!.month &&
                invoice.billDateTime.day == _selectedDate!.day;
          }).toList();

          if (filteredInvoices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _selectedDate == null
                      ? 'Chưa có hóa đơn nào được lưu.' // Nếu không có bộ lọc ngày và danh sách trống
                      : 'Không có hóa đơn nào vào ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredInvoices.length,
            itemBuilder: (context, index) {
              final invoice = filteredInvoices[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: ListTile(
                  title: Text(
                    'Bàn: ${invoice.tableName} - ${DateFormat('HH:mm dd/MM/yyyy').format(invoice.billDateTime)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thời gian chơi: ${invoice.playedDuration.inHours}h ${invoice.playedDuration.inMinutes % 60}m'),
                      Text('Tổng cộng: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(invoice.finalAmount)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút xóa hóa đơn
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteInvoice(context, invoice, appDataProvider),
                        tooltip: 'Xóa hóa đơn',
                      ),
                      // Nút xem chi tiết (hoặc chuyển đến màn hình chi tiết)
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.blue), // Thay đổi icon để rõ hơn
                        onPressed: () {
                          _showInvoiceDetailsDialog(context, invoice, appDataProvider);
                        },
                        tooltip: 'Xem chi tiết',
                      ),
                    ],
                  ),
                  onTap: () {
                    // Bạn có thể giữ onTap để click vào ListTile cũng mở dialog
                    _showInvoiceDetailsDialog(context, invoice, appDataProvider);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Dialog hiển thị chi tiết hóa đơn (ĐÃ CẬP NHẬT để thêm nút in)
  void _showInvoiceDetailsDialog(
      BuildContext context, Invoice invoice, AppDataProvider appDataProvider) {
    final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Chi tiết hóa đơn - Bàn ${invoice.tableName}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Thời gian hóa đơn: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(invoice.billDateTime)}'),
                const SizedBox(height: 8),
                Text('Bắt đầu: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(invoice.startTime)}'),
                Text('Kết thúc: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(invoice.endTime)}'),
                Text('Thời gian chơi: ${invoice.playedDuration.inHours}h ${invoice.playedDuration.inMinutes % 60}m'),
                Text('Giá giờ: ${currencyFormat.format(invoice.hourlyRateAtTimeOfBill)}/giờ'),
                Text('Tiền giờ: ${currencyFormat.format(invoice.totalTableCost)}'),
                const Divider(),
                const Text('Món đã gọi:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (invoice.orderedItems.isEmpty)
                  const Text('Không có món ăn nào.'),
                ...invoice.orderedItems.map((orderedItem) {
                  final MenuItem? menuItem = appDataProvider.menuItems
                      .firstWhereOrNull((item) => item.id == orderedItem.itemId);
                  return Text(
                    '- ${menuItem?.name ?? 'Món không rõ'} x${orderedItem.quantity} (${currencyFormat.format(menuItem?.price ?? 0)})',
                  );
                }).toList(),
                Text('Tổng tiền đồ ăn: ${currencyFormat.format(invoice.totalOrderedItemsCost)}'),
                const Divider(),
                Text('Giảm giá: ${currencyFormat.format(invoice.discountAmount)}', style: const TextStyle(color: Colors.red)),
                Text(
                  'Tổng cộng: ${currencyFormat.format(invoice.totalTableCost+invoice.totalOrderedItemsCost-invoice.discountAmount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                ),
              ],
            ),
          ),
          actions: [
            // NÚT IN HÓA ĐƠN MỚI
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop(); // Đóng dialog chi tiết hóa đơn
                _handlePrintInvoice(context, invoice, appDataProvider); // Gọi hàm xử lý in
              },
              icon: const Icon(Icons.print, color: Colors.white),
              label: const Text('In HĐ', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Màu nổi bật
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}