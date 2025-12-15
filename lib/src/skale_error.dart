/// Base class for all SkaleKit errors.
sealed class SkaleError implements Exception {
  const SkaleError([this.message]);

  /// Optional error message with additional details.
  final String? message;

  @override
  String toString() {
    if (message != null) {
      return '$runtimeType: $message';
    }
    return runtimeType.toString();
  }
}

/// Bluetooth is disabled on the device.
class BluetoothDisabledError extends SkaleError {
  const BluetoothDisabledError([super.message]);
}

/// Required permissions were not granted.
class PermissionDeniedError extends SkaleError {
  const PermissionDeniedError([super.message]);
}

/// The requested device was not found.
class DeviceNotFoundError extends SkaleError {
  const DeviceNotFoundError([super.message]);
}

/// Failed to establish a connection to the device.
class ConnectionFailedError extends SkaleError {
  const ConnectionFailedError([super.message]);
}

/// The connection to the device was lost.
class ConnectionLostError extends SkaleError {
  const ConnectionLostError([super.message]);
}

/// Connection attempt timed out.
class ConnectionTimeoutError extends SkaleError {
  const ConnectionTimeoutError([super.message]);
}

/// Device is already connected.
class AlreadyConnectedError extends SkaleError {
  const AlreadyConnectedError([super.message]);
}

/// Operation was cancelled by the user.
class CancelledError extends SkaleError {
  const CancelledError([super.message]);
}

/// An unknown error occurred.
class UnknownError extends SkaleError {
  const UnknownError([super.message]);
}

/// Button identifiers for Skale device buttons.
enum SkaleButton {
  /// The circle button on the device.
  circle(1),

  /// The square button on the device.
  square(2);

  const SkaleButton(this.value);

  /// The numeric identifier for this button.
  final int value;

  /// Creates a [SkaleButton] from its numeric value.
  static SkaleButton? fromValue(int value) {
    return switch (value) {
      1 => SkaleButton.circle,
      2 => SkaleButton.square,
      _ => null,
    };
  }
}
