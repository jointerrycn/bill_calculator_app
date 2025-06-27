// lib/screens/menu_management_screen.dart
import 'package:flutter/material.dart';
import 'package:bill_calculator_app/models/menu_item.dart';
import 'package:intl/intl.dart'; // Để định dạng tiền tệ

class MenuManagementScreen extends StatefulWidget {
  final List<MenuItem> initialMenuItems;
  final Function(List<MenuItem>) onSave; // Callback khi lưu menu

  const MenuManagementScreen({
    super.key,
    required this.initialMenuItems,
    required this.onSave,
  });

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  late List<MenuItem> _menuItems; // Danh sách menu items cục bộ để chỉnh sửa

  // Helper để định dạng tiền tệ
  String _formatCurrency(double amount) {
    final oCcy = NumberFormat("#,##0", "vi_VN");
    return '${oCcy.format(amount.round())} VNĐ';
  }

  @override
  void initState() {
    super.initState();
    // Sao chép danh sách ban đầu để tránh chỉnh sửa trực tiếp danh sách gốc
    _menuItems = List.from(widget.initialMenuItems);
  }

  // Hàm hiển thị dialog để thêm/chỉnh sửa món
  void _showMenuItemDialog({MenuItem? itemToEdit}) {
    final _idController = TextEditingController(text: itemToEdit?.id ?? '');
    final _nameController = TextEditingController(text: itemToEdit?.name ?? '');
    final _priceController = TextEditingController(text: itemToEdit?.price.round().toString() ?? '');

    // Biến kiểm soát lỗi
    String? _idError;
    String? _nameError;
    String? _priceError;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Sử dụng StatefulBuilder để cập nhật UI trong dialog
          builder: (context, setInnerState) {
            return AlertDialog(
              title: Text(itemToEdit == null ? 'Thêm món mới' : 'Chỉnh sửa món'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: 'ID Món (duy nhất)',
                        hintText: 'ví dụ: nuoc_ngot',
                        errorText: _idError,
                        border: const OutlineInputBorder(),
                      ),
                      enabled: itemToEdit == null, // ID chỉ cho phép chỉnh sửa khi thêm mới
                      onChanged: (value) {
                        setInnerState(() {
                          _idError = null; // Xóa lỗi khi người dùng nhập
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên món',
                        hintText: 'ví dụ: Nước Ngọt',
                        errorText: _nameError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setInnerState(() {
                          _nameError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Giá (VNĐ)',
                        hintText: 'ví dụ: 15000',
                        errorText: _priceError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setInnerState(() {
                          _priceError = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(itemToEdit == null ? 'Thêm' : 'Cập nhật'),
                  onPressed: () {
                    // Validate inputs
                    bool isValid = true;
                    setInnerState(() {
                      _idError = null;
                      _nameError = null;
                      _priceError = null;

                      if (_idController.text.trim().isEmpty) {
                        _idError = 'ID không được để trống';
                        isValid = false;
                      } else if (itemToEdit == null && _menuItems.any((item) => item.id == _idController.text.trim())) {
                        _idError = 'ID đã tồn tại';
                        isValid = false;
                      }

                      if (_nameController.text.trim().isEmpty) {
                        _nameError = 'Tên món không được để trống';
                        isValid = false;
                      }

                      if (double.tryParse(_priceController.text) == null || double.parse(_priceController.text) <= 0) {
                        _priceError = 'Giá phải là số dương';
                        isValid = false;
                      }
                    });

                    if (!isValid) return; // Dừng nếu có lỗi

                    final newMenuItem = MenuItem(
                      id: _idController.text.trim(),
                      name: _nameController.text.trim(),
                      price: double.parse(_priceController.text),
                    );

                    setState(() { // Cập nhật trạng thái của _MenuManagementScreenState
                      if (itemToEdit == null) {
                        _menuItems.add(newMenuItem);
                      } else {
                        final index = _menuItems.indexWhere((item) => item.id == itemToEdit.id);
                        if (index != -1) {
                          _menuItems[index] = newMenuItem;
                        }
                      }
                    });
                    Navigator.of(context).pop(); // Đóng dialog
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Đảm bảo các controller được dispose sau khi dialog đóng
      //_idController.dispose();
      //_nameController.dispose();
      //._priceController.dispose();
    });
  }

  // Hàm xác nhận xóa món
  void _confirmDeleteItem(MenuItem itemToDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa món "${itemToDelete.name}" không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                setState(() {
                  _menuItems.removeWhere((item) => item.id == itemToDelete.id);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Menu'),
        centerTitle: true,
      ),
      body: _menuItems.isEmpty
          ? const Center(
        child: Text('Chưa có món nào trong menu. Hãy thêm món mới!'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2.0,
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${item.id}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatCurrency(item.price), style: const TextStyle(fontSize: 16, color: Colors.blue)),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () => _showMenuItemDialog(itemToEdit: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteItem(item),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenuItemDialog(), // Thêm món mới
        child: const Icon(Icons.add),
      ),
      persistentFooterButtons: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onSave(_menuItems); // Gọi callback để lưu menu
              Navigator.of(context).pop(); // Quay lại màn hình trước
            },
            child: const Text('Lưu Menu và Quay lại'),
          ),
        ),
      ],
    );
  }
}