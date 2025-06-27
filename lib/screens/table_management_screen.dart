// lib/screens/table_management_screen.dart
import 'package:flutter/material.dart';
import 'package:bill_calculator_app/models/billiard_table.dart'; // Đảm bảo import này

class TableManagementScreen extends StatefulWidget {
  final List<BilliardTable> initialTables;
  final Function(List<BilliardTable>) onSave;

  const TableManagementScreen({
    super.key,
    required this.initialTables,
    required this.onSave,
  });

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  late List<BilliardTable> _tables; // Danh sách bàn cục bộ để chỉnh sửa

  @override
  void initState() {
    super.initState();
    // Sao chép danh sách ban đầu để tránh chỉnh sửa trực tiếp danh sách gốc
    _tables = List.from(widget.initialTables);
  }

  // Hàm hiển thị dialog để thêm/chỉnh sửa bàn
  void _showTableDialog({BilliardTable? tableToEdit}) {
    // KHAI BÁO TextEditingController VÀ BIẾN ERROR CỤC BỘ TRONG HÀM NÀY
    final _idController = TextEditingController(text: tableToEdit?.id ?? '');
    String? _dialogIdError; // Biến lỗi cục bộ cho dialog

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: Text(tableToEdit == null ? 'Thêm Bàn Mới' : 'Chỉnh sửa Bàn'),
              content: TextField(
                controller: _idController, // Sử dụng controller cục bộ
                decoration: InputDecoration(
                  labelText: 'ID Bàn (ví dụ: Bàn 7)',
                  hintText: 'ví dụ: Bàn 7',
                  errorText: _dialogIdError, // Sử dụng biến error cục bộ
                  border: const OutlineInputBorder(),
                ),
                enabled: tableToEdit == null, // ID chỉ cho phép chỉnh sửa khi thêm mới
                onChanged: (value) {
                  setInnerState(() {
                    _dialogIdError = null; // Xóa lỗi khi người dùng nhập
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(tableToEdit == null ? 'Thêm' : 'Cập nhật'),
                  onPressed: () {
                    bool isValid = true;
                    setInnerState(() {
                      _dialogIdError = null; // Reset lỗi trong dialog
                      if (_idController.text.trim().isEmpty) {
                        _dialogIdError = 'ID bàn không được để trống';
                        isValid = false;
                      } else if (tableToEdit == null && _tables.any((table) => table.id == _idController.text.trim())) {
                        _dialogIdError = 'ID bàn đã tồn tại';
                        isValid = false;
                      }
                    });

                    if (!isValid) return;

                    final newTableId = _idController.text.trim();

                    // Cần setState của _TableManagementScreenState để cập nhật UI danh sách bàn
                    // bên ngoài dialog
                    setState(() {
                      if (tableToEdit == null) {
                        _tables.add(BilliardTable(id: newTableId));
                      } else {
                        // Hiện tại ID không thể sửa khi edit, nên phần này đơn giản là giữ nguyên
                        // Nếu sau này muốn cho phép sửa ID khi edit, logic sẽ phức tạp hơn
                        // vì cần cập nhật ID của bàn đang tồn tại.
                        // Với enabled: tableToEdit == null, chúng ta không cần xử lý thay đổi ID ở đây.
                      }
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      // Đây là nơi DUY NHẤT để dispose controller cục bộ này
      // Sử dụng addPostFrameCallback để đảm bảo dispose sau khi khung hình cuối cùng được vẽ
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _idController.dispose();
        debugPrint('TextEditingController for table dialog disposed via post-frame callback.');
      });
    });
  }

  // Hàm xác nhận xóa bàn
  void _confirmDeleteTable(BilliardTable tableToDelete) {
    if (tableToDelete.isOccupied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Không thể xóa bàn'),
          content: Text('Bàn ${tableToDelete.id} đang có khách. Vui lòng dừng bàn trước khi xóa.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa bàn "${tableToDelete.id}" không?'),
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
                  _tables.removeWhere((table) => table.id == tableToDelete.id);
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
        title: const Text('Quản lý Bàn Bida'),
        centerTitle: true,
      ),
      body: _tables.isEmpty
          ? const Center(
        child: Text('Chưa có bàn nào. Hãy thêm bàn mới!'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _tables.length,
        itemBuilder: (context, index) {
          final table = _tables[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2.0,
            child: ListTile(
              title: Text(table.id, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(table.isOccupied ? 'Đang chơi' : 'Trống',
                  style: TextStyle(color: table.isOccupied ? Colors.red : Colors.green)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút chỉnh sửa ID (hiện tại không cho phép sửa ID bàn đã tồn tại)
                  // Để đơn giản, chỉ cho phép thêm/xóa.
                  // IconButton(
                  //   icon: const Icon(Icons.edit, color: Colors.blueGrey),
                  //   onPressed: () => _showTableDialog(tableToEdit: table),
                  // ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteTable(table),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTableDialog(), // Thêm bàn mới
        child: const Icon(Icons.add),
      ),
      persistentFooterButtons: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onSave(_tables); // Gọi callback để lưu danh sách bàn
              Navigator.of(context).pop(); // Quay lại màn hình trước
            },
            child: const Text('Lưu Bàn và Quay lại'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Controller cho dialog được dispose trong .then() của showDialog
    super.dispose();
  }
}