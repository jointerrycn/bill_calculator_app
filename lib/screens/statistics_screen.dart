// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Để dùng .firstWhereOrNull
import 'package:fl_chart/fl_chart.dart'; // Để tạo biểu đồ
import 'package:provider/provider.dart'; // Import provider
import 'package:month_year_picker/month_year_picker.dart'; // Thêm dependency này

// Import các models (Đảm bảo đường dẫn đúng với project của bạn)
import 'package:bill_calculator_app/models/ordered_item.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/models/transaction.dart';

// Import provider chính (Đảm bảo đường dẫn đúng với project của bạn)
import 'package:bill_calculator_app/providers/app_data_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Biến để quản lý phạm vi thời gian hiển thị thống kê
  // Mặc định là 'Ngày' khi khởi tạo
  String _selectedTimeRange = 'Ngày';
  DateTime? _selectedDate; // Dùng cho lọc theo ngày
  DateTime? _selectedWeekStart; // Dùng cho lọc theo tuần (luôn là Thứ Hai)
  DateTime? _selectedMonth; // Dùng cho lọc theo tháng (luôn là ngày 1 của tháng)

  @override
  void initState() {
    super.initState();
    // Đặt mặc định khi khởi tạo là ngày hôm nay
    _selectedTimeRange = 'Ngày';
    _selectedDate = DateTime.now(); // Mặc định là ngày hôm nay
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _selectedWeekStart = _getStartOfWeek(DateTime.now());
  }

  // Hàm tiện ích để lấy ngày bắt đầu của tuần (Thứ Hai)
  DateTime _getStartOfWeek(DateTime date) {
    // Dart's weekday starts from 1 (Monday) to 7 (Sunday).
    // So, date.weekday - 1 gives days to subtract to get to Monday.
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // Hàm tạo tiêu đề động cho phần tổng doanh thu
  String _getTotalRevenueTitle() {
    switch (_selectedTimeRange) {
      case 'Ngày':
        if (_selectedDate == null) return 'Doanh thu Ngày:';
        // Kiểm tra nếu là ngày hôm nay
        if (_selectedDate!.year == DateTime.now().year &&
            _selectedDate!.month == DateTime.now().month &&
            _selectedDate!.day == DateTime.now().day) {
          return 'Doanh thu Ngày hôm nay:';
        }
        return 'Doanh thu Ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}:';
      case 'Tuần':
        if (_selectedWeekStart == null) return 'Doanh thu Tuần:';
        final weekEnd = _selectedWeekStart!.add(const Duration(days: 6));
        return 'Doanh thu Tuần (${DateFormat('dd/MM').format(_selectedWeekStart!)} - ${DateFormat('dd/MM').format(weekEnd)}):';
      case 'Tháng':
        if (_selectedMonth == null) return 'Doanh thu Tháng:';
        return 'Doanh thu Tháng ${DateFormat('MM/yyyy').format(_selectedMonth!)}:';
      default:
      // Trường hợp mặc định, không nên xảy ra nếu không có lựa chọn "Tổng"
        return 'Tổng doanh thu:';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appDataProvider = context.watch<AppDataProvider>();
    final List<Transaction> allTransactions = appDataProvider.transactions;
    final List<MenuItem> allMenuItems = appDataProvider.menuItems;

    // Lọc giao dịch dựa trên phạm vi thời gian đã chọn
    List<Transaction> filteredTransactions = _filterTransactions(allTransactions);

    // Tính tổng doanh thu dựa trên các giao dịch đã lọc
    final double totalRevenue = _calculateTotalRevenue(filteredTransactions);
    final Map<String, int> topMenuItems = _getTopMenuItems(filteredTransactions, allMenuItems);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề chính của màn hình
                    const Text(
                      'Thống kê Doanh thu',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Lựa chọn phạm vi thời gian (Ngày, Tuần, Tháng)
                    _buildTimeRangeSelection(context),
                    const SizedBox(height: 16),

                    // Hiển thị tổng doanh thu của phạm vi đã chọn
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tiêu đề động cho tổng doanh thu
                            Text(
                              _getTotalRevenueTitle(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            // Hiển thị tổng doanh thu đã format
                            Text(
                              NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalRevenue),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Biểu đồ doanh thu theo ngày/tháng/tuần
                    const Text(
                      'Biểu đồ doanh thu:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          // Gọi hàm dựng biểu đồ Bar Chart
                          child: _buildBarChart(filteredTransactions, _selectedTimeRange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thống kê món ăn bán chạy nhất
                    const Text(
                      'Món ăn bán chạy:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: topMenuItems.isEmpty
                              ? const Center(child: Text('Chưa có món ăn nào được bán trong khoảng thời gian này.'))
                              : ListView.builder(
                            itemCount: topMenuItems.length,
                            itemBuilder: (context, index) {
                              final entry = topMenuItems.entries.elementAt(index);
                              // Tìm tên món ăn từ ID
                              final MenuItem? menuItem = allMenuItems.firstWhereOrNull((item) => item.id == entry.key);
                              final String itemName = menuItem?.name ?? 'Món không rõ (${entry.key})';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${index + 1}. $itemName',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      '${entry.value} lượt',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Widget để chọn phạm vi thời gian ---
  Widget _buildTimeRangeSelection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Chip "Ngày"
        ChoiceChip(
          label: Text(
            // Hiển thị ngày đã chọn hoặc chữ "Ngày"
            _selectedDate == null || _selectedTimeRange != 'Ngày'
                ? 'Ngày'
                : DateFormat('dd/MM').format(_selectedDate!),
          ),
          selected: _selectedTimeRange == 'Ngày',
          onSelected: (selected) async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020), // Ngày bắt đầu cho DatePicker
              lastDate: DateTime.now(), // Ngày kết thúc cho DatePicker
            );
            if (picked != null) {
              setState(() {
                _selectedTimeRange = 'Ngày';
                _selectedDate = picked;
                _selectedWeekStart = null;
                _selectedMonth = null;
              });
            }
          },
        ),
        // Chip "Tuần"
        ChoiceChip(
          label: Text(
            // Hiển thị tuần đã chọn hoặc chữ "Tuần"
            _selectedWeekStart == null || _selectedTimeRange != 'Tuần'
                ? 'Tuần'
                : 'Tuần ${DateFormat('dd/MM').format(_selectedWeekStart!)}',
          ),
          selected: _selectedTimeRange == 'Tuần',
          onSelected: (selected) async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedWeekStart ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              DateTime weekStart = _getStartOfWeek(picked); // Luôn lấy ngày đầu tuần
              setState(() {
                _selectedTimeRange = 'Tuần';
                _selectedWeekStart = weekStart;
                _selectedDate = null;
                _selectedMonth = null;
              });
            }
          },
        ),
        // Chip "Tháng" (đã sửa lỗi)
        ChoiceChip(
          label: Text(
            // Hiển thị tháng đã chọn hoặc chữ "Tháng"
            _selectedMonth == null || _selectedTimeRange != 'Tháng'
                ? 'Tháng'
                : DateFormat('MM/yyyy').format(_selectedMonth!),
          ),
          selected: _selectedTimeRange == 'Tháng',
          onSelected: (selected) async {
            final DateTime now = DateTime.now();
            // Tính toán ngày cuối cùng của tháng hiện tại để làm giới hạn trên cho bộ chọn
            // DateTime(year, month + 1, 0) sẽ cho ngày cuối cùng của tháng trước đó
            final DateTime lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0);

            final DateTime? picked = await showMonthYearPicker(
              context: context,
              initialDate: _selectedMonth ?? now, // Đảm bảo initialDate không null
              firstDate: DateTime(2020, 1, 1), // Đặt firstDate rõ ràng (vd: đầu năm 2020)
              lastDate: lastDayOfCurrentMonth, // Đặt lastDate là ngày cuối cùng của tháng hiện tại
              locale: const Locale('vi'), // Quan trọng: Đặt locale cho tiếng Việt
            );
            if (picked != null) {
              setState(() {
                _selectedTimeRange = 'Tháng';
                _selectedMonth = DateTime(picked.year, picked.month, 1); // Luôn lấy ngày 1 của tháng đã chọn
                _selectedDate = null;
                _selectedWeekStart = null;
              });
            }
          },
        ),
      ],
    );
  }

  // --- Hàm lọc giao dịch dựa trên phạm vi thời gian đã chọn ---
  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    if (_selectedTimeRange == 'Ngày' && _selectedDate != null) {
      return transactions.where((t) {
        return t.transactionTime.year == _selectedDate!.year &&
            t.transactionTime.month == _selectedDate!.month &&
            t.transactionTime.day == _selectedDate!.day;
      }).toList();
    } else if (_selectedTimeRange == 'Tuần' && _selectedWeekStart != null) {
      final weekEnd = _selectedWeekStart!.add(const Duration(days: 6));
      return transactions.where((t) {
        // Kiểm tra xem transactionTime có nằm trong khoảng từ _selectedWeekStart đến weekEnd không
        return (t.transactionTime.isAfter(_selectedWeekStart!) || t.transactionTime.isAtSameMomentAs(_selectedWeekStart!)) &&
            (t.transactionTime.isBefore(weekEnd) || t.transactionTime.isAtSameMomentAs(weekEnd));
      }).toList();
    } else if (_selectedTimeRange == 'Tháng' && _selectedMonth != null) {
      return transactions.where((t) {
        return t.transactionTime.year == _selectedMonth!.year &&
            t.transactionTime.month == _selectedMonth!.month;
      }).toList();
    }
    return []; // Trả về danh sách rỗng nếu không có lựa chọn phù hợp
  }

  // --- Hàm tính tổng doanh thu ---
  double _calculateTotalRevenue(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, t) => sum + t.finalBillAmount);
  }

  // --- Hàm lấy các món ăn bán chạy nhất ---
  Map<String, int> _getTopMenuItems(List<Transaction> transactions, List<MenuItem> menuItems) {
    final Map<String, int> itemCounts = {};
    for (var transaction in transactions) {
      for (var orderedItem in transaction.orderedItems) {
        itemCounts.update(orderedItem.itemId, (value) => value + orderedItem.quantity,
            ifAbsent: () => orderedItem.quantity);
      }
    }

    // Sắp xếp các món ăn theo số lượng giảm dần
    final sortedEntries = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Lấy top 5 món (hoặc ít hơn nếu không đủ)
    final Map<String, int> top5 = {};
    for (int i = 0; i < sortedEntries.length && i < 5; i++) {
      top5[sortedEntries[i].key] = sortedEntries[i].value;
    }
    return top5;
  }

  // --- Biểu đồ Bar Chart ---
  Widget _buildBarChart(List<Transaction> transactions, String timeRange) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Không có dữ liệu giao dịch để vẽ biểu đồ.'));
    }

    Map<String, double> dataPoints = {}; // Lưu trữ doanh thu cho mỗi khoảng thời gian
    List<String> labels = []; // Nhãn cho trục X

    // Khởi tạo các điểm dữ liệu và nhãn dựa trên phạm vi thời gian đã chọn
    if (timeRange == 'Ngày') {
      final effectiveDate = _selectedDate!; // Chắc chắn không null vì đã mặc định
      // Hiển thị 7 ngày, bắt đầu từ 6 ngày trước ngày đã chọn
      for (int i = 6; i >= 0; i--) {
        final date = effectiveDate.subtract(Duration(days: i));
        final key = DateFormat('dd/MM').format(date);
        dataPoints[key] = 0.0;
        labels.add(key); // Thêm vào labels theo thứ tự thời gian
      }
    } else if (timeRange == 'Tuần') {
      final effectiveWeekStart = _selectedWeekStart!; // Chắc chắn không null
      // Hiển thị 4 tuần, bắt đầu từ 3 tuần trước tuần đã chọn
      for (int i = 3; i >= 0; i--) {
        final weekStart = effectiveWeekStart.subtract(Duration(days: i * 7));
        final key = DateFormat('dd/MM').format(weekStart); // Nhãn: ngày bắt đầu tuần
        dataPoints[key] = 0.0;
        labels.add(key);
      }
    } else if (timeRange == 'Tháng') {
      final effectiveMonth = _selectedMonth!; // Chắc chắn không null
      // Hiển thị 6 tháng, bắt đầu từ 5 tháng trước tháng đã chọn
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(effectiveMonth.year, effectiveMonth.month - i, 1);
        final key = DateFormat('MM/yyyy').format(month);
        dataPoints[key] = 0.0;
        labels.add(key);
      }
    }

    // Điền dữ liệu doanh thu vào dataPoints từ các giao dịch đã lọc
    for (var t in transactions) {
      String key;
      if (timeRange == 'Ngày') {
        key = DateFormat('dd/MM').format(t.transactionTime);
      } else if (timeRange == 'Tuần') {
        DateTime transactionWeekStart = _getStartOfWeek(t.transactionTime);
        key = DateFormat('dd/MM').format(transactionWeekStart);
      } else if (timeRange == 'Tháng') {
        key = DateFormat('MM/yyyy').format(t.transactionTime);
      } else {
        continue;
      }
      dataPoints[key] = (dataPoints[key] ?? 0) + t.finalBillAmount;
    }

    List<BarChartGroupData> barGroups = [];
    // labels đã được sắp xếp khi khởi tạo theo thứ tự thời gian

    for (int i = 0; i < labels.length; i++) {
      final key = labels[i];
      barGroups.add(
        BarChartGroupData(
          x: i, // Index của cột trên trục X
          barRods: [
            BarChartRodData(
              toY: dataPoints[key] ?? 0,
              color: Colors.blueAccent,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    // Tính toán giá trị lớn nhất cho trục Y của biểu đồ
    double maxY = dataPoints.values.isEmpty ? 100000 : dataPoints.values.reduce((a, b) => a > b ? a : b) * 1.2;
    if (maxY == 0 && dataPoints.values.isNotEmpty) { // Nếu có dữ liệu nhưng tất cả là 0
      maxY = 100000;
    } else if (maxY == 0 && dataPoints.values.isEmpty) { // Nếu không có dữ liệu
      maxY = 100000;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Hiển thị giá trị trên trục Y (ví dụ: 1.5M = 1.5 triệu)
                return Text(
                  '${(value / 1000000).toStringAsFixed(1)}M',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false), // Không hiển thị lưới
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1), // Viền biểu đồ
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final String label = labels[group.x];
              final double revenue = rod.toY;
              final int xIndex = group.x.toInt(); // Lấy chỉ số x
              if (xIndex < 0 || xIndex >= labels.length) {
                return null; // Trả về null để không hiển thị tooltip nếu chỉ số không hợp lệ
              }
              return BarTooltipItem(
                '$label\n', // Nhãn thời gian
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(revenue), // Doanh thu
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}