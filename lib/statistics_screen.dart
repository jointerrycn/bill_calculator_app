import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Đảm bảo có gói này trong pubspec.yaml
import 'package:fl_chart/fl_chart.dart'; // Đảm bảo có gói này trong pubspec.yaml
import 'main.dart';
import 'models/menu_item.dart';
import 'models/transaction.dart'; // Import Transaction, MenuItem từ main.dart

class StatisticsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<MenuItem> menuItems;

  const StatisticsScreen({
    super.key,
    required this.transactions,
    required this.menuItems,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedFilter = 'Tháng'; // Mặc định hiển thị theo tháng
  DateTime? _selectedDate;
  late DateTime _currentRangeStartDate;
  late DateTime _currentRangeEndDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _updateDateRange();
  }

  // Cập nhật phạm vi ngày hiển thị dựa trên bộ lọc
  void _updateDateRange() {
    DateTime now = DateTime.now();
    DateTime tempStartDate;
    DateTime tempEndDate;

    switch (_selectedFilter) {
      case 'Tất cả':
      // Khi chọn "Tất cả", có thể giới hạn từ năm đầu tiên có giao dịch hoặc một mốc cố định
      // Để tránh tạo quá nhiều cột, chúng ta sẽ tổng hợp theo tháng cho bộ lọc này.
        tempStartDate = DateTime(2023, 1, 1); // Ví dụ: từ đầu năm 2023
        if (widget.transactions.isNotEmpty) {
          // Lấy năm của giao dịch sớm nhất nếu muốn chính xác hơn
          widget.transactions.sort((a, b) => a.transactionTime.compareTo(b.transactionTime));
          tempStartDate = DateTime(widget.transactions.first.transactionTime.year, 1, 1);
        }
        tempEndDate = DateTime(now.year + 1, 1, 1); // Đến đầu năm sau
        break;
      case 'Ngày':
        DateTime dateToFilter = _selectedDate ?? now;
        tempStartDate = DateTime(dateToFilter.year, dateToFilter.month, dateToFilter.day);
        tempEndDate = tempStartDate.add(const Duration(days: 1));
        break;
      case 'Tuần':
      // Tuần bắt đầu từ thứ 2 (weekday 1)
        tempStartDate = now.subtract(Duration(days: now.weekday - 1));
        tempStartDate = DateTime(tempStartDate.year, tempStartDate.month, tempStartDate.day);
        tempEndDate = tempStartDate.add(const Duration(days: 7));
        break;
      case 'Tháng':
        tempStartDate = DateTime(now.year, now.month, 1);
        tempEndDate = DateTime(now.year, now.month + 1, 1);
        break;
      default:
        tempStartDate = DateTime(now.year, now.month, 1); // Mặc định tháng hiện tại
        tempEndDate = DateTime(now.year, now.month + 1, 1);
        break;
    }

    setState(() {
      _currentRangeStartDate = tempStartDate;
      _currentRangeEndDate = tempEndDate;
    });
  }

  // Mở DatePicker để chọn ngày khi bộ lọc là "Ngày"
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedFilter = 'Ngày'; // Chuyển bộ lọc về "Ngày" khi chọn ngày cụ thể
      });
      _updateDateRange();
    }
  }

  // Hàm chuẩn bị dữ liệu cho biểu đồ dựa trên bộ lọc
  List<BarChartGroupData> _getBarChartData(List<Transaction> transactions) {
    Map<DateTime, double> aggregatedRevenue = {};
    Duration aggregationUnit; // Đơn vị tổng hợp (ngày hoặc tháng)

    // Xác định đơn vị tổng hợp và cách lấy key
    if (_selectedFilter == 'Tất cả') {
      // Tổng hợp theo tháng
      aggregationUnit = const Duration(days: 30); // Chỉ mang tính ước lượng để lặp
      for (var transaction in transactions) {
        // Lấy ngày đầu tiên của tháng làm key
        DateTime monthOnly = DateTime(transaction.transactionTime.year, transaction.transactionTime.month, 1);
        aggregatedRevenue.update(monthOnly, (value) => value + transaction.finalBillAmount,
            ifAbsent: () => transaction.finalBillAmount);
      }
    } else {
      // Tổng hợp theo ngày (cho Ngày, Tuần, Tháng)
      aggregationUnit = const Duration(days: 1);
      for (var transaction in transactions) {
        // Lấy ngày không kèm giờ làm key
        DateTime dayOnly = DateTime(transaction.transactionTime.year, transaction.transactionTime.month, transaction.transactionTime.day);
        aggregatedRevenue.update(dayOnly, (value) => value + transaction.finalBillAmount,
            ifAbsent: () => transaction.finalBillAmount);
      }
    }

    List<BarChartGroupData> barGroups = [];
    int xIndex = 0;

    // Lặp qua từng đơn vị thời gian trong phạm vi đã chọn để tạo cột
    DateTime tempIterator = _currentRangeStartDate;
    while (tempIterator.isBefore(_currentRangeEndDate)) {
      double revenue = 0.0;
      DateTime currentUnitKey;

      if (_selectedFilter == 'Tất cả') {
        currentUnitKey = DateTime(tempIterator.year, tempIterator.month, 1);
        revenue = aggregatedRevenue[currentUnitKey] ?? 0.0;
        tempIterator = DateTime(tempIterator.year, tempIterator.month + 1, 1); // Tăng lên tháng tiếp theo
      } else {
        currentUnitKey = DateTime(tempIterator.year, tempIterator.month, tempIterator.day);
        revenue = aggregatedRevenue[currentUnitKey] ?? 0.0;
        tempIterator = tempIterator.add(const Duration(days: 1)); // Tăng lên ngày tiếp theo
      }

      barGroups.add(
        BarChartGroupData(
          x: xIndex,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: Colors.blue,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
      xIndex++;
    }
    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    List<Transaction> filteredTransactions = widget.transactions.where((transaction) {
      final transactionTime = transaction.transactionTime;
      return transactionTime.isAfter(_currentRangeStartDate.subtract(const Duration(microseconds: 1))) &&
          transactionTime.isBefore(_currentRangeEndDate);
    }).toList();

    double totalRevenue = filteredTransactions.fold(0.0, (sum, t) => sum + t.finalBillAmount);
    List<BarChartGroupData> barGroups = _getBarChartData(filteredTransactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê Doanh Thu'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bộ lọc thời gian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedFilter,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                        if (newValue == 'Ngày' && _selectedDate == null) {
                          _selectedDate = DateTime.now();
                        }
                      });
                      _updateDateRange();
                    }
                  },
                  items: <String>['Tất cả', 'Ngày', 'Tuần', 'Tháng']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                if (_selectedFilter == 'Ngày')
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Chọn Ngày'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    ),
                    onPressed: () => _selectDate(context),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Dữ liệu từ: ${_formatFilterRangeString()}',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),

            // Tổng doanh thu
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng Doanh Thu:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(totalRevenue),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Biểu đồ doanh thu
            const Text(
              'Biểu Đồ Doanh Thu:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: filteredTransactions.isEmpty
                  ? const Center(
                child: Text('Không có dữ liệu để hiển thị biểu đồ.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              )
                  : BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          DateTime labelDate;
                          if (_selectedFilter == 'Tất cả') {
                            labelDate = DateTime(_currentRangeStartDate.year,
                                _currentRangeStartDate.month + value.toInt(), 1);
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(DateFormat('MM/yyyy').format(labelDate), style: const TextStyle(fontSize: 10)),
                            );
                          } else {
                            labelDate = _currentRangeStartDate.add(Duration(days: value.toInt()));
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                _selectedFilter == 'Ngày'
                                    ? DateFormat('dd').format(labelDate)
                                    : DateFormat('dd/MM').format(labelDate),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(_formatCurrencyShort(value), style: const TextStyle(fontSize: 10));
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueAccent,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        DateTime tooltipDate;
                        String dateString;

                        if (_selectedFilter == 'Tất cả') {
                          tooltipDate = DateTime(
                              _currentRangeStartDate.year,
                              _currentRangeStartDate.month + group.x.toInt(),
                              1);
                          dateString = DateFormat('MM/yyyy').format(tooltipDate);
                        } else {
                          tooltipDate = _currentRangeStartDate.add(Duration(days: group.x.toInt()));
                          dateString = DateFormat('dd/MM/yyyy').format(tooltipDate);
                        }

                        return BarTooltipItem(
                          '$dateString\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: _formatCurrency(rod.toY),
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Chi tiết giao dịch
            const Text(
              'Chi Tiết Giao Dịch:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            filteredTransactions.isEmpty
                ? const Center(
              child: Text(
                'Không có giao dịch nào trong khoảng thời gian này.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bàn: ${transaction.tableId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Thời gian: ${_formatDateTime(transaction.transactionTime)}'),
                        Text('Số tiền: ${_formatCurrency(transaction.finalBillAmount)}'),
                        if (transaction.orderedItems.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Món đã gọi: ${transaction.orderedItems.map((oi) => '${widget.menuItems.firstWhereOrNull((m) => m.id == oi.itemId)?.name} x${oi.quantity}').join(', ')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hỗ trợ định dạng tiền tệ
  String _formatCurrency(double amount) {
    final String formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
    return '$formattedAmount VNĐ';
  }

  // Hàm hỗ trợ định dạng tiền tệ rút gọn cho trục Y của biểu đồ
  String _formatCurrencyShort(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B'; // Tỷ
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M'; // Triệu
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K'; // Ngàn
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }

  String _formatFilterRangeString() {
    switch (_selectedFilter) {
      case 'Tất cả':
      // Nếu có giao dịch thì hiển thị từ năm đầu tiên đến năm hiện tại
        if (widget.transactions.isNotEmpty) {
          widget.transactions.sort((a, b) => a.transactionTime.compareTo(b.transactionTime));
          final int firstYear = widget.transactions.first.transactionTime.year;
          final int currentYear = DateTime.now().year;
          if (firstYear == currentYear) {
            return 'Năm $firstYear';
          }
          return 'Từ $firstYear đến $currentYear';
        }
        return 'Tất cả thời gian';
      case 'Ngày':
        return _selectedDate == null
            ? 'Vui lòng chọn ngày'
            : DateFormat('dd/MM/yyyy').format(_selectedDate!);
      case 'Tuần':
        return 'Tuần này (${DateFormat('dd/MM').format(_currentRangeStartDate)} - ${DateFormat('dd/MM/yyyy').format(_currentRangeEndDate.subtract(const Duration(microseconds: 1)))})';
      case 'Tháng':
        return 'Tháng này (${DateFormat('MM/yyyy').format(_currentRangeStartDate)})';
      default:
        return 'Không xác định';
    }
  }
}