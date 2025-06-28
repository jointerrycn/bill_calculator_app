//Để quản lý các cài đặt chung như giá tiền theo giờ và chức năng sao lưu/phục hồi.
// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:bill_calculator_app/providers/app_data_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controller cho giá tiền theo giờ
  late TextEditingController _hourlyRateController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller với giá trị hiện tại từ provider
    // Sử dụng `listen: false` để không kích hoạt rebuild ở đây
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
    _hourlyRateController = TextEditingController(text: appDataProvider.hourlyRate.toString());
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe AppDataProvider để lấy giá tiền theo giờ và các hàm sao lưu/phục hồi
    final appDataProvider = context.watch<AppDataProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // --- Phần cài đặt giá tiền theo giờ ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giá tiền theo giờ:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _hourlyRateController,
                    decoration: InputDecoration(
                      labelText: 'Giá tiền mỗi giờ (VNĐ)',
                      hintText: 'Ví dụ: 50000',
                      border: const OutlineInputBorder(),
                      suffixText: NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(appDataProvider.hourlyRate),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Cập nhật giá trị hiển thị mà không cần setState ngay lập tức
                      // Giá trị thực sẽ được lưu khi bấm nút "Lưu"
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final double? newRate = double.tryParse(_hourlyRateController.text.trim());
                        if (newRate != null && newRate >= 0) {
                          appDataProvider.setHourlyRate(newRate);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã cập nhật giá tiền theo giờ!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập giá tiền hợp lệ.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu Giá Tiền'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Phần sao lưu và phục hồi dữ liệu ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dữ liệu ứng dụng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => appDataProvider.backupData(context),
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
                          onPressed: () => appDataProvider.restoreData(context),
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
    );
  }
}