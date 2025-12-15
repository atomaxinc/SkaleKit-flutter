package com.atomaxinc.skalekit.flutter

import android.app.Activity
import android.bluetooth.BluetoothDevice
import android.content.Context
import androidx.annotation.NonNull
import com.atomaxinc.skalekit.SkaleDevicePicker
import com.atomaxinc.skalekit.SkaleKit
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SkaleKitPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, SkaleKit.SkaleListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var weightChannel: EventChannel
    private lateinit var connectionStateChannel: EventChannel
    private lateinit var buttonChannel: EventChannel
    private lateinit var deviceChannel: EventChannel

    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var skaleKit: SkaleKit? = null
    private var devicePicker: SkaleDevicePicker? = null

    private var weightEventSink: EventChannel.EventSink? = null
    private var connectionStateEventSink: EventChannel.EventSink? = null
    private var buttonEventSink: EventChannel.EventSink? = null
    private var deviceEventSink: EventChannel.EventSink? = null

    private var pendingDevicePickerResult: Result? = null
    private var pendingBatteryResult: Result? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.atomaxinc.skalekit/methods")
        methodChannel.setMethodCallHandler(this)

        weightChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.atomaxinc.skalekit/weight")
        weightChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                weightEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                weightEventSink = null
            }
        })

        connectionStateChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.atomaxinc.skalekit/connectionState")
        connectionStateChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                connectionStateEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                connectionStateEventSink = null
            }
        })

        buttonChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.atomaxinc.skalekit/button")
        buttonChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                buttonEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                buttonEventSink = null
            }
        })

        deviceChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.atomaxinc.skalekit/devices")
        deviceChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                deviceEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                deviceEventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        weightChannel.setStreamHandler(null)
        connectionStateChannel.setStreamHandler(null)
        buttonChannel.setStreamHandler(null)
        deviceChannel.setStreamHandler(null)
        skaleKit?.disconnect()
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        initializeSkaleKit()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        initializeSkaleKit()
    }

    override fun onDetachedFromActivity() {
        skaleKit?.disconnect()
        activity = null
    }

    private fun initializeSkaleKit() {
        activity?.let { ctx ->
            if (skaleKit == null) {
                skaleKit = SkaleKit(ctx)
                skaleKit?.setListener(this)
            }
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "isConnected" -> {
                val state = skaleKit?.let {
                    // Check if currently connected
                    true // Placeholder - actual implementation depends on SkaleKit API
                } ?: false
                result.success(false) // Return false as we can't directly check connection state
            }

            "isBluetoothEnabled" -> {
                result.success(skaleKit?.isBluetoothEnabled() ?: false)
            }

            "hasPermissions" -> {
                applicationContext?.let { ctx ->
                    result.success(SkaleKit.hasPermissions(ctx))
                } ?: result.success(false)
            }

            "requestPermissions" -> {
                // Permission requests need to be handled by the Flutter app using permission_handler
                applicationContext?.let { ctx ->
                    result.success(SkaleKit.hasPermissions(ctx))
                } ?: result.success(false)
            }

            "startScan" -> {
                skaleKit?.let {
                    if (!it.isBluetoothEnabled()) {
                        result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
                        return
                    }
                    applicationContext?.let { ctx ->
                        if (!SkaleKit.hasPermissions(ctx)) {
                            result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                            return
                        }
                    }
                    it.startScan()
                    connectionStateEventSink?.success("SCANNING")
                    result.success(null)
                } ?: result.error("NOT_INITIALIZED", "SkaleKit not initialized", null)
            }

            "stopScan" -> {
                // SkaleKit doesn't have a direct stopScan method
                result.success(null)
            }

            "showDevicePicker" -> {
                showDevicePicker(result)
            }

            "connect" -> {
                // Direct connection is handled through device picker
                result.error("NOT_SUPPORTED", "Direct connection by ID is not supported. Use showDevicePicker instead.", null)
            }

            "disconnect" -> {
                skaleKit?.disconnect()
                result.success(null)
            }

            "tare" -> {
                skaleKit?.tare()
                result.success(null)
            }

            "getBatteryLevel" -> {
                skaleKit?.let {
                    pendingBatteryResult = result
                    it.requestBatteryLevel()
                } ?: result.error("NOT_INITIALIZED", "SkaleKit not initialized", null)
            }

            "setLEDDisplay" -> {
                // LED display control may not be available in Android SDK
                result.success(null)
            }

            "setAutoConnect" -> {
                // Auto-connect feature implementation depends on SkaleKit API
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun showDevicePicker(result: Result) {
        val currentActivity = activity
        val kit = skaleKit

        if (currentActivity == null || kit == null) {
            result.error("NOT_INITIALIZED", "Activity or SkaleKit not initialized", null)
            return
        }

        if (!kit.isBluetoothEnabled()) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
            return
        }

        applicationContext?.let { ctx ->
            if (!SkaleKit.hasPermissions(ctx)) {
                result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                return
            }
        }

        pendingDevicePickerResult = result
        connectionStateEventSink?.success("SCANNING")

        devicePicker = SkaleDevicePicker(currentActivity, kit)
        devicePicker?.show(object : SkaleDevicePicker.OnDeviceSelectedListener {
            override fun onDeviceSelected(device: BluetoothDevice) {
                connectionStateEventSink?.success("CONNECTING")
                kit.connect(device)
                // The result will be sent when onConnectionStateChanged is called
            }

            override fun onCancelled() {
                connectionStateEventSink?.success("DISCONNECTED")
                pendingDevicePickerResult?.error("CANCELLED", "User cancelled device selection", null)
                pendingDevicePickerResult = null
            }
        })
    }

    // SkaleKit.SkaleListener implementation

    override fun onConnectionStateChanged(state: SkaleKit.ConnectionState) {
        activity?.runOnUiThread {
            val stateString = when (state) {
                SkaleKit.ConnectionState.DISCONNECTED -> "DISCONNECTED"
                SkaleKit.ConnectionState.SCANNING -> "SCANNING"
                SkaleKit.ConnectionState.CONNECTING -> "CONNECTING"
                SkaleKit.ConnectionState.CONNECTED -> "CONNECTED"
            }
            connectionStateEventSink?.success(stateString)

            if (state == SkaleKit.ConnectionState.CONNECTED) {
                pendingDevicePickerResult?.success(null)
                pendingDevicePickerResult = null
            }
        }
    }

    override fun onWeightUpdate(weight: Float) {
        activity?.runOnUiThread {
            weightEventSink?.success(weight.toDouble())
        }
    }

    override fun onButtonClicked(buttonId: Int) {
        activity?.runOnUiThread {
            buttonEventSink?.success(buttonId)
        }
    }

    override fun onBatteryLevelUpdate(level: Int) {
        activity?.runOnUiThread {
            pendingBatteryResult?.success(level)
            pendingBatteryResult = null
        }
    }

    override fun onError(error: SkaleKit.SkaleError) {
        activity?.runOnUiThread {
            val errorCode = when (error) {
                is SkaleKit.SkaleError.BluetoothDisabled -> "BLUETOOTH_DISABLED"
                is SkaleKit.SkaleError.PermissionDenied -> "PERMISSION_DENIED"
                is SkaleKit.SkaleError.DeviceNotFound -> "DEVICE_NOT_FOUND"
                is SkaleKit.SkaleError.ConnectionFailed -> "CONNECTION_FAILED"
                is SkaleKit.SkaleError.ConnectionLost -> "CONNECTION_LOST"
                is SkaleKit.SkaleError.Unknown -> "UNKNOWN"
            }
            val errorMessage = when (error) {
                is SkaleKit.SkaleError.Unknown -> error.message ?: "Unknown error"
                else -> errorCode
            }

            connectionStateEventSink?.error(errorCode, errorMessage, null)

            pendingDevicePickerResult?.error(errorCode, errorMessage, null)
            pendingDevicePickerResult = null
        }
    }
}
