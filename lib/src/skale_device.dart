/// Represents a discovered Skale device.
class SkaleDevice {
  /// Creates a new [SkaleDevice] instance.
  const SkaleDevice({
    required this.id,
    required this.name,
    this.rssi = 0,
  });

  /// The unique identifier of the device.
  ///
  /// On iOS, this is a UUID string.
  /// On Android, this is the MAC address.
  final String id;

  /// The advertised name of the device.
  final String name;

  /// The received signal strength indicator in dBm.
  ///
  /// A higher (less negative) value indicates a stronger signal.
  final int rssi;

  /// Creates a [SkaleDevice] from a map representation.
  factory SkaleDevice.fromMap(Map<String, dynamic> map) {
    return SkaleDevice(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      rssi: map['rssi'] as int? ?? 0,
    );
  }

  /// Converts this device to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rssi': rssi,
    };
  }

  @override
  String toString() => 'SkaleDevice(id: $id, name: $name, rssi: $rssi)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkaleDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
