// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Để định dạng tiền tệ
import '../providers/app_data_provider.dart';
import '../models/custom_paper_size.dart'; // Đảm bảo import CustomPaperSize

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controllers cho thông tin quán
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _shopPhoneController = TextEditingController();

  //Bank
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();
  final _qrImageUrlController = TextEditingController();

  // Controller cho giá tiền theo giờ chung (nếu bạn muốn có một mức giá chung)
  final TextEditingController _hourlyRateController = TextEditingController();

  // Controllers cho giấy tùy chỉnh
  final TextEditingController _customPaperNameController =
      TextEditingController();
  final TextEditingController _customPaperWidthController =
      TextEditingController();
  final TextEditingController _customPaperHeightController =
      TextEditingController();

  // Danh sách các tùy chọn kích thước giấy chuẩn
  static const Map<String, String> _standardPaperSizes = {
    'roll80': 'Giấy in nhiệt 80mm',
    'roll57': 'Giấy in nhiệt 57mm',
    'a4': 'A4 (210x297mm)',
    'a5': 'A5 (148x210mm)',
    'letter': 'Letter (216x279mm)',
  };

  @override
  void initState() {
    super.initState();
    // Khởi tạo controllers với giá trị ban đầu từ AppDataProvider (listen: false)
    // để tránh kích hoạt rebuild khi khởi tạo.
    final appDataProvider = Provider.of<AppDataProvider>(
      context,
      listen: false,
    );
    _shopNameController.text = appDataProvider.shopName;
    _shopAddressController.text = appDataProvider.shopAddress;
    _shopPhoneController.text = appDataProvider.shopPhone;
    _bankNameController.text = appDataProvider.bankName; // Khởi tạo
    _bankAccountNumberController.text =
        appDataProvider.bankAccountNumber; // Khởi tạo
    _bankAccountHolderController.text =
        appDataProvider.bankAccountHolder; // Khởi tạo
    _qrImageUrlController.text = appDataProvider.qrImageUrl; // Khởi tạo

    _shopNameController.addListener(_saveSettingsDelayed);
    _shopAddressController.addListener(_saveSettingsDelayed);
    _shopPhoneController.addListener(_saveSettingsDelayed);
    _bankNameController.addListener(_saveSettingsDelayed);
    _bankAccountNumberController.addListener(_saveSettingsDelayed);
    _bankAccountHolderController.addListener(_saveSettingsDelayed);
    _qrImageUrlController.addListener(_saveSettingsDelayed);
    // _hourlyRateController.text = appDataProvider.hourlyRate.toString(); // Chỉ khởi tạo nếu bạn vẫn dùng giá chung
  }

  // Hàm lưu cài đặt
  void _saveSettings() {
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
  }

  void _saveSettingsDelayed() {
    _saveSettings(); // Gọi hàm lưu trực tiếp
  }

  @override
  void dispose() {
    _shopNameController.removeListener(_saveSettingsDelayed);
    _shopAddressController.removeListener(_saveSettingsDelayed);
    _shopPhoneController.removeListener(_saveSettingsDelayed);
    _bankNameController.removeListener(_saveSettingsDelayed);
    _bankAccountNumberController.removeListener(_saveSettingsDelayed);
    _bankAccountHolderController.removeListener(_saveSettingsDelayed);
    _qrImageUrlController.removeListener(_saveSettingsDelayed);

    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _hourlyRateController.dispose();
    _customPaperNameController.dispose();
    _customPaperWidthController.dispose();
    _customPaperHeightController.dispose();
    _bankNameController.dispose(); // Dispose
    _bankAccountNumberController.dispose(); // Dispose
    _bankAccountHolderController.dispose(); // Dispose
    _qrImageUrlController.dispose(); // Dispose
    super.dispose();
  }

  // Hàm hiển thị dialog thêm giấy tùy chỉnh
  void _showAddCustomPaperSizeDialog(AppDataProvider appDataProvider) {
    _customPaperNameController.clear();
    _customPaperWidthController.clear();
    _customPaperHeightController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Đổi tên context thành dialogContext
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
                  // Chuyển đổi mm sang points (1mm = 72/25.4 points ≈ 2.8346 points)
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
                    // Show snackbar in the main context
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
    // Lắng nghe AppDataProvider để cập nhật UI tự động
    final appDataProvider = context.watch<AppDataProvider>();

    // Tạo danh sách tất cả các loại giấy có thể chọn
    Map<String, String> allPaperSizes = {..._standardPaperSizes};
    for (var customSize in appDataProvider.customPaperSizes) {
      allPaperSizes[customSize.name] = '${customSize.name} (Tùy chỉnh)';
    }

    return Scaffold(

      body: SingleChildScrollView(
        // <-- SỬ DỤNG SingleChildScrollView TRỰC TIẾP
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cài đặt',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // --- Phần cài đặt thông tin quán ---
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
                    const SizedBox(height: 20),

                    // Cài đặt QR Thanh toán
                    Text(
                      'Cài đặt QR Thanh toán:',
                      style: Theme.of(context).textTheme.headlineSmall,
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
                    ),
                  ],
                ),
              ),
            ),

            // --- Phần cài đặt kích thước giấy in ---
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
                      'Kích thước giấy in hóa đơn',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value:
                          appDataProvider.selectedPaperSize.isEmpty &&
                              allPaperSizes.isNotEmpty
                          ? allPaperSizes
                                .keys
                                .first // Đặt giá trị mặc định hợp lệ nếu selectedPaperSize rỗng
                          : appDataProvider.selectedPaperSize,
                      decoration: const InputDecoration(
                        labelText: 'Chọn kích thước giấy',
                        border: OutlineInputBorder(),
                      ),
                      items: allPaperSizes.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          appDataProvider.updateSelectedPaperSize(newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showAddCustomPaperSizeDialog(appDataProvider),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm giấy tùy chỉnh'),
                      ),
                    ),
                    // Hiển thị danh sách giấy tùy chỉnh để xóa
                    if (appDataProvider.customPaperSizes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Giấy tùy chỉnh của bạn:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        // Quan trọng để ListView lồng trong Column
                        physics: const NeverScrollableScrollPhysics(),
                        // Vô hiệu hóa cuộn riêng của ListView
                        itemCount: appDataProvider.customPaperSizes.length,
                        itemBuilder: (context, index) {
                          final customSize =
                              appDataProvider.customPaperSizes[index];
                          return ListTile(
                            title: Text(customSize.name),
                            subtitle: Text(
                              '${(customSize.widthPoints / (72 / 25.4)).toStringAsFixed(1)}mm x '
                              '${(customSize.heightPoints / (72 / 25.4)).toStringAsFixed(1)}mm '
                              '(${customSize.widthPoints.toStringAsFixed(1)} x ${customSize.heightPoints.toStringAsFixed(1)} points)',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                appDataProvider.removeCustomPaperSize(
                                  customSize.name,
                                );
                                if (appDataProvider.selectedPaperSize ==
                                    customSize.name) {
                                  // Nếu giấy đang chọn bị xóa, đặt lại mặc định hoặc chọn giấy tùy chỉnh đầu tiên nếu có
                                  appDataProvider.updateSelectedPaperSize(
                                    appDataProvider.customPaperSizes.isNotEmpty
                                        ? appDataProvider
                                              .customPaperSizes
                                              .first
                                              .name
                                        : 'roll80',
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // --- Phần sao lưu và phục hồi dữ liệu ---
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
