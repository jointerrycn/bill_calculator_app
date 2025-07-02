// lib/screens/table_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bill_calculator_app/models/billiard_table.dart';
import 'package:bill_calculator_app/providers/app_data_provider.dart';

//Để quản lý thêm, sửa, xóa bàn bi-a.
class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Quản lý Bàn Bi-a',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // --- Phần thêm bàn mới ---
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Thêm bàn mới:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên bàn',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Giá (VNĐ/giờ)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final String name = _nameController.text.trim();
                                  final double price = double.tryParse(_priceController.text) ?? 0;
                                  if (name.isNotEmpty && price > 0) {
                                    appDataProvider.addBilliardTable(name, price);
                                    _nameController.clear();
                                    _priceController.clear();
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã thêm bàn mới thành công!')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm Bàn'),
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

                    // --- Phần danh sách và chỉnh sửa/xóa bàn ---
                    const Text(
                      'Danh sách Bàn:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: appDataProvider.billiardTables.isEmpty
                          ? const Center(child: Text('Chưa có bàn bi-a nào. Vui lòng thêm bàn!'))
                          : ListView.builder(
                              itemCount: appDataProvider.billiardTables.length,
                              itemBuilder: (context, index) {
                                final table = appDataProvider.billiardTables[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 2,
                                  child: ListTile(
                                    title: Text(
                                      table.name,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text('Giá: ${table.price.toStringAsFixed(0)} VNĐ/giờ'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showEditBilliardTableDialog(context, table, appDataProvider),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            // Xác nhận xóa
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Xác nhận xóa'),
                                                content: Text('Bạn có chắc muốn xóa bàn "${table.name}" không?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                                                  TextButton(
                                                    onPressed: () {
                                                      appDataProvider.deleteBilliardTable(table.id);
                                                      Navigator.of(ctx).pop();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Đã xóa bàn!')),
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

  // --- Dialog Chỉnh sửa bàn bi-a ---
  void _showEditBilliardTableDialog(BuildContext context, BilliardTable table, AppDataProvider provider) {
    _nameController.text = table.name;
    _priceController.text = table.price.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa bàn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên bàn'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá (VNĐ/giờ)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final price = double.tryParse(_priceController.text) ?? 0;
              if (name.isNotEmpty && price > 0) {
                provider.updateBilliardTable(table.id, name, price);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật bàn!')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}