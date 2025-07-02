// lib/screens/invoice_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';
import 'package:bill_calculator_app/models/invoice.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:collection/collection.dart';

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
            if (_selectedDate == null) {
              _selectedDate = DateTime.now();
              return true; // Không có ngày được chọn, hiển thị tất cả
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
                      ? 'Chưa có hóa đơn nào được lưu.'
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
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteInvoice(context, invoice, appDataProvider),
                        tooltip: 'Xóa hóa đơn',
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () {
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

  // Dialog hiển thị chi tiết hóa đơn (giữ nguyên)
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
                Text('Thời gian: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(invoice.billDateTime)}'),
                const SizedBox(height: 8),
                Text('Thời gian chơi: ${invoice.playedDuration.inHours}h ${invoice.playedDuration.inMinutes % 60}m ${invoice.playedDuration.inSeconds % 60}s'),
                Text('Giá giờ: ${currencyFormat.format(invoice.hourlyRateAtTimeOfBill)}/giờ'),
                Text('Tiền bàn: ${currencyFormat.format(invoice.totalTableCost)}'),
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
                  'Tổng cộng: ${currencyFormat.format(invoice.finalAmount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                ),
              ],
            ),
          ),
          actions: [
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