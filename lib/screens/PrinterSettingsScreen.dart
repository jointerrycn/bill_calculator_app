// lib/screens/printer_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_thermal_printer/utils/printer.dart' as ftp_utils; // Đảm bảo import này
import 'dart:async'; // Cần để sử dụng StreamSubscription
import 'package:printing/printing.dart';

import '../services/ThermalPrinterService.dart'; // ✅ Import này để sử dụng lớp Printer của gói printing

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final TextEditingController _networkIpController = TextEditingController();
  final TextEditingController _networkPortController = TextEditingController();

  ftp_utils.Printer? _selectedBluetoothPrinter;
  ftp_utils.Printer? _selectedNetworkPrinter;
  Printer? _selectedUsbPrinter; // ✅ Đây là lớp Printer từ gói printing

  StreamSubscription? _bluetoothConnectionStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
  }

  @override
  void dispose() {
    // QUAN TRỌNG: Dừng tất cả các quá trình quét khi màn hình bị hủy
    final thermalPrinterService = Provider.of<ThermalPrinterService>(context, listen: false);
    thermalPrinterService.stopScan();
    _networkIpController.dispose();
    _networkPortController.dispose();
    _bluetoothConnectionStateSubscription?.cancel();
    super.dispose();
  }

  void _loadInitialSettings() async {
    final thermalPrinterService = Provider.of<ThermalPrinterService>(context, listen: false);

    // Load và đặt các máy in mặc định
    // Sử dụng defaultThermalPrinter cho Bluetooth/Network
    _selectedBluetoothPrinter = thermalPrinterService.defaultThermalPrinter?.connectionType == ftp_utils.ConnectionType.BLE
        ? thermalPrinterService.defaultThermalPrinter
        : null;
    _selectedNetworkPrinter = thermalPrinterService.defaultThermalPrinter?.connectionType == ftp_utils.ConnectionType.NETWORK
        ? thermalPrinterService.defaultThermalPrinter
        : null;
    // Sử dụng defaultUsbPrinter cho USB/System
    _selectedUsbPrinter = thermalPrinterService.defaultUsbPrinter;

    // Load giá trị IP và Port cho máy in mạng nếu có
    if (_selectedNetworkPrinter != null && _selectedNetworkPrinter!.address != null) {
      _networkIpController.text = _selectedNetworkPrinter!.address!;
      _networkPortController.text = thermalPrinterService.defaultNetworkPrinterPort.toString();
    }

    // Nếu máy in Bluetooth mặc định đã được chọn, bắt đầu lắng nghe trạng thái kết nối
    if (_selectedBluetoothPrinter != null && _selectedBluetoothPrinter!.address != null) {
      _listenToBluetoothConnectionState(_selectedBluetoothPrinter!.address!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Khởi tạo các danh sách máy in có sẵn
      //thermalPrinterService.startScan(scanType: ftp_utils.ConnectionType.BLE);
      //thermalPrinterService.startScan(scanType: ftp_utils.ConnectionType.NETWORK);
      thermalPrinterService.listAvailableUsbPrinters();
    });
  }

  // Hàm để lắng nghe trạng thái kết nối của máy in Bluetooth
  void _listenToBluetoothConnectionState(String deviceId) {
    _bluetoothConnectionStateSubscription?.cancel(); // Hủy subscription cũ nếu có

    final BluetoothDevice device = BluetoothDevice.fromId(deviceId);
    _bluetoothConnectionStateSubscription = device.connectionState.listen((BluetoothConnectionState state) {
      debugPrint('Bluetooth device $deviceId connection state: $state');
      // Cập nhật trạng thái isConnected của máy in Bluetooth đã chọn
      if (_selectedBluetoothPrinter != null && _selectedBluetoothPrinter!.address == deviceId) {
        setState(() {
          _selectedBluetoothPrinter!.isConnected = state == BluetoothConnectionState.connected;
        });
      }
      // Cập nhật trạng thái isConnected trong scanResults để UI tự động refresh nếu cần
      final thermalPrinterService = Provider.of<ThermalPrinterService>(context, listen: false);
      final index = thermalPrinterService.scanResults.indexWhere((p) =>
      p.address == deviceId && p.connectionType == ftp_utils.ConnectionType.BLE);
      if (index != -1) {
        thermalPrinterService.scanResults[index].isConnected = state == BluetoothConnectionState.connected;
        thermalPrinterService.notifyListeners(); // Thông báo cho Provider
      }
    });
  }

  // Hàm để kết nối/ngắt kết nối Bluetooth
  Future<void> _toggleBluetoothConnection(ftp_utils.Printer printer) async {
    final thermalPrinterService = Provider.of<ThermalPrinterService>(context, listen: false); // Lấy service nếu cần
    final BluetoothDevice device = BluetoothDevice.fromId(printer.address!);

    if (printer.isConnected == true) {
      // Đang kết nối, thực hiện ngắt kết nối
      await device.disconnect();
    } else {
      // Chưa kết nối, thực hiện kết nối
      try {
        await device.connect();
        // Sau khi kết nối, trạng thái sẽ được cập nhật thông qua _bluetoothConnectionStateSubscription
      } catch (e) {
        debugPrint('Failed to connect to Bluetooth printer: $e');
        // Xử lý lỗi kết nối
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể kết nối đến máy in Bluetooth: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final thermalPrinterService = Provider.of<ThermalPrinterService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt máy in'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Cài đặt kích thước giấy in ---
            Text(
              'Kích thước giấy in hóa đơn:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            FutureBuilder<PaperSizeOption>(
              future: thermalPrinterService.loadPaperSize(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final currentPaperSize = snapshot.data ?? PaperSizeOption.mm80;
                return DropdownButton<PaperSizeOption>(
                  value: currentPaperSize,
                  onChanged: (PaperSizeOption? newValue) {
                    if (newValue != null) {
                      thermalPrinterService.savePaperSize(newValue);
                      setState(() {}); // Cập nhật UI
                    }
                  },
                  items: PaperSizeOption.values.map((PaperSizeOption size) {
                    return DropdownMenuItem<PaperSizeOption>(
                      value: size,
                      child: Text(size == PaperSizeOption.mm80 ? '80mm' : '58mm'),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // --- Chọn loại máy in mặc định ---
            Text(
              'Chọn loại máy in mặc định:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RadioListTile<DefaultPrinterType>(
              title: const Text('Không chọn'),
              value: DefaultPrinterType.none,
              groupValue: thermalPrinterService.defaultPrinterType,
              onChanged: (DefaultPrinterType? value) {
                if (value != null) {
                  thermalPrinterService.setDefaultPrinterType(value);
                  // Logic xóa máy in mặc định cũ đã được xử lý trong setDefaultPrinterType của service
                }
              },
            ),
            RadioListTile<DefaultPrinterType>(
              title: const Text('Máy in Bluetooth'),
              value: DefaultPrinterType.bluetooth,
              groupValue: thermalPrinterService.defaultPrinterType,
              onChanged: (DefaultPrinterType? value) {
                if (value != null) {
                  thermalPrinterService.setDefaultPrinterType(value);
                }
              },
            ),
            RadioListTile<DefaultPrinterType>(
              title: const Text('Máy in Mạng (LAN/Wifi)'),
              value: DefaultPrinterType.network,
              groupValue: thermalPrinterService.defaultPrinterType,
              onChanged: (DefaultPrinterType? value) {
                if (value != null) {
                  thermalPrinterService.setDefaultPrinterType(value);
                }
              },
            ),
            RadioListTile<DefaultPrinterType>(
              title: const Text('Máy in USB/Hệ thống'),
              value: DefaultPrinterType.usb,
              groupValue: thermalPrinterService.defaultPrinterType,
              onChanged: (DefaultPrinterType? value) {
                if (value != null) {
                  thermalPrinterService.setDefaultPrinterType(value);
                }
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // --- Cài đặt cho máy in Bluetooth ---
            if (thermalPrinterService.defaultPrinterType == DefaultPrinterType.bluetooth)
              _buildBluetoothPrinterSettings(thermalPrinterService),

            // --- Cài đặt cho máy in Mạng ---
            if (thermalPrinterService.defaultPrinterType == DefaultPrinterType.network)
              _buildNetworkPrinterSettings(thermalPrinterService),

            // --- Cài đặt cho máy in USB/Hệ thống ---
            if (thermalPrinterService.defaultPrinterType == DefaultPrinterType.usb)
              _buildUsbPrinterSettings(thermalPrinterService),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothPrinterSettings(ThermalPrinterService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Máy in Bluetooth:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: service.isScanning
              ? null
              : () => service.startScan(scanType: ftp_utils.ConnectionType.BLE),
          child: Text(service.isScanning ? 'Đang quét...' : 'Tìm máy in Bluetooth'),
        ),
        if (service.isScanning)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: service.scanResults.length,
          itemBuilder: (context, index) {
            final printer = service.scanResults[index];
            // So sánh với defaultThermalPrinter (là máy in nhiệt mặc định, bao gồm cả Bluetooth và Network)
            final isDefault = service.defaultThermalPrinter?.address == printer.address &&
                service.defaultThermalPrinter?.connectionType == ftp_utils.ConnectionType.BLE;
            final isConnected = printer.isConnected ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              color: isDefault ? Colors.blue.shade50 : null,
              child: ListTile(
                title: Text(printer.name ?? 'Unknown Device'),
                subtitle: Text('${printer.address} - ${isConnected ? 'Đã kết nối' : 'Chưa kết nối'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (printer.address != null) // Chỉ hiển thị nút kết nối nếu có địa chỉ
                      IconButton(
                        icon: Icon(
                          isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected,
                          color: isConnected ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _toggleBluetoothConnection(printer),
                        tooltip: isConnected ? 'Ngắt kết nối' : 'Kết nối',
                      ),
                    Radio<ftp_utils.Printer>(
                      value: printer,
                      groupValue: _selectedBluetoothPrinter,
                      onChanged: (ftp_utils.Printer? value) {
                        setState(() {
                          _selectedBluetoothPrinter = value;
                        });
                        if (value != null) {
                          // Đặt máy in nhiệt mặc định
                          service.setDefaultThermalPrinter(value);
                          // Lắng nghe trạng thái kết nối cho máy in mới được chọn
                          if (value.address != null) {
                            _listenToBluetoothConnectionState(value.address!);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (service.scanResults.isEmpty && !service.isScanning)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Không tìm thấy máy in Bluetooth nào. Đảm bảo Bluetooth đang bật và máy in đang ở chế độ ghép nối.'),
          ),
      ],
    );
  }

  Widget _buildNetworkPrinterSettings(ThermalPrinterService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Máy in Mạng:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _networkIpController,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ IP',
            hintText: 'Ví dụ: 192.168.1.100',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _networkPortController,
          decoration: const InputDecoration(
            labelText: 'Cổng (Port)',
            hintText: 'Mặc định: 9100',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            final ip = _networkIpController.text;
            final port = int.tryParse(_networkPortController.text) ?? 9100; // Lấy giá trị port
            if (ip.isNotEmpty) {
              final networkPrinter = ftp_utils.Printer(
                address: ip,
                name: 'Máy in Mạng ($ip:$port)',
                connectionType: ftp_utils.ConnectionType.NETWORK,
              );
              setState(() {
                _selectedNetworkPrinter = networkPrinter;
              });
              // Đặt máy in nhiệt mặc định (là máy in mạng)
              await service.setDefaultThermalPrinter(networkPrinter);
              // Lưu cổng mặc định cho máy in mạng
              await service.setDefaultNetworkPrinterPort(port);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu máy in mạng mặc định.')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập địa chỉ IP.')),
              );
            }
          },
          child: const Text('Lưu máy in mạng mặc định'),
        ),
        const SizedBox(height: 10),
        // Hiển thị máy in mạng mặc định và cổng
        if (service.defaultThermalPrinter?.connectionType == ftp_utils.ConnectionType.NETWORK)
          Text(
            'Máy in mạng mặc định: ${service.defaultThermalPrinter?.name ?? service.defaultThermalPrinter?.address} (Cổng: ${service.defaultNetworkPrinterPort})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildUsbPrinterSettings(ThermalPrinterService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Máy in USB/Hệ thống:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => service.listAvailableUsbPrinters(),
          child: const Text('Tìm máy in USB/Hệ thống'),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: service.availableUsbPrinters.length,
          itemBuilder: (context, index) {
            final printer = service.availableUsbPrinters[index];
            final isDefault = service.defaultUsbPrinter?.url == printer.url;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              color: isDefault ? Colors.blue.shade50 : null,
              child: ListTile(
                title: Text(printer.name ?? 'Unknown USB Printer'),
                subtitle: Text(printer.url),
                trailing: Radio<Printer>( // ✅ Đây là Radio cho lớp Printer của gói printing
                  value: printer,
                  groupValue: _selectedUsbPrinter,
                  onChanged: (Printer? value) {
                    setState(() {
                      _selectedUsbPrinter = value;
                    });
                    if (value != null) {
                      service.setDefaultUsbPrinter(value);
                    }
                  },
                ),
              ),
            );
          },
        ),
        if (service.availableUsbPrinters.isEmpty && !service.isScanning)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Không tìm thấy máy in USB/Hệ thống nào. Đảm bảo máy in được kết nối và driver đã được cài đặt.'),
          ),
      ],
    );
  }
}