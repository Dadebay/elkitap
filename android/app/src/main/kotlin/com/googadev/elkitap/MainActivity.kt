package com.googadev.elkitap

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.googadev.elkitap/bluetooth_audio"
    private var bluetoothAudioHelper: BluetoothAudioHelper? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        bluetoothAudioHelper = BluetoothAudioHelper(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "disconnectAudioDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        val success = bluetoothAudioHelper?.disconnectAudioDevice(address) ?: false
                        Log.d("MainActivity", "disconnectAudioDevice($address) = $success")
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Address is required", null)
                    }
                }
                "connectAudioDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        val success = bluetoothAudioHelper?.connectAudioDevice(address) ?: false
                        Log.d("MainActivity", "connectAudioDevice($address) = $success")
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Address is required", null)
                    }
                }
                "isAudioDeviceConnected" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        val connected = bluetoothAudioHelper?.isAudioDeviceConnected(address) ?: false
                        result.success(connected)
                    } else {
                        result.error("INVALID_ARGUMENT", "Address is required", null)
                    }
                }
                "getConnectedAudioDevices" -> {
                    val devices = bluetoothAudioHelper?.getConnectedAudioDevices() ?: emptyList()
                    result.success(devices)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        bluetoothAudioHelper?.cleanup()
        super.onDestroy()
    }
}
