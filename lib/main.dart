import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import gói provider

// Import các màn hình và provider mà chúng ta sẽ sử dụng
import 'package:bill_calculator_app/screens/home_screen.dart'; // Sẽ tạo trong bước tiếp theo
import 'package:bill_calculator_app/providers/app_data_provider.dart'; // AppDataProvider đã tạo

void main() {
  // `runApp` là điểm bắt đầu của ứng dụng Flutter của bạn.
  // Chúng ta bọc `MyApp` trong `ChangeNotifierProvider`
  // để `AppDataProvider` có thể được truy cập bởi bất kỳ widget nào
  // trong cây widget bên dưới nó.
  runApp(
    ChangeNotifierProvider(
      // `create` là một hàm callback tạo ra một instance mới của AppDataProvider.
      // Instance này sẽ được cung cấp cho các widget con.
      create: (context) => AppDataProvider(),
      // `child` là widget gốc của ứng dụng của bạn.
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Calculator App', // Tiêu đề của ứng dụng
      theme: ThemeData(
        // Định nghĩa theme cho ứng dụng của bạn.
        // `ColorScheme.fromSeed` tạo ra một bảng màu dựa trên một màu gốc.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        // Kích hoạt Material 3 design system.
        useMaterial3: true,
      ),
      // Màn hình chính của ứng dụng bây giờ là `HomeScreen`.
      // `HomeScreen` sẽ sử dụng `Provider` để lấy dữ liệu từ `AppDataProvider`.
      home: const HomeScreen(title: 'Bill Calculator'),
    );
  }
}