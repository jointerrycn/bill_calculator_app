// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_data_provider.dart';
import '../models/custom_paper_size.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  // ... (Giữ nguyên tất cả các TextEditingController và _standardPaperSizes) ...
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _shopPhoneController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();
  final _qrImageUrlController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _customPaperNameController = TextEditingController();
  final TextEditingController _customPaperWidthController = TextEditingController();
  final TextEditingController _customPaperHeightController = TextEditingController();



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('SettingsScreen initState: WidgetsBindingObserver added.');

    _loadInitialDataIntoControllers();

    _shopNameController.addListener(_saveSettingsDelayed);
    _shopAddressController.addListener(_saveSettingsDelayed);
    _shopPhoneController.addListener(_saveSettingsDelayed);
    _bankNameController.addListener(_saveSettingsDelayed);
    _bankAccountNumberController.addListener(_saveSettingsDelayed);
    _bankAccountHolderController.addListener(_saveSettingsDelayed);
    _qrImageUrlController.addListener(_saveSettingsDelayed);
    _hourlyRateController.addListener(_saveSettingsDelayed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('SettingsScreen dispose: WidgetsBindingObserver removed.');

    _shopNameController.removeListener(_saveSettingsDelayed);
    _shopAddressController.removeListener(_saveSettingsDelayed);
    _shopPhoneController.removeListener(_saveSettingsDelayed);
    _bankNameController.removeListener(_saveSettingsDelayed);
    _bankAccountNumberController.removeListener(_saveSettingsDelayed);
    _bankAccountHolderController.removeListener(_saveSettingsDelayed);
    _qrImageUrlController.removeListener(_saveSettingsDelayed);
    _hourlyRateController.removeListener(_saveSettingsDelayed);

    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _hourlyRateController.dispose();
    _customPaperNameController.dispose();
    _customPaperWidthController.dispose();
    _customPaperHeightController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountHolderController.dispose();
    _qrImageUrlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('AppLifecycleState in SettingsScreen changed to: $state');
    if (state == AppLifecycleState.resumed) {
      debugPrint('SettingsScreen: Ứng dụng đã quay lại từ nền (resumed).');

      // CHỈNH SỬA Ở ĐÂY:
      // Chúng ta sẽ đợi AppDataProvider tải xong dữ liệu trước khi cập nhật controllers
      // để tránh việc cập nhật controllers với dữ liệu cũ hoặc khi AppDataProvider đang ở trạng thái loading.
      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
      appDataProvider.reloadData().then((_) {
        // Callback này sẽ chạy sau khi reloadData() hoàn tất
        if (mounted) { // Đảm bảo widget vẫn còn trên cây
          setState(() {
            debugPrint('SettingsScreen setState() triggered AFTER reloadData completes.');
            _loadInitialDataIntoControllers(); // Tải lại dữ liệu vào controllers sau khi dữ liệu mới đã có
          });
        }
      });
    }
  }

  void _loadInitialDataIntoControllers() {
    final appDataProvider = Provider.of<AppDataProvider>(
      context,
      listen: false,
    );
    // Dùng mounted để tránh lỗi nếu widget đã bị dispose trong quá trình async
    if (!mounted) return;

    _shopNameController.text = appDataProvider.shopName;
    _shopAddressController.text = appDataProvider.shopAddress;
    _shopPhoneController.text = appDataProvider.shopPhone;
    _bankNameController.text = appDataProvider.bankName;
    _bankAccountNumberController.text = appDataProvider.bankAccountNumber;
    _bankAccountHolderController.text = appDataProvider.bankAccountHolder;
    _qrImageUrlController.text = appDataProvider.qrImageUrl;
    _hourlyRateController.text = appDataProvider.hourlyRate.toStringAsFixed(0);
    debugPrint('SettingsScreen: Initial data loaded into controllers.');
  }

  void _saveSettings() {
    debugPrint('SettingsScreen: _saveSettings() called.');
    final appData = context.read<AppDataProvider>();
    appData.updateShopInfo2(
      _shopNameController.text,
      _shopAddressController.text,
      _shopPhoneController.text,
      _bankNameController.text,
      _bankAccountNumberController.text,
      _bankAccountHolderController.text,
      _qrImageUrlController.text,
    );
    final newRate = double.tryParse(_hourlyRateController.text) ?? 0.0;
    if (newRate > 0 && newRate != appData.hourlyRate) {
      appData.setHourlyRate(newRate);
    }
  }

  void _saveSettingsDelayed() {
    _saveSettings();
  }

  void _showAddCustomPaperSizeDialog(AppDataProvider appDataProvider) {
    _customPaperNameController.clear();
    _customPaperWidthController.clear();
    _customPaperHeightController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Thêm kích thước giấy tùy chỉnh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customPaperNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên kích thước (ví dụ: Custom 100mm)',
                ),
              ),
              TextField(
                controller: _customPaperWidthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chiều rộng (mm)'),
              ),
              TextField(
                controller: _customPaperHeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chiều cao (mm)'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Lưu ý: 1 inch = 25.4mm = 72 points (điểm ảnh PDF)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _customPaperNameController.text.trim();
                final widthMm = double.tryParse(
                  _customPaperWidthController.text.trim(),
                );
                final heightMm = double.tryParse(
                  _customPaperHeightController.text.trim(),
                );

                if (name.isNotEmpty &&
                    widthMm != null &&
                    heightMm != null &&
                    widthMm > 0 &&
                    heightMm > 0) {
                  final widthPoints = widthMm * (72 / 25.4);
                  final heightPoints = heightMm * (72 / 25.4);

                  appDataProvider.addCustomPaperSize(
                    CustomPaperSize(
                      name: name,
                      widthPoints: widthPoints,
                      heightPoints: heightPoints,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm kích thước giấy tùy chỉnh!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ và hợp lệ.'),
                    ),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SettingsScreen build() called.');
    final appDataProvider = context.watch<AppDataProvider>();

    if (appDataProvider.isLoading) {
      debugPrint('SettingsScreen: AppDataProvider is loading, showing CircularProgressIndicator.');
      return Scaffold(
        appBar: AppBar(title: const Text('Cài đặt')), // Giữ nguyên AppBar để không bị mất
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    debugPrint('SettingsScreen: AppDataProvider NOT loading, building content.');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt ứng dụng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin Quán',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _shopNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên Quán Bi-a',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _shopAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ Quán',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _shopPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Điện thoại',
                        border: OutlineInputBorder(),
                      ),
                    ),
/*                    const SizedBox(height: 20),

                    Text(
                      'Cài đặt QR Thanh toán:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên ngân hàng / Ví điện tử',
                        hintText: 'VD: Vietcombank, Momo, Zalopay...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bankAccountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Số tài khoản / Số điện thoại',
                        hintText: 'VD: 0123456789, 0901234567...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bankAccountHolderController,
                      decoration: const InputDecoration(
                        labelText: 'Tên chủ tài khoản',
                        hintText: 'VD: NGUYEN VAN A',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _qrImageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL hình ảnh QR Code (dán link ảnh)',
                        hintText: 'VD: https://example.com/your_qr.png',
                        border: OutlineInputBorder(),
                        helperText:
                        'Tải ảnh QR lên dịch vụ lưu trữ ảnh công khai và dán URL vào đây.',
                      ),
                      keyboardType: TextInputType.url,
                    ),*/
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dữ liệu ứng dụng:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                appDataProvider.backupData(context),
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Sao Lưu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                appDataProvider.restoreData(context),
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('Phục Hồi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showClearAllInvoicesDialog(context, appDataProvider);
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Xóa tất cả hóa đơn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllInvoicesDialog(BuildContext context, AppDataProvider appDataProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa tất cả hóa đơn?'),
          content: const Text('Bạn có chắc chắn muốn xóa TẤT CẢ hóa đơn? Hành động này không thể hoàn tác.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa Tất Cả'),
              onPressed: () {
                appDataProvider.clearAllInvoices();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tất cả hóa đơn thành công!')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}