// lib/screens/menu_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';


//Để quản lý thêm, sửa, xóa món ăn.

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  // Controllers cho form thêm món ăn mới
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe AppDataProvider để có danh sách món ăn và các hàm quản lý
    final appDataProvider = context.watch<AppDataProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quản lý Món ăn',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // --- Phần thêm món mới ---
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Thêm món mới:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên món',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Giá',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final String name = _nameController.text.trim();
                                  final double? price = double.tryParse(_priceController.text.trim());

                                  if (name.isNotEmpty && price != null && price > 0 ) {
                                    appDataProvider.addMenuItem(name, price);
                                    _nameController.clear();
                                    _priceController.clear();
                                    _categoryController.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã thêm món ăn thành công!')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng nhập đủ và đúng thông tin món ăn.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm Món'),
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

                    // --- Phần danh sách và chỉnh sửa/xóa món ăn ---
                    const Text(
                      'Danh sách Món ăn:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Thay Expanded bằng SizedBox với chiều cao động
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: appDataProvider.menuItems.isEmpty
                          ? const Center(child: Text('Chưa có món ăn nào. Vui lòng thêm món!'))
                          : ListView.builder(
                              itemCount: appDataProvider.menuItems.length,
                              itemBuilder: (context, index) {
                                final item = appDataProvider.menuItems[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 2,
                                  child: ListTile(
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(
                                      'Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(item.price)}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showEditMenuItemDialog(context, item, appDataProvider),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            // Xác nhận xóa
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Xác nhận xóa'),
                                                content: Text('Bạn có chắc muốn xóa "${item.name}" khỏi danh sách món ăn không?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                                                  TextButton(
                                                    onPressed: () {
                                                      appDataProvider.deleteMenuItem(item.id);
                                                      Navigator.of(ctx).pop();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Đã xóa món ăn!')),
                                                      );
                                                    },
                                                    child: const Text('Xóa'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Dialog Chỉnh sửa món ăn ---
  Future<void> _showEditMenuItemDialog(BuildContext context, MenuItem item, AppDataProvider appDataProvider) async {
    final TextEditingController editNameController = TextEditingController(text: item.name);
    final TextEditingController editPriceController = TextEditingController(text: item.price.toString());


    return showDialog<void>(

      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Chỉnh sửa Món: ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: editNameController,
                decoration: const InputDecoration(labelText: 'Tên món'),
              ),
              TextField(
                controller: editPriceController,
                decoration: const InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Cập nhật'),
              onPressed: () {
                final String newName = editNameController.text.trim();
                final double? newPrice = double.tryParse(editPriceController.text.trim());

                if (newName.isNotEmpty && newPrice != null && newPrice > 0 ) {
                  appDataProvider.updateMenuItem(item.id, newName, newPrice);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật món ăn!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đủ thông tin hợp lệ.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}