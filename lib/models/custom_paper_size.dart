// lib/models/custom_paper_size.dart

/// Lớp đại diện cho một kích thước giấy in tùy chỉnh
class CustomPaperSize {
  final String name;
  final double widthPoints; // Chiều rộng tính bằng điểm ảnh PDF (PostScript points)
  final double heightPoints; // Chiều cao tính bằng điểm ảnh PDF (PostScript points)

  CustomPaperSize({required this.name, required this.widthPoints, required this.heightPoints});

  // Chuyển đổi từ JSON (khi tải dữ liệu từ SharedPreferences)
  factory CustomPaperSize.fromJson(Map<String, dynamic> json) {
    return CustomPaperSize(
      name: json['name'],
      widthPoints: json['widthPoints'],
      heightPoints: json[
      'heightPoints'], // Đảm bảo key khớp với cách bạn lưu trong toJson()
    );
  }

  // Chuyển đổi sang JSON (khi lưu dữ liệu vào SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'widthPoints': widthPoints,
      'heightPoints': heightPoints,
    };
  }
}