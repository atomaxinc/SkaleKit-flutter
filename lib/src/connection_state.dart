/// Represents the connection state of a Skale device.
enum SkaleConnectionState {
  /// Not connected to any device.
  disconnected,

  /// Scanning for nearby devices.
  scanning,

  /// Attempting to connect to a device.
  connecting,

  /// Successfully connected to a device.
  connected,
}
