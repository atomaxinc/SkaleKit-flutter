import Flutter
import UIKit
import SkaleKit
import CoreBluetooth

public class SkaleKitPlugin: NSObject, FlutterPlugin, SKSkaleDelegate {

    private let skale = SKSkale()
    private var methodChannel: FlutterMethodChannel?
    private var weightEventSink: FlutterEventSink?
    private var connectionStateEventSink: FlutterEventSink?
    private var buttonEventSink: FlutterEventSink?
    private var deviceEventSink: FlutterEventSink?

    private var centralManager: CBCentralManager?
    private var discoveredDevices: [String: [String: Any]] = [:]
    private var isScanning = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SkaleKitPlugin()

        // Method channel
        let methodChannel = FlutterMethodChannel(
            name: "com.atomaxinc.skalekit/methods",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        instance.methodChannel = methodChannel

        // Weight event channel
        let weightChannel = FlutterEventChannel(
            name: "com.atomaxinc.skalekit/weight",
            binaryMessenger: registrar.messenger()
        )
        weightChannel.setStreamHandler(WeightStreamHandler(plugin: instance))

        // Connection state event channel
        let connectionStateChannel = FlutterEventChannel(
            name: "com.atomaxinc.skalekit/connectionState",
            binaryMessenger: registrar.messenger()
        )
        connectionStateChannel.setStreamHandler(ConnectionStateStreamHandler(plugin: instance))

        // Button event channel
        let buttonChannel = FlutterEventChannel(
            name: "com.atomaxinc.skalekit/button",
            binaryMessenger: registrar.messenger()
        )
        buttonChannel.setStreamHandler(ButtonStreamHandler(plugin: instance))

        // Device discovery event channel
        let deviceChannel = FlutterEventChannel(
            name: "com.atomaxinc.skalekit/devices",
            binaryMessenger: registrar.messenger()
        )
        deviceChannel.setStreamHandler(DeviceStreamHandler(plugin: instance))

        instance.skale.delegate = instance
        instance.skale.isAutoConnectEnabled = false
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isConnected":
            result(skale.isConnected)

        case "isBluetoothEnabled":
            if centralManager == nil {
                centralManager = CBCentralManager(delegate: nil, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
            }
            result(centralManager?.state == .poweredOn)

        case "hasPermissions":
            if #available(iOS 13.1, *) {
                let authorization = CBCentralManager.authorization
                result(authorization == .allowedAlways || authorization == .restricted)
            } else {
                result(true)
            }

        case "requestPermissions":
            // On iOS, permissions are requested automatically when CBCentralManager is created
            if centralManager == nil {
                centralManager = CBCentralManager(delegate: nil, queue: nil)
            }
            if #available(iOS 13.1, *) {
                let authorization = CBCentralManager.authorization
                result(authorization == .allowedAlways || authorization == .restricted)
            } else {
                result(true)
            }

        case "startScan":
            startScanning(result: result)

        case "stopScan":
            stopScanning()
            result(nil)

        case "showDevicePicker":
            showDevicePicker(result: result)

