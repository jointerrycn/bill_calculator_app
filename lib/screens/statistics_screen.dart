// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Để dùng .firstWhereOrNull
import 'package:fl_chart/fl_chart.dart'; // Để tạo biểu đồ
import 'package:provider/provider.dart'; // Import provider

// Import các models
import 'package:bill_calculator_app/models/billiard_table.dart'; // Có thể không cần trực tiếp ở đây, nhưng giữ lại phòng trường hợp
import 'package:bill_calculator_app/models/ordered_item.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/models/transaction.dart';

// Import provider chính
import 'package:bill_calculator_app/providers/app_data_provider.dart';

class StatisticsScreen extends StatefulWidget {
  // Không còn cần nhận transactions và menuItems qua constructor nữa
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Biến để quản lý phạm vi thời gian hiển thị thống kê
  String _selectedTimeRange = 'Tổng'; // Mặc định là 'Tổng', có thể là 'Ngày', 'Tuần', 'Tháng'
  DateTime? _selectedDate; // Dùng cho lọc theo ngày
  DateTime? _selectedWeekStart; // Dùng cho lọc theo tuần
  DateTime? _selectedMonth; // Dùng cho lọc theo tháng

  @override
  Widget build(BuildContext context) {
    final appDataProvider = context.watch<AppDataProvider>();
    final List<Transaction> allTransactions = appDataProvider.transactions;
    final List<MenuItem> allMenuItems = appDataProvider.menuItems;

    List<Transaction> filteredTransactions = _filterTransactions(allTransactions);

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
                    // Tiêu đề
                    const Text(
                      'Thống kê Doanh thu',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Lựa chọn phạm vi thời gian
                    _buildTimeRangeSelection(context),
                    const SizedBox(height: 16),

                    // Hiển thị tổng doanh thu
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng doanh thu:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalRevenue),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Biểu đồ doanh thu theo ngày/tháng (chỉ hiện khi có đủ dữ liệu)
                    if (_selectedTimeRange != 'Tổng') ...[
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
                            child: _buildBarChart(filteredTransactions, _selectedTimeRange),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Thống kê món ăn bán chạy
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
                                    // Lấy tên món ăn từ ID
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

  // --- Widget chọn phạm vi thời gian ---
  Widget _buildTimeRangeSelection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ChoiceChip(
          label: const Text('Tổng'),
          selected: _selectedTimeRange == 'Tổng',
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedTimeRange = 'Tổng';
                _selectedDate = null;
                _selectedWeekStart = null;
                _selectedMonth = null;
              });
            }
          },
        ),
        ChoiceChip(
          label: const Text('Ngày'),
          selected: _selectedTimeRange == 'Ngày',
          onSelected: (selected) async {
            if (selected) {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedTimeRange = 'Ngày';
                  _selectedDate = picked;
                  _selectedWeekStart = null;
                  _selectedMonth = null;
                });
              }
            }
          },
        ),
        ChoiceChip(
          label: const Text('Tuần'),
          selected: _selectedTimeRange == 'Tuần',
          onSelected: (selected) async {
            if (selected) {
              // Chọn tuần (có thể phức tạp hơn, tạm thời dùng DatePicker cho ngày bắt đầu tuần)
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedWeekStart ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                // Đảm bảo là ngày đầu tuần (thứ 2)
                DateTime weekStart = picked.subtract(Duration(days: picked.weekday - 1));
                setState(() {
                  _selectedTimeRange = 'Tuần';
                  _selectedWeekStart = weekStart;
                  _selectedDate = null;
                  _selectedMonth = null;
                });
              }
            }
          },
        ),
        ChoiceChip(
          label: const Text('Tháng'),
          selected: _selectedTimeRange == 'Tháng',
          onSelected: (selected) async {
            if (selected) {
              // Chọn tháng (ví dụ: dùng showDatePicker và chỉ lấy tháng/năm)
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year, // Bắt đầu ở chế độ chọn năm
              );
              if (picked != null) {
                setState(() {
                  _selectedTimeRange = 'Tháng';
                  _selectedMonth = DateTime(picked.year, picked.month, 1); // Lấy ngày đầu tháng
                  _selectedDate = null;
                  _selectedWeekStart = null;
                });
              }
            }
          },
        ),
      ],
    );
  }

  // --- Hàm lọc giao dịch dựa trên phạm vi thời gian ---
  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    if (_selectedTimeRange == 'Tổng') {
      return transactions;
    } else if (_selectedTimeRange == 'Ngày' && _selectedDate != null) {
      return transactions.where((t) {
        return t.transactionTime.year == _selectedDate!.year &&
            t.transactionTime.month == _selectedDate!.month &&
            t.transactionTime.day == _selectedDate!.day;
      }).toList();
    } else if (_selectedTimeRange == 'Tuần' && _selectedWeekStart != null) {
      final weekEnd = _selectedWeekStart!.add(const Duration(days: 6));
      return transactions.where((t) {
        return t.transactionTime.isAfter(_selectedWeekStart!.subtract(const Duration(days: 1))) &&
            t.transactionTime.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedTimeRange == 'Tháng' && _selectedMonth != null) {
      return transactions.where((t) {
        return t.transactionTime.year == _selectedMonth!.year &&
            t.transactionTime.month == _selectedMonth!.month;
      }).toList();
    }
    return [];
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

    // Lấy top 5 (hoặc ít hơn nếu không đủ)
    final Map<String, int> top5 = {};
    for (int i = 0; i < sortedEntries.length && i < 5; i++) {
      top5[sortedEntries[i].key] = sortedEntries[i].value;
    }
    return top5;
  }

  // --- Biểu đồ Bar Chart (đơn giản, có thể mở rộng) ---
  Widget _buildBarChart(List<Transaction> transactions, String timeRange) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Không có dữ liệu giao dịch để vẽ biểu đồ.'));
    }

    // Nhóm giao dịch theo ngày/tuần/tháng để tính doanh thu
    Map<String, double> dailyRevenue = {};
    String formatPattern;
    if (timeRange == 'Ngày') {
      formatPattern = 'dd/MM';
      // Chỉ vẽ 7 ngày gần nhất hoặc các ngày có trong giao dịch
      final today = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(today.year, today.month, today.day - i);
        dailyRevenue[DateFormat(formatPattern).format(date)] = 0.0;
      }
    } else if (timeRange == 'Tuần') {
      formatPattern = 'dd/MM'; // Hiển thị ngày bắt đầu tuần
      // Lấy các tuần trong tháng đã chọn hoặc 4 tuần gần nhất
      final currentWeekStart = _selectedWeekStart ?? DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      for (int i = 3; i >= 0; i--) {
        final weekStart = currentWeekStart.subtract(Duration(days: i * 7));
        dailyRevenue[DateFormat(formatPattern).format(weekStart)] = 0.0;
      }
    } else if (timeRange == 'Tháng') {
      formatPattern = 'MM/yyyy';
      // Lấy các tháng trong năm đã chọn hoặc 6 tháng gần nhất
      final currentMonth = _selectedMonth ?? DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(currentMonth.year, currentMonth.month - i, 1);
        dailyRevenue[DateFormat(formatPattern).format(month)] = 0.0;
      }
    } else {
      return const Center(child: Text('Chọn phạm vi thời gian (Ngày/Tuần/Tháng) để xem biểu đồ.'));
    }

    for (var t in transactions) {
      String key;
      if (timeRange == 'Ngày') {
        key = DateFormat(formatPattern).format(t.transactionTime);
      } else if (timeRange == 'Tuần') {
        DateTime transactionWeekStart = t.transactionTime.subtract(Duration(days: t.transactionTime.weekday - 1));
        key = DateFormat(formatPattern).format(transactionWeekStart);
      } else if (timeRange == 'Tháng') {
        key = DateFormat(formatPattern).format(t.transactionTime);
      } else {
        continue;
      }
      dailyRevenue[key] = (dailyRevenue[key] ?? 0) + t.finalBillAmount;
    }

    List<BarChartGroupData> barGroups = [];
    List<String> labels = [];
    int xIndex = 0;

    // Sắp xếp các key theo thứ tự thời gian
    final sortedKeys = dailyRevenue.keys.toList();
    if (timeRange == 'Ngày') {
      sortedKeys.sort((a, b) {
        final dateA = DateFormat('dd/MM').parse(a);
        final dateB = DateFormat('dd/MM').parse(b);
        return dateA.compareTo(dateB);
      });
    } else if (timeRange == 'Tuần') {
      sortedKeys.sort((a, b) {
        final dateA = DateFormat('dd/MM').parse(a);
        final dateB = DateFormat('dd/MM').parse(b);
        return dateA.compareTo(dateB);
      });
    } else if (timeRange == 'Tháng') {
      sortedKeys.sort((a, b) {
        final dateA = DateFormat('MM/yyyy').parse(a);
        final dateB = DateFormat('MM/yyyy').parse(b);
        return dateA.compareTo(dateB);
      });
    }


    for (var key in sortedKeys) {
      labels.add(key);
      barGroups.add(
        BarChartGroupData(
          x: xIndex,
          barRods: [
            BarChartRodData(
              toY: dailyRevenue[key] ?? 0,
              color: Colors.blueAccent,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      xIndex++;
    }

    double maxY = dailyRevenue.values.isEmpty ? 100000 : dailyRevenue.values.reduce((a, b) => a > b ? a : b) * 1.2;
    if (maxY == 0) maxY = 100000; // Tránh chia cho 0 nếu không có doanh thu

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
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[value.toInt()],
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
                return Text(
                  '${(value / 1000000).toStringAsFixed(1)}M', // Ví dụ: hiển thị triệu
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
      ),
    );
  }
}