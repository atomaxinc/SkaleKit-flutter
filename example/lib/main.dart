import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skale_kit/skale_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkaleKit Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const ScalePage(),
    );
  }
}

class ScalePage extends StatefulWidget {
  const ScalePage({super.key});

  @override
  State<ScalePage> createState() => _ScalePageState();
}

class _ScalePageState extends State<ScalePage> {
  late final SkaleKit _skaleKit;

  SkaleConnectionState _connectionState = SkaleConnectionState.disconnected;
  double _weight = 0.0;
  int _batteryLevel = 0;
  String? _errorMessage;

  StreamSubscription<double>? _weightSubscription;
  StreamSubscription<SkaleConnectionState>? _connectionStateSubscription;
  StreamSubscription<SkaleButton>? _buttonSubscription;

  @override
  void initState() {
    super.initState();
    _skaleKit = SkaleKit();
    _setupListeners();
  }

  void _setupListeners() {
    _weightSubscription = _skaleKit.weightStream.listen(
      (weight) {
        setState(() {
          _weight = weight;
        });
      },
      onError: (error) {
        _showError(error.toString());
      },
    );

    _connectionStateSubscription = _skaleKit.connectionStateStream.listen(
      (state) {
        setState(() {
          _connectionState = state;
          _errorMessage = null;
        });

        if (state == SkaleConnectionState.connected) {
          _fetchBatteryLevel();
        }
      },
      onError: (error) {
        _showError(error.toString());
      },
    );

    _buttonSubscription = _skaleKit.buttonStream.listen(
      (button) {
        final buttonName = button == SkaleButton.circle ? 'Circle' : 'Square';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$buttonName button pressed'),
            duration: const Duration(seconds: 1),
          ),
        );

        // Tare on circle button press
        if (button == SkaleButton.circle) {
          _skaleKit.tare();
        }
      },
    );
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _buttonSubscription?.cancel();
    _skaleKit.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final allGranted = statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );

      if (!allGranted) {
        _showError('Bluetooth permissions are required');
        return;
      }
    }
  }

  Future<void> _connect() async {
    try {
      await _requestPermissions();

      final hasPermissions = await _skaleKit.hasPermissions();
      if (!hasPermissions) {
        _showError('Bluetooth permissions are required');
        return;
      }

      final isEnabled = await _skaleKit.isBluetoothEnabled();
      if (!isEnabled) {
        _showError('Please enable Bluetooth');
        return;
      }

      // Show the native device picker
      await _skaleKit.showDevicePicker();
    } on SkaleError catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _disconnect() async {
    try {
      await _skaleKit.disconnect();
    } on SkaleError catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _tare() async {
    try {
      await _skaleKit.tare();
    } on SkaleError catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _fetchBatteryLevel() async {
    try {
      final level = await _skaleKit.getBatteryLevel();
      setState(() {
        _batteryLevel = level;
      });
    } on SkaleError catch (e) {
      debugPrint('Failed to get battery level: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkaleKit Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status
              _buildStatusCard(),
              const SizedBox(height: 24),

              // Weight Display
              _buildWeightDisplay(),
              const SizedBox(height: 24),

              // Control Buttons
              if (_connectionState == SkaleConnectionState.connected) ...[
                _buildControlButtons(),
                const SizedBox(height: 24),
              ],

              // Connect/Disconnect Button
              _buildConnectionButton(),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final (statusText, statusColor) = switch (_connectionState) {
      SkaleConnectionState.disconnected => ('Disconnected', Colors.grey),
      SkaleConnectionState.scanning => ('Scanning...', Colors.orange),
      SkaleConnectionState.connecting => ('Connecting...', Colors.orange),
      SkaleConnectionState.connected => ('Connected', Colors.green),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (_connectionState == SkaleConnectionState.connected &&
                _batteryLevel > 0)
              Row(
                children: [
                  Icon(
                    _batteryLevel > 20
                        ? Icons.battery_full
                        : Icons.battery_alert,
                    color: _batteryLevel > 20 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text('$_batteryLevel%'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightDisplay() {
    return Expanded(
      child: Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weight.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 72,
                    ),
              ),
              Text(
                'grams',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _tare,
            icon: const Icon(Icons.exposure_zero),
            label: const Text('Tare'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton.icon(
            onPressed: _fetchBatteryLevel,
            icon: const Icon(Icons.battery_unknown),
            label: const Text('Battery'),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionButton() {
    final isConnecting = _connectionState == SkaleConnectionState.scanning ||
        _connectionState == SkaleConnectionState.connecting;

    if (_connectionState == SkaleConnectionState.connected) {
      return OutlinedButton.icon(
        onPressed: _disconnect,
        icon: const Icon(Icons.bluetooth_disabled),
        label: const Text('Disconnect'),
      );
    }

    return FilledButton.icon(
      onPressed: isConnecting ? null : _connect,
      icon: isConnecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.bluetooth_searching),
      label: Text(isConnecting ? 'Connecting...' : 'Connect Scale'),
    );
  }
}
