// --- Class Printer model của bạn (trong printer.dart hoặc tương tự) ---
enum ConnectionType { NETWORK, BLE }

class Printer2 {
  final String? name;
  final String? address;
  final ConnectionType? connectionType;
  bool isConnected;

  Printer2({
    this.name,
    this.address,
    this.connectionType,
    this.isConnected = false,
  });

  factory Printer2.fromJson(Map<String, dynamic> json) {
    return Printer2(
      name: json['name'] as String?,
      address: json['address'] as String?,
      connectionType: (json['connectionType'] as String?) != null
          ? ConnectionType.values.firstWhere(
            (e) => e.toString().split('.').last == json['connectionType'],
        orElse: () => ConnectionType.NETWORK,
      )
          : null,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'connectionType': connectionType?.toString().split('.').last,
      'isConnected': isConnected,
    };
  }

  Printer2 copyWith({
    String? name,
    String? address,
    ConnectionType? connectionType,
    bool? isConnected,
  }) {
    return Printer2(
      name: name ?? this.name,
      address: address ?? this.address,
      connectionType: connectionType ?? this.connectionType,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}