        case "connect":
            if let args = call.arguments as? [String: Any],
               let deviceId = args["id"] as? String {
                connect(deviceId: deviceId, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device ID is required", details: nil))
            }

        case "disconnect":
            skale.disconnect()
            result(nil)

        case "tare":
            skale.tare()
            result(nil)

        case "getBatteryLevel":
            skale.readBatteryLife { level in
                result(Int(level))
            }

        case "setLEDDisplay":
            if let args = call.arguments as? [String: Any],
               let isOn = args["isOn"] as? Bool {
                skale.setLEDDisplayOn(isOn)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "isOn parameter is required", details: nil))
            }

        case "setAutoConnect":
            if let args = call.arguments as? [String: Any],
               let enabled = args["enabled"] as? Bool {
                skale.isAutoConnectEnabled = enabled
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "enabled parameter is required", details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Scanning

    private func startScanning(result: @escaping FlutterResult) {
        guard let manager = centralManager, manager.state == .poweredOn else {
            if centralManager == nil {
                centralManager = CBCentralManager(delegate: nil, queue: nil)
            }
            result(FlutterError(code: "BLUETOOTH_DISABLED", message: "Bluetooth is not enabled", details: nil))
            return
        }

        discoveredDevices.removeAll()
        isScanning = true
        connectionStateEventSink?("SCANNING")

        // Note: The actual scanning is handled by the native SDK
        // This is a placeholder for custom scanning if needed
        result(nil)
    }

    private func stopScanning() {
        isScanning = false
    }

    // MARK: - Device Picker

    private func showDevicePicker(result: @escaping FlutterResult) {
        // Must run on main thread for UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                result(FlutterError(code: "PLUGIN_ERROR", message: "Plugin instance deallocated", details: nil))
                return
            }

            guard let topController = self.getTopViewController() else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
                return
            }

            self.connectionStateEventSink?("SCANNING")

            self.skale.showDevicePicker(onViewContoller: topController) { [weak self] error in
                if let error = error {
                    let nsError = error as NSError
                    let flutterError = self?.mapNSErrorToFlutterError(nsError)
                    result(flutterError)
                } else {
                    // Connection will be handled by delegate methods
                    // Return nil to indicate picker was shown successfully
                    result(nil)
                }
            }
        }
    }

    private func getTopViewController() -> UIViewController? {
        var rootViewController: UIViewController?

        if #available(iOS 13.0, *) {
            // iOS 13+ use scene-based approach
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            rootViewController = windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        } else {
            rootViewController = UIApplication.shared.keyWindow?.rootViewController
        }

        guard var topController = rootViewController else {
            return nil
        }

        // Find the topmost presented view controller
        while let presented = topController.presentedViewController {
            topController = presented
        }

        return topController
    }

    private func connect(deviceId: String, result: @escaping FlutterResult) {
        // The native SDK uses the device picker for connection
        // Direct connection by ID is not supported in the current API
        // We'll use the device picker flow instead
        result(FlutterError(code: "NOT_SUPPORTED", message: "Direct connection by ID is not supported. Use showDevicePicker instead.", details: nil))
    }

    // MARK: - SKSkaleDelegate

    public func skaleDidConnected(_ skale: SKSkale) {
        connectionStateEventSink?("CONNECTED")
    }

    public func skaleDidDisconnected(_ skale: SKSkale) {
        connectionStateEventSink?("DISCONNECTED")
    }

    public func skale(_ skale: SKSkale, didErrorOccur error: Error) {
        let nsError = error as NSError
        connectionStateEventSink?(FlutterError(
            code: mapErrorCode(nsError.code),
            message: nsError.localizedDescription,
            details: nil
        ))
    }

    public func skaleWeightDidUpdate(_ weight: Float) {
        weightEventSink?(Double(weight))
    }

    public func skaleDeviceDidClickButton(_ buttonIndex: UInt) {
        buttonEventSink?(Int(buttonIndex))
    }

    // MARK: - Error Mapping

    private func mapNSErrorToFlutterError(_ error: NSError) -> FlutterError {
        let code = mapErrorCode(error.code)
        return FlutterError(code: code, message: error.localizedDescription, details: nil)
    }

    private func mapErrorCode(_ code: Int) -> String {
        switch code {
        case 100: // SKErrorLECancel
            return "CANCELLED"
        case 101: // SKErrorLENotAvailable
            return "BLUETOOTH_DISABLED"
        case 102: // SKErrorLEDeviceAlreadyConnected
            return "ALREADY_CONNECTED"
        case 103: // SKErrorLEConnectionUnknown
            return "CONNECTION_FAILED"
        case 104: // SKErrorLEConnectionInvalidParameters
            return "CONNECTION_FAILED"
        case 105: // SKErrorLEConnectionInvalidHandle
            return "CONNECTION_FAILED"
        case 106: // SKErrorLEConnectionTimeout
            return "CONNECTION_TIMEOUT"
        case 107: // SKErrorLEValidation
            return "CONNECTION_FAILED"
        case 108: // SKErrorLEInvalidDevice
            return "DEVICE_NOT_FOUND"
        case 109: // SKErrorLEAccess
            return "PERMISSION_DENIED"
        default:
            return "UNKNOWN"
        }
    }

    // MARK: - Event Sink Setters

    func setWeightEventSink(_ sink: FlutterEventSink?) {
        weightEventSink = sink
    }

    func setConnectionStateEventSink(_ sink: FlutterEventSink?) {
        connectionStateEventSink = sink
    }

    func setButtonEventSink(_ sink: FlutterEventSink?) {
        buttonEventSink = sink
    }

    func setDeviceEventSink(_ sink: FlutterEventSink?) {
        deviceEventSink = sink
    }
}

// MARK: - Stream Handlers

class WeightStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: SkaleKitPlugin?

    init(plugin: SkaleKitPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setWeightEventSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setWeightEventSink(nil)
        return nil
    }
}

class ConnectionStateStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: SkaleKitPlugin?

    init(plugin: SkaleKitPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setConnectionStateEventSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setConnectionStateEventSink(nil)
        return nil
    }
}

class ButtonStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: SkaleKitPlugin?

    init(plugin: SkaleKitPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setButtonEventSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setButtonEventSink(nil)
        return nil
    }
}

class DeviceStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: SkaleKitPlugin?

    init(plugin: SkaleKitPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setDeviceEventSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setDeviceEventSink(nil)
        return nil
    }
}
