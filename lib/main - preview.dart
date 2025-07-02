// lib/main.dart
import 'package:flutter/foundation.dart'; // Import này để kiểm tra chế độ debug
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart'; // <-- Import DevicePreview

import 'package:bill_calculator_app/providers/app_data_provider.dart';
import 'package:bill_calculator_app/screens/home_screen.dart'; // Widget gốc của bạn

void main() {
  runApp(
    // Bọc MaterialApp bằng DevicePreview

    DevicePreview(
      // Chỉ bật DevicePreview khi ở chế độ DEBUG.
      // Điều này rất quan trọng để tránh đưa DevicePreview vào bản phát hành (release build) của bạn.
      enabled: !kReleaseMode, // kReleaseMode là một hằng số từ foundation.dart
      builder: (context) => MultiProvider( // MultiProvider của bạn
        providers: [
          ChangeNotifierProvider(create: (_) => AppDataProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Thêm các adapter cần thiết cho DevicePreview
      // Điều này giúp DevicePreview điều chỉnh locale, builder và theme
      locale: DevicePreview.locale(context), // Cập nhật locale
      builder: DevicePreview.appBuilder,    // Cập nhật builder để hỗ trợ DevicePreview
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(title: 'Quản lý Bi-a'),
    );
  }
}