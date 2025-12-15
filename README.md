# SkaleKit for Flutter

A Flutter plugin for connecting to Skale smart coffee scales via Bluetooth Low Energy (BLE).

[![pub package](https://img.shields.io/pub/v/skale_kit.svg)](https://pub.dev/packages/skale_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- Real-time weight updates
- Device discovery with native picker UI
- Tare (zero) function
- Battery level monitoring
- Button event detection (circle and square buttons)
- Auto-connect support
- LED display control (iOS only)

## Platform Support

| Platform | Support |
|----------|---------|
| iOS      | 12.0+   |
| Android  | API 21+ |

## Installation

Add `skale_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  skale_kit: ^1.0.0
```

### iOS Setup

Add the following keys to your `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth access to connect to your Skale coffee scale.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth access to connect to your Skale coffee scale.</string>
```

### Android Setup

The plugin automatically adds the required permissions to your `AndroidManifest.xml`. However, you'll need to request permissions at runtime using a package like `permission_handler`.

## Usage

### Basic Example

```dart
import 'package:skale_kit/skale_kit.dart';

// Create an instance
final skaleKit = SkaleKit();

// Listen to connection state changes
skaleKit.connectionStateStream.listen((state) {
  print('Connection state: $state');
});

// Listen to weight updates
skaleKit.weightStream.listen((weight) {
  print('Weight: ${weight}g');
});

// Listen to button presses
skaleKit.buttonStream.listen((button) {
  print('Button pressed: $button');
});

// Show device picker and connect
final device = await skaleKit.showDevicePicker();

// Tare the scale
await skaleKit.tare();

// Get battery level
final batteryLevel = await skaleKit.getBatteryLevel();
print('Battery: $batteryLevel%');

// Disconnect
await skaleKit.disconnect();

// Don't forget to dispose
skaleKit.dispose();
```

### Permission Handling

Before connecting, ensure you have the required permissions:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  if (Platform.isAndroid) {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }
}
```

### Error Handling

The plugin uses typed exceptions for error handling:

```dart
try {
  await skaleKit.showDevicePicker();
} on BluetoothDisabledError {
  print('Please enable Bluetooth');
} on PermissionDeniedError {
  print('Bluetooth permissions required');
} on CancelledError {
  print('User cancelled device selection');
} on SkaleError catch (e) {
  print('Error: $e');
}
```

## API Reference

### SkaleKit

| Method | Description |
|--------|-------------|
| `showDevicePicker()` | Shows native device picker UI |
| `connect(device)` | Connects to a specific device |
| `disconnect()` | Disconnects from current device |
| `tare()` | Tares (zeros) the scale |
| `getBatteryLevel()` | Returns battery percentage (0-100) |
| `setLEDDisplay(bool)` | Controls LED display (iOS only) |
| `setAutoConnect(bool)` | Enables/disables auto-connect |
| `startScan()` | Starts scanning for devices |
| `stopScan()` | Stops scanning |
| `isBluetoothEnabled()` | Checks if Bluetooth is enabled |
| `hasPermissions()` | Checks if permissions are granted |
| `dispose()` | Releases resources |

### Streams

| Stream | Type | Description |
|--------|------|-------------|
| `weightStream` | `Stream<double>` | Real-time weight in grams |
| `connectionStateStream` | `Stream<SkaleConnectionState>` | Connection state changes |
| `buttonStream` | `Stream<SkaleButton>` | Button press events |
| `deviceStream` | `Stream<List<SkaleDevice>>` | Discovered devices |

### Enums

**SkaleConnectionState**
- `disconnected`
- `scanning`
- `connecting`
- `connected`

**SkaleButton**
- `circle` (value: 1)
- `square` (value: 2)

### Error Types

- `BluetoothDisabledError` - Bluetooth is disabled
- `PermissionDeniedError` - Required permissions not granted
- `DeviceNotFoundError` - Device was not found
- `ConnectionFailedError` - Failed to connect
- `ConnectionLostError` - Connection was lost
- `ConnectionTimeoutError` - Connection timed out
- `AlreadyConnectedError` - Already connected to a device
- `CancelledError` - Operation was cancelled
- `UnknownError` - Unknown error occurred

## Native SDK Integration

This plugin wraps the native SkaleKit SDKs:
- **iOS**: SkaleKit.xcframework
- **Android**: skalekit-1.0.0.aar

The native SDKs must be placed in the following locations:
- iOS: `ios/Frameworks/SkaleKit.xcframework`
- Android: `android/libs/skalekit-1.0.0.aar`

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) before submitting a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and feature requests, please [file an issue](https://github.com/atomaxinc/SkaleKit-flutter/issues) on GitHub.
