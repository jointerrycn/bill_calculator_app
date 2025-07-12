import 'package:bill_calculator_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';
import 'package:bill_calculator_app/services/ThermalPrinterService.dart';



void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppDataProvider()),
        // Sử dụng ChangeNotifierProxyProvider để truyền AppDataProvider vào ThermalPrinterService
        ChangeNotifierProxyProvider<AppDataProvider, ThermalPrinterService>(
          // `update` được gọi khi AppDataProvider thay đổi,
          // hoặc lần đầu tiên khi ThermalPrinterService được tạo.
          // `appDataProvider` là instance của AppDataProvider.
          // `previousThermalService` là instance ThermalPrinterService trước đó (nếu có).
          update: (context, appDataProvider, previousThermalService) {
            // Trả về một instance mới của ThermalPrinterService với appDataProvider.
            // Nếu ThermalPrinterService không quản lý trạng thái phức tạp,
            // bạn có thể luôn tạo mới. Nếu nó có trạng thái cần được giữ lại,
            // bạn có thể cân nhắc tái sử dụng `previousThermalService` nếu không null.
            return ThermalPrinterService(appDataProvider);
          },
          // `create` được gọi lần đầu tiên.
          // cần cung cấp appDataProvider ở đây nếu ThermalPrinterService được tạo sớm.
          create: (context) => ThermalPrinterService(
              Provider.of<AppDataProvider>(context, listen: false)),
        ),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bi-a Smart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(title: 'Bi-a Smart'), // Hoặc màn hình Home của bạn
    );
  }
}