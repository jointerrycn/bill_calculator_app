import 'package:bill_calculator_app/providers/app_data_provider.dart';
import 'package:bill_calculator_app/screens/home_screen.dart';
import 'package:bill_calculator_app/services/ThermalPrinterService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



void main() {
  runApp(
    // Sử dụng MultiProvider để khai báo nhiều Provider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThermalPrinterService()),
        ChangeNotifierProvider(create: (context) => AppDataProvider()), // Provider thứ hai
        // Thêm các Provider khác nếu có
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
      title: 'Printer Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(title: 'Bi-a Smart'), // Hoặc màn hình Home của bạn
    );
  }
}