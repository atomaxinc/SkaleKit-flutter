import 'dart:async';

import 'package:flutter/services.dart';

import 'connection_state.dart';
import 'skale_device.dart';
import 'skale_error.dart';

/// The main interface for interacting with Skale coffee scales.
///
/// Use [SkaleKit] to discover, connect to, and communicate with Skale devices.
///
/// Example usage:
/// ```dart
/// final skaleKit = SkaleKit();
///
/// // Listen to connection state changes
/// skaleKit.connectionStateStream.listen((state) {
///   print('Connection state: $state');
/// });
///
/// // Listen to weight updates
/// skaleKit.weightStream.listen((weight) {
///   print('Weight: ${weight}g');
/// });
///
/// // Start scanning and show device picker
/// final device = await skaleKit.showDevicePicker();
/// if (device != null) {
///   await skaleKit.connect(device);
/// }
/// ```
class SkaleKit {
  /// Creates a new [SkaleKit] instance.
  SkaleKit() {
    _setupEventChannels();
  }

  static const MethodChannel _methodChannel =
      MethodChannel('com.atomaxinc.skalekit/methods');

  static const EventChannel _weightChannel =
      EventChannel('com.atomaxinc.skalekit/weight');

  static const EventChannel _connectionStateChannel =
      EventChannel('com.atomaxinc.skalekit/connectionState');

  static const EventChannel _buttonChannel =
      EventChannel('com.atomaxinc.skalekit/button');

  static const EventChannel _deviceChannel =
      EventChannel('com.atomaxinc.skalekit/devices');

  StreamSubscription<dynamic>? _weightSubscription;
  StreamSubscription<dynamic>? _connectionStateSubscription;
  StreamSubscription<dynamic>? _buttonSubscription;
  StreamSubscription<dynamic>? _deviceSubscription;

  final StreamController<double> _weightController =
      StreamController<double>.broadcast();

  final StreamController<SkaleConnectionState> _connectionStateController =
      StreamController<SkaleConnectionState>.broadcast();

  final StreamController<SkaleButton> _buttonController =
      StreamController<SkaleButton>.broadcast();

  final StreamController<List<SkaleDevice>> _deviceController =
      StreamController<List<SkaleDevice>>.broadcast();

  bool _isDisposed = false;

