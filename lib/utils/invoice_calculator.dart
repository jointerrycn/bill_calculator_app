// lib/utils/invoice_calculator.dart
import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/models/ordered_item.dart';
import 'package:collection/collection.dart'; // Để sử dụng firstWhereOrNull

class InvoiceCalculator {
  // Phương thức tính toán chi phí bàn bi-a
  static double calculateTableCost(BilliardTable table) {
    if (!table.isOccupied && table.totalPlayedTime.inMinutes == 0) {
      return 0.0; // Bàn trống và chưa chơi phút nào
    }

    Duration actualTimePlayed;
    if (table.isOccupied && table.startTime != null) {
      // Nếu bàn đang bận, tính thời gian từ lúc bắt đầu đến hiện tại
      actualTimePlayed = DateTime.now().difference(table.startTime!);
    } else {
      // Nếu bàn trống, sử dụng tổng thời gian đã lưu
      actualTimePlayed = table.totalPlayedTime;
    }

    if (actualTimePlayed.inMinutes < 0) {
      // Xử lý trường hợp thời gian âm (mặc dù không nên xảy ra với Duration)
      return 0.0;
    }

    final double hours = actualTimePlayed.inMinutes / 60.0;
    return hours * table.price;
  }

  // Phương thức tính toán tổng chi phí các món đã gọi
  static double calculateOrderedItemsCost(
      List<OrderedItem> orderedItems, List<MenuItem> availableMenuItems) {
    double total = 0.0;
    for (var orderedItem in orderedItems) {
      final MenuItem? item = availableMenuItems.firstWhereOrNull(
            (menu) => menu.id == orderedItem.itemId,
      );
      if (item != null) {
        total += item.price * orderedItem.quantity;
      } else {
        // Xử lý trường hợp MenuItem không tìm thấy (có thể log lỗi hoặc bỏ qua)
        // print('Warning: Menu item with ID ${orderedItem.itemId} not found.');
      }
    }
    return total;
  }

  // Phương thức tính tổng hóa đơn
  static double calculateTotalBill(BilliardTable table, List<MenuItem> availableMenuItems) {
    final double tableCost = calculateTableCost(table);
    final double itemsCost = calculateOrderedItemsCost(table.orderedItems, availableMenuItems);
    return tableCost + itemsCost;
  }
}