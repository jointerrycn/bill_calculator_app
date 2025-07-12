import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../models/invoice.dart';
import '../providers/app_data_provider.dart';
import '../services/ThermalPrinterService.dart'; // Make sure this path is correct

// Hàm tiện ích để loại bỏ dấu tiếng Việt (nếu cần hiển thị không dấu trên preview)
// Bạn có thể đặt nó ở một file utils/string_utils.dart
String removeVietnameseDiacritics(String str) {
  const withDiacritics =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễ'
      'ìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẠẺẼÊỀẾỆỂỄ'
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


class ReceiptPreview extends StatelessWidget {
  final Invoice invoice;
  final AppDataProvider appDataProvider;
  final double fontSize; // Có thể tùy chỉnh kích thước font cho xem trước

  const ReceiptPreview({
    Key? key,
    required this.invoice,
    required this.appDataProvider,
    this.fontSize = 12.0, // Kích thước font mặc định
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    final String shopName = appDataProvider.shopName;
    final String shopAddress = appDataProvider.shopAddress;
    final String shopPhone = appDataProvider.shopPhone;

    final String startTimeStr = DateFormat('HH:mm:ss').format(invoice.startTime);
    final String endTimeStr = DateFormat('HH:mm:ss').format(invoice.endTime);
    final String playedTimeString = '${invoice.playedDuration.inHours} giờ ${invoice.playedDuration.inMinutes % 60} phút';
    double pagewidth=300; // Mặc định là 300, có thể thay đổi tùy theo khổ giấy
    final  currentPaperSizeKey = appDataProvider.selectedPaperSize;
    debugPrint('Current selectedPaperSize: $currentPaperSizeKey');
    switch (currentPaperSizeKey) {
      case PaperSizeOption.mm58:
        pagewidth = 200;
        break;
      case PaperSizeOption.mm80:
        pagewidth = 300; // Giả định chiều cao A4
        break;
      default:
        pagewidth = 300;
        break;
    }
    return Container(
      // Để mô phỏng giấy in nhiệt, bạn có thể đặt chiều rộng cố định
      // Ví dụ: 200.0 cho giấy 58mm hoặc 300.0 cho giấy 80mm
      width: pagewidth,
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Giới hạn chiều cao theo nội dung
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Thông tin quán ---
          if (shopName.isNotEmpty)
            Center(
              child: Text(
                shopName,
                style: TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          if (shopAddress.isNotEmpty)
            Center(
              child: Text(
                shopAddress,
                style: TextStyle(fontSize: fontSize),
                textAlign: TextAlign.center,
              ),
            ),
          if (shopPhone.isNotEmpty)
            Center(
              child: Text(
                shopPhone,
                style: TextStyle(fontSize: fontSize),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          const Divider(thickness: 1),
          const SizedBox(height: 8),

          // --- Tiêu đề hóa đơn và thông tin bàn ---
          Center(
            child: Text(
              'HÓA ĐƠN THANH TOÁN',
              style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Bàn: ${invoice.tableName}',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
          Text(
            'Ngày in: ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.billDateTime)}',
            style: TextStyle(fontSize: fontSize),
          ),
          const SizedBox(height: 10),

          // --- Thời gian bắt đầu, kết thúc, đã chơi ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bắt đầu:', style: TextStyle(fontSize: fontSize)),
              Text(startTimeStr, style: TextStyle(fontSize: fontSize)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kết thúc:', style: TextStyle(fontSize: fontSize)),
              Text(endTimeStr, style: TextStyle(fontSize: fontSize)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thời gian đã chơi:', style: TextStyle(fontSize: fontSize)),
              Text(playedTimeString, style: TextStyle(fontSize: fontSize)),
            ],
          ),
          const SizedBox(height: 10),

          // --- Chi tiết tiền giờ ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá giờ:', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
              Text('${currencyFormat.format(invoice.hourlyRateAtTimeOfBill)}/giờ', style: TextStyle(fontSize: fontSize)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng tiền giờ:', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
              Text(currencyFormat.format(invoice.totalTableCost), style: TextStyle(fontSize: fontSize)),
            ],
          ),
          const SizedBox(height: 10),

          // --- Chi tiết đồ ăn/uống ---
          Text('Chi tiết đồ ăn/uống:', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          if (invoice.orderedItems.isEmpty)
            Text('Không có món nào được gọi.', style: TextStyle(fontSize: fontSize))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(flex: 4, child: Text('Tên món', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('SL', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Đơn giá', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('T.tiền', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
                const Divider(height: 5, thickness: 0.5),
                ...invoice.orderedItems.map((orderedItem) {
                  final menuItem = appDataProvider.menuItems.firstWhereOrNull((item) => item.id == orderedItem.itemId);
                  final String itemName = menuItem?.name ?? 'Không rõ';
                  final double itemPrice = menuItem?.price ?? 0;
                  final double itemTotal = itemPrice * orderedItem.quantity;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text(itemName, style: TextStyle(fontSize: fontSize))),
                        Expanded(flex: 1, child: Text('x${orderedItem.quantity}', style: TextStyle(fontSize: fontSize), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(currencyFormat.format(itemPrice), style: TextStyle(fontSize: fontSize), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text(currencyFormat.format(itemTotal), style: TextStyle(fontSize: fontSize), textAlign: TextAlign.right)),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 5, thickness: 0.5),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng tiền món ăn:', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                    Text(currencyFormat.format(invoice.totalOrderedItemsCost), style: TextStyle(fontSize: fontSize)),
                  ],
                ),
              ],
            ),
          const Divider(),

          // --- Tổng kết hóa đơn ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng ban đầu:', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
              Text(currencyFormat.format(invoice.totalTableCost + invoice.totalOrderedItemsCost), style: TextStyle(fontSize: fontSize)),
            ],
          ),
          if (invoice.discountAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giảm giá:', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                Text('-${currencyFormat.format(invoice.discountAmount)}', style: TextStyle(fontSize: fontSize)),
              ],
            ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TỔNG CỘNG:', style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold)),
              Text(
                currencyFormat.format(invoice.finalAmount),
                style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(child: Text('Cảm ơn quý khách và hẹn gặp lại!', style: TextStyle(fontSize: fontSize + 1, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20), // Khoảng trống cuối cùng
        ],
      ),
    );
  }
}