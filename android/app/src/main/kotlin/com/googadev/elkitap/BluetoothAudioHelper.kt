package com.googadev.elkitap

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothHeadset
import android.content.Context
import android.os.Build
import android.util.Log
import java.lang.reflect.Method

class BluetoothAudioHelper(private val context: Context) {

    companion object {
        private const val TAG = "BluetoothAudioHelper"
    }

    private var a2dpProfile: BluetoothA2dp? = null
    private var headsetProfile: BluetoothHeadset? = null
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    private var a2dpReady = false
    private var headsetReady = false

    init {
        setupProxies()
    }

    private fun setupProxies() {
        bluetoothAdapter?.let { adapter ->
            // Get A2DP proxy
            adapter.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                    if (profile == BluetoothProfile.A2DP) {
                        a2dpProfile = proxy as? BluetoothA2dp
                        a2dpReady = true
                        Log.d(TAG, "A2DP proxy connected")
                    }
                }
                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.A2DP) {
                        a2dpProfile = null
                        a2dpReady = false
                        Log.d(TAG, "A2DP proxy disconnected")
                    }
                }
            }, BluetoothProfile.A2DP)

            // Get Headset proxy
            adapter.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                    if (profile == BluetoothProfile.HEADSET) {
                        headsetProfile = proxy as? BluetoothHeadset
                        headsetReady = true
                        Log.d(TAG, "Headset proxy connected")
                    }
                }
                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.HEADSET) {
                        headsetProfile = null
                        headsetReady = false
                        Log.d(TAG, "Headset proxy disconnected")
                    }
                }
            }, BluetoothProfile.HEADSET)
        }
    }

    fun disconnectAudioDevice(address: String): Boolean {
        Log.d(TAG, "Attempting to disconnect audio device: $address")

        val device = bluetoothAdapter?.getRemoteDevice(address) ?: run {
            Log.e(TAG, "Device not found: $address")
            return false
        }

        var disconnected = false

        // Disconnect A2DP
        a2dpProfile?.let { a2dp ->
            try {
                val method: Method = BluetoothA2dp::class.java.getMethod("disconnect", BluetoothDevice::class.java)
                val result = method.invoke(a2dp, device) as Boolean
                Log.d(TAG, "A2DP disconnect result: $result")
                if (result) disconnected = true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to disconnect A2DP: ${e.message}")
            }
        }

        // Disconnect Headset/HFP
        headsetProfile?.let { headset ->
            try {
                val method: Method = BluetoothHeadset::class.java.getMethod("disconnect", BluetoothDevice::class.java)
                val result = method.invoke(headset, device) as Boolean
                Log.d(TAG, "Headset disconnect result: $result")
                if (result) disconnected = true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to disconnect Headset: ${e.message}")
            }
        }

        return disconnected
    }

    fun connectAudioDevice(address: String): Boolean {
        Log.d(TAG, "Attempting to connect audio device: $address")

        val device = bluetoothAdapter?.getRemoteDevice(address) ?: run {
            Log.e(TAG, "Device not found: $address")
            return false
        }

        var connected = false

        // Connect A2DP
        a2dpProfile?.let { a2dp ->
            try {
                val method: Method = BluetoothA2dp::class.java.getMethod("connect", BluetoothDevice::class.java)
                val result = method.invoke(a2dp, device) as Boolean
                Log.d(TAG, "A2DP connect result: $result")
                if (result) connected = true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to connect A2DP: ${e.message}")
            }
        }

        // Connect Headset/HFP
        headsetProfile?.let { headset ->
            try {
                val method: Method = BluetoothHeadset::class.java.getMethod("connect", BluetoothDevice::class.java)
                val result = method.invoke(headset, device) as Boolean
                Log.d(TAG, "Headset connect result: $result")
                if (result) connected = true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to connect Headset: ${e.message}")
            }
        }

        return connected
    }

    fun isAudioDeviceConnected(address: String): Boolean {
        val device = bluetoothAdapter?.getRemoteDevice(address) ?: return false

        // Check A2DP connection
        a2dpProfile?.let { a2dp ->
            val connectedDevices = a2dp.connectedDevices
            if (connectedDevices.any { it.address == address }) {
                Log.d(TAG, "Device $address is connected via A2DP")
                return true
            }
        }

        // Check Headset connection
        headsetProfile?.let { headset ->
            val connectedDevices = headset.connectedDevices
            if (connectedDevices.any { it.address == address }) {
                Log.d(TAG, "Device $address is connected via Headset")
                return true
            }
        }

        return false
    }

    fun getConnectedAudioDevices(): List<Map<String, String>> {
        val devices = mutableListOf<Map<String, String>>()
        val addedAddresses = mutableSetOf<String>()

        // A2DP connected devices
        a2dpProfile?.let { a2dp ->
            for (device in a2dp.connectedDevices) {
                if (addedAddresses.add(device.address)) {
                    devices.add(mapOf(
                        "name" to (device.name ?: "Unknown"),
                        "address" to device.address,
                        "profile" to "A2DP"
                    ))
                }
            }
        }

        // Headset connected devices
        headsetProfile?.let { headset ->
            for (device in headset.connectedDevices) {
                if (addedAddresses.add(device.address)) {
                    devices.add(mapOf(
                        "name" to (device.name ?: "Unknown"),
                        "address" to device.address,
                        "profile" to "Headset"
                    ))
                }
            }
        }

        Log.d(TAG, "Connected audio devices: ${devices.size}")
        return devices
    }

    fun cleanup() {
        bluetoothAdapter?.let { adapter ->
            a2dpProfile?.let { adapter.closeProfileProxy(BluetoothProfile.A2DP, it) }
            headsetProfile?.let { adapter.closeProfileProxy(BluetoothProfile.HEADSET, it) }
        }
        a2dpProfile = null
        headsetProfile = null
    }
}
