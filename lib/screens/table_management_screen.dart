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
  // Controller cho form thêm bàn mới
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe AppDataProvider để có danh sách bàn và các hàm quản lý
    final appDataProvider = context.watch<AppDataProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final String name = _nameController.text.trim();
                        if (name.isNotEmpty) {
                          appDataProvider.addBilliardTable(name);
                          _nameController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã thêm bàn mới thành công!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập tên bàn.')),
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
          Expanded(
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
    );
  }

  // --- Dialog Chỉnh sửa bàn bi-a ---
  Future<void> _showEditBilliardTableDialog(BuildContext context, BilliardTable table, AppDataProvider appDataProvider) async {
    final TextEditingController editNameController = TextEditingController(text: table.name);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Chỉnh sửa Bàn: ${table.name}'),
          content: TextField(
            controller: editNameController,
            decoration: const InputDecoration(labelText: 'Tên bàn mới'),
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
                if (newName.isNotEmpty) {
                  appDataProvider.updateBilliardTable(table.id, newName);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật tên bàn!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên bàn mới.')),
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