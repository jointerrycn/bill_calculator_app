import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart'; // Đảm bảo đã import đúng

import '../models/invoice.dart'; // Đảm bảo đường dẫn đúng
import '../services/ThermalPrinterService.dart'; // Đảm bảo đường dẫn đúng

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  PaperSizeOption? selectedSize;

  @override
  void initState() {
    super.initState();

    // Tải khổ giấy đã lưu
    final printerService = Provider.of<ThermalPrinterService>(context, listen: false);
    printerService.loadPaperSize().then((value) {
      setState(() {
        selectedSize = value;
      });
    });

    // Ban đầu, không tự động quét khi initState
    // Người dùng sẽ nhấn nút "Quét" để bắt đầu
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<ThermalPrinterService>(context, listen: false).startScan();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt máy in')),
      body: Consumer<ThermalPrinterService>(
        builder: (context, printerService, child) {
          final devices = printerService.scanResults;
          final selected = printerService.defaultDevice; // Máy in mặc định

          // Kiểm tra xem đã có máy in mặc định được chọn hay chưa
          final bool isPrinterSelected = selected != null;

          return selectedSize == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn máy in Bluetooth:',
                    style: TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 8),
                // Nút Quét chủ động
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<BluetoothDevice>(
                        isExpanded: true,
                        value: selected,
                        hint: const Text('Chọn máy in'),
                        items: devices.map((device) {
                          return DropdownMenuItem<BluetoothDevice>(
                            value: device,
                            child: Text('${device.name ?? 'Không tên'} (${device.address})'),
                          );
                        }).toList(),
                        onChanged: (device) {
                          printerService.setDefaultDevice(device);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: printerService.isScanning
                          ? null // Vô hiệu hóa nút khi đang quét
                          : () {
                        printerService.startScan();
                      },
                      child: printerService.isScanning
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) // Hiển thị vòng xoay
                          : const Text('Quét'),
                    ),
                  ],
                ),
                // Hiển thị trạng thái quét hoặc thông báo
                if (printerService.isScanning)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Đang quét thiết bị...', style: TextStyle(fontStyle: FontStyle.italic)),
                  )
                else if (devices.isEmpty && !printerService.isScanning)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Không tìm thấy thiết bị Bluetooth nào.', style: TextStyle(fontStyle: FontStyle.italic)),
                  ),

                const SizedBox(height: 24),
                const Text('Chọn khổ giấy in:',
                    style: TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Cỡ giấy:'),
                    const SizedBox(width: 12),
                    DropdownButton<PaperSizeOption>(
                      value: selectedSize,
                      items: PaperSizeOption.values.map((option) {
                        return DropdownMenuItem<PaperSizeOption>(
                          value: option,
                          child: Text(option == PaperSizeOption.mm80 ? '80mm' : '58mm'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedSize = value);
                          printerService.savePaperSize(value);
                        }
                      },
                    ),
                  ],
                ),

                const Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('In thử'),
                    // Nút bị vô hiệu hóa nếu chưa chọn máy in mặc định
                    onPressed: isPrinterSelected
                        ? () async {
                      final invoice = Invoice.createFakeInvoice(); // Bạn cần thay bằng hóa đơn thực
                      final bytes = await printerService.generateReceiptFromInvoice(invoice);

                      // Không cần truyền device, vì printTicket sẽ dùng _defaultDevice
                      final result = await printerService.printTicket(bytes);
                      if (result == PrintResult.noDeviceSelected) { // Trường hợp này giờ ít xảy ra hơn
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn máy in trước khi in.')),
                        );
                      } else if (result == PrintResult.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('In thành công')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lỗi khi in')),
                        );
                      }
                    }
                        : null, // Vô hiệu hóa nút nếu không có máy in được chọn
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}