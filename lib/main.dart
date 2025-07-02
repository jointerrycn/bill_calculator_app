// lib/main.dart
import 'package:flutter/material.dart'; // Giữ lại import này
import 'package:provider/provider.dart'; // Giữ lại import này

import 'package:bill_calculator_app/providers/app_data_provider.dart'; // Giữ lại import này
import 'package:bill_calculator_app/screens/home_screen.dart'; // Giữ lại import này

// Không cần import 'package:flutter/foundation.dart'; nữa nếu không dùng kReleaseMode
// Không cần import 'package:device_preview/device_preview.dart'; nữa

void main() {
  runApp(
    // Không còn DevicePreview bọc ở đây nữa
    MultiProvider( // MultiProvider của bạn
      providers: [
        ChangeNotifierProvider(create: (_) => AppDataProvider()),
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
      // Không còn các adapter của DevicePreview nữa
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(title: 'Quản lý Bi-a'),
    );
  }
}