  void _setupEventChannels() {
    _weightSubscription = _weightChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is num) {
          _weightController.add(event.toDouble());
        }
      },
      onError: (dynamic error) {
        _weightController.addError(_parseError(error));
      },
    );

    _connectionStateSubscription =
        _connectionStateChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          final state = _parseConnectionState(event);
          _connectionStateController.add(state);
        }
      },
      onError: (dynamic error) {
        _connectionStateController.addError(_parseError(error));
      },
    );

    _buttonSubscription = _buttonChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is int) {
          final button = SkaleButton.fromValue(event);
          if (button != null) {
            _buttonController.add(button);
          }
        }
      },
      onError: (dynamic error) {
        _buttonController.addError(_parseError(error));
      },
    );

    _deviceSubscription = _deviceChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is List) {
          final devices = event
              .whereType<Map>()
              .map((e) => SkaleDevice.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          _deviceController.add(devices);
        }
      },
      onError: (dynamic error) {
        _deviceController.addError(_parseError(error));
      },
    );
  }

  /// Stream of weight updates in grams.
  ///
  /// The stream emits weight values as the scale measures them in real-time.
  Stream<double> get weightStream => _weightController.stream;

  /// Stream of connection state changes.
  Stream<SkaleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream of button press events.
  Stream<SkaleButton> get buttonStream => _buttonController.stream;

  /// Stream of discovered devices during scanning.
  Stream<List<SkaleDevice>> get deviceStream => _deviceController.stream;

  /// Whether the device is currently connected.
  Future<bool> get isConnected async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if Bluetooth is currently enabled on the device.
  Future<bool> isBluetoothEnabled() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isBluetoothEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if all required permissions are granted.
  ///
  /// On Android 12+, this checks for BLUETOOTH_SCAN and BLUETOOTH_CONNECT.
  /// On older Android versions, this checks for location permissions.
  /// On iOS, this checks for Bluetooth permission.
  Future<bool> hasPermissions() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('hasPermissions');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Requests the required Bluetooth permissions.
  ///
  /// Returns `true` if all permissions were granted.
  Future<bool> requestPermissions() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Starts scanning for nearby Skale devices.
  ///
  /// Discovered devices will be emitted through [deviceStream].
  /// Call [stopScan] to stop scanning.
  ///
  /// Throws [BluetoothDisabledError] if Bluetooth is not enabled.
  /// Throws [PermissionDeniedError] if required permissions are not granted.
  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod<void>('startScan');
    } on PlatformException catch (e) {
      throw _parseError(e);
    }
  }

  /// Stops scanning for devices.
  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod<void>('stopScan');
    } on PlatformException catch (e) {
      throw _parseError(e);
    }
  }

  /// Shows the native device picker UI.
  ///
  /// Returns the selected [SkaleDevice], or `null` if the user cancelled.
  ///
  /// This method provides a platform-native UI for device selection:
  /// - On iOS, it shows a modal view controller with device list.
  /// - On Android, it shows a dialog with device list.
  ///
  /// Throws [BluetoothDisabledError] if Bluetooth is not enabled.
  /// Throws [PermissionDeniedError] if required permissions are not granted.
  Future<SkaleDevice?> showDevicePicker() async {
    try {
      final result = await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('showDevicePicker');
      if (result == null) return null;
      return SkaleDevice.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') return null;
      throw _parseError(e);
    }
  }

  /// Connects to the specified device.
  ///
  /// After connecting, weight updates will be emitted through [weightStream].
  ///
  /// Throws [ConnectionFailedError] if the connection fails.
  /// Throws [AlreadyConnectedError] if already connected to a device.
  /// Throws [ConnectionTimeoutError] if the connection times out.
  Future<void> connect(SkaleDevice device) async {
    try {
      await _methodChannel.invokeMethod<void>('connect', device.toMap());
    } on PlatformException catch (e) {
      throw _parseError(e);
    }
  }

  /// Disconnects from the currently connected device.
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod<void>('disconnect');
    } on PlatformException catch (e) {
      throw _parseError(e);
    }
  }

  /// Tares (zeros) the scale.
  ///
  /// This sets the current weight as the zero reference point.
  /// Must be connected to a device.
  Future<void> tare() async {
    try {
      await _methodChannel.invokeMethod<void>('tare');
    } on PlatformException catch (e) {
      throw _parseError(e);
    }
  }

  /// Gets the current battery level of the connected device.
  ///
  /// Returns the battery percentage (0-100).
  /// Must be connected to a device.
  Future<int> getBatteryLevel() async {
    try {
      final result =
          await _methodChannel.invokeMethod<int>('getBatteryLevel');
      return result ?? 0;
    } on PlatformException catch (e) {
      throw _parseError(e);
    }
  }

  /// Sets the LED display state on the scale.
  ///
  /// Set [isOn] to `true` to turn the LED on, `false` to turn it off.
  /// Must be connected to a device.
  Future<void> setLEDDisplay(bool isOn) async {
    try {
      await _methodChannel.invokeMethod<void>('setLEDDisplay', {'isOn': isOn});
    } on PlatformException catch (e) {
      throw _parseError(e);
    }
  }

  /// Enables or disables auto-connect feature.
  ///
  /// When enabled, the SDK will automatically reconnect to the last
  /// connected device when it becomes available.
  Future<void> setAutoConnect(bool enabled) async {
    try {
      await _methodChannel
          .invokeMethod<void>('setAutoConnect', {'enabled': enabled});
    } on PlatformException catch (e) {
      throw _parseError(e);
    }
  }

  /// Releases all resources used by this instance.
  ///
  /// After calling dispose, this instance should not be used anymore.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _weightSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _buttonSubscription?.cancel();
    _deviceSubscription?.cancel();

    _weightController.close();
    _connectionStateController.close();
    _buttonController.close();
    _deviceController.close();
  }

  SkaleConnectionState _parseConnectionState(String state) {
    return switch (state.toUpperCase()) {
      'DISCONNECTED' => SkaleConnectionState.disconnected,
      'SCANNING' => SkaleConnectionState.scanning,
      'CONNECTING' => SkaleConnectionState.connecting,
      'CONNECTED' => SkaleConnectionState.connected,
      _ => SkaleConnectionState.disconnected,
    };
  }

  SkaleError _parseError(dynamic error) {
    String? code;
    String? message;

    if (error is PlatformException) {
      code = error.code;
      message = error.message;
    } else if (error is Map) {
      code = error['code'] as String?;
      message = error['message'] as String?;
    }

    return switch (code) {
      'BLUETOOTH_DISABLED' => BluetoothDisabledError(message),
      'PERMISSION_DENIED' => PermissionDeniedError(message),
      'DEVICE_NOT_FOUND' => DeviceNotFoundError(message),
      'CONNECTION_FAILED' => ConnectionFailedError(message),
      'CONNECTION_LOST' => ConnectionLostError(message),
      'CONNECTION_TIMEOUT' => ConnectionTimeoutError(message),
      'ALREADY_CONNECTED' => AlreadyConnectedError(message),
      'CANCELLED' => CancelledError(message),
      _ => UnknownError(message ?? error.toString()),
    };
  }
}
