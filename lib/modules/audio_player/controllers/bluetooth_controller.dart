// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  final RxList<BluetoothDevice> scannedDevices = <BluetoothDevice>[].obs;
  final RxList<BluetoothDevice> bondedDevices = <BluetoothDevice>[].obs;
  final Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  final Rx<BluetoothDevice?> activeAudioDevice = Rx<BluetoothDevice?>(null);
  // iOS: maps device address → isBluetooth (false = built-in/AirPlay/wired)
  final Map<String, bool> iosDeviceProfiles = {};
  final RxBool isScanning = false.obs;
  final RxBool isBluetoothOn = false.obs;

  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  StreamSubscription<BluetoothState>? _stateSubscription;
  BluetoothConnection? _connection;
  final _storage = GetStorage();
  static const String _activeDeviceKey = 'active_audio_device_address';

  // Native audio channel for A2DP/HFP profile management
  static const _audioChannel = MethodChannel('com.googadev.elkitap/bluetooth_audio');

  /// iOS: Show the native system audio route picker (AirPlay/Bluetooth device selector)
  Future<void> showIOSAudioRoutePicker() async {
    try {
      print('[BT] 🍎 Showing iOS system audio route picker...');
      await _audioChannel.invokeMethod('showSystemAudioRoutePicker');
    } catch (e) {
      print('[BT] ❌ Error showing iOS audio route picker: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initBluetooth();
  }

  @override
  void onClose() {
    _discoverySubscription?.cancel();
    _stateSubscription?.cancel();
    _connection?.dispose();
    super.onClose();
  }

  Future<void> _initBluetooth() async {
    print('[BT] 🚀 === _initBluetooth START ===');

    try {
      if (Platform.isIOS) {
        // iOS: Use native MethodChannel to detect connected audio devices
        print('[BT] 🍎 iOS detected - using native audio route detection');
        isBluetoothOn.value = true; // iOS manages BT state itself
        await _loadIOSAudioDevices();
        print('[BT] 🚀 === _initBluetooth END (iOS) ===');
        return;
      }

      // Android: Use flutter_bluetooth_serial
      _stateSubscription = FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
        print('[BT] 📡 Bluetooth state changed: $state');
        isBluetoothOn.value = state == BluetoothState.STATE_ON;

        if (state == BluetoothState.STATE_ON) {
          print('[BT] ✅ Bluetooth turned ON - loading bonded devices...');
          getBondedDevices();
        } else {
          print('[BT] ❌ Bluetooth turned OFF');
        }
      });

      // Get current Bluetooth state
      print('[BT] 🔍 Checking current Bluetooth state...');
      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      print('[BT] 📡 Bluetooth is ${isEnabled == true ? "ON" : "OFF"}');
      isBluetoothOn.value = isEnabled ?? false;

      if (isBluetoothOn.value) {
        print('[BT] ✅ Bluetooth is ON - loading bonded devices...');
        await getBondedDevices();
      } else {
        print('[BT] ❌ Bluetooth is OFF on init');
      }

      print('[BT] 🚀 === _initBluetooth END ===');
    } catch (e, stackTrace) {
      print('[BT] ❌ Error initializing Bluetooth: $e');
      print('[BT] Stack trace: $stackTrace');
    }
  }

  /// iOS: Load connected audio devices via native MethodChannel
  Future<void> _loadIOSAudioDevices() async {
    try {
      print('[BT] 🍎 Loading iOS audio devices...');
      final List<dynamic> devices = await _audioChannel.invokeMethod('getConnectedAudioDevices');
      print('[BT] 🍎 Found ${devices.length} audio output device(s)');

      bondedDevices.clear();
      iosDeviceProfiles.clear();

      for (var deviceMap in devices) {
        final name = deviceMap['name'] as String? ?? 'Unknown';
        final address = deviceMap['address'] as String? ?? '';
        final profile = deviceMap['profile'] as String? ?? '';
        final isBluetooth = (deviceMap['isBluetooth'] as String? ?? 'false') == 'true';
        print('[BT] 🍎   - $name ($address) [$profile] isBT=$isBluetooth');

        iosDeviceProfiles[address] = isBluetooth;

        final device = BluetoothDevice(
          name: name,
          address: address,
          type: BluetoothDeviceType.unknown,
          bondState: BluetoothBondState.bonded,
        );
        bondedDevices.add(device);
      }

      // Always show the current system route as the active device
      if (bondedDevices.isNotEmpty) {
        activeAudioDevice.value = bondedDevices.first;
        print('[BT] 🍎 Active audio output: ${bondedDevices.first.name}');
      } else {
        activeAudioDevice.value = null;
        print('[BT] 🍎 No audio output route detected');
      }
    } catch (e) {
      print('[BT] ❌ Error loading iOS audio devices: $e');
    }
  }

  Future<bool> requestPermissions() async {
    print('[BT] 🔐 Requesting Bluetooth permissions...');

    if (Platform.isAndroid) {
      // Get Android SDK version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      print('[BT] 📱 Android SDK: $sdkInt');

      List<Permission> permissionsToRequest = [];

      if (sdkInt >= 31) {
        // Android 12+ (API 31+): Use new Bluetooth permissions
        permissionsToRequest = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];
      } else {
        // Android 11 and below: Use legacy Bluetooth + Location
        permissionsToRequest = [
          Permission.bluetooth,
          Permission.location,
        ];
      }

      // Check current status
      print('[BT] 📋 Current permissions:');
      for (var permission in permissionsToRequest) {
        final status = await permission.status;
        print('[BT]   - $permission: $status');
      }

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

      print('[BT] 📋 After request:');
      statuses.forEach((permission, status) {
        print('[BT]   - $permission: $status');
      });

      final allGranted = statuses.values.every((status) => status.isGranted);
      print('[BT] ${allGranted ? "✅" : "❌"} All permissions granted: $allGranted');
      return allGranted;
    } else if (Platform.isIOS) {
      // iOS: Request Bluetooth permission
      final btStatus = await Permission.bluetooth.status;
      print('[BT] 🍎 Bluetooth permission: $btStatus');
      if (!btStatus.isGranted) {
        final result = await Permission.bluetooth.request();
        return result.isGranted;
      }
      return true;
    }
    print('[BT] ❌ Unknown platform');
    return false;
  }

  Future<void> getBondedDevices() async {
    print('[BT] 🔍 === getBondedDevices START ===');

    try {
      if (Platform.isIOS) {
        // iOS: Reload from native
        await _loadIOSAudioDevices();
        print('[BT] 🔍 === getBondedDevices END (iOS) ===');
        return;
      }

      // Android: Check permissions first
      if (Platform.isAndroid) {
        final connectStatus = await Permission.bluetoothConnect.status;
        print('[BT] 🔐 bluetoothConnect permission: $connectStatus');

        if (!connectStatus.isGranted) {
          print('[BT] ⚠️ bluetoothConnect permission NOT granted');
          return;
        }
      }

      print('[BT] 📞 Calling FlutterBluetoothSerial.instance.getBondedDevices()...');
      final List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();

      print('[BT] 📊 getBondedDevices() returned ${devices.length} devices');

      if (devices.isEmpty) {
        print('[BT] ❌ No bonded devices found');
        print('[BT] 💡 To see devices here:');
        print('[BT]    1. Open Android Settings -> Bluetooth');
        print('[BT]    2. Make sure your device (e.g., AirPods) is paired');
        print('[BT]    3. Device should appear in "Paired devices" list');
        bondedDevices.clear();
      } else {
        for (int i = 0; i < devices.length; i++) {
          final device = devices[i];
          print('[BT] 📱 Device [$i]: ${device.name ?? "<no name>"}');
          print('[BT]    - Address: ${device.address}');
          print('[BT]    - Type: ${device.type}');
          print('[BT]    - isBonded: ${device.isBonded}');
        }

        bondedDevices.value = devices;
        print('[BT] ✅ Loaded ${devices.length} bonded devices into bondedDevices list');

        // Restore active audio device if saved
        await _loadActiveAudioDevice();

        // Validate current connection - if connected device is not in bonded list or connection is null, clear it
        if (connectedDevice.value != null) {
          final stillBonded = devices.any((d) => d.address == connectedDevice.value!.address);
          final connectionValid = _connection != null && _connection!.isConnected;

          if (!stillBonded || !connectionValid) {
            print('[BT] ⚠️ Connected device no longer valid - clearing connection');
            print('[BT]    - Still bonded: $stillBonded');
            print('[BT]    - Connection valid: $connectionValid');
            connectedDevice.value = null;
            _connection?.close();
            _connection = null;
          }
        }
      }

      print('[BT] 🔍 === getBondedDevices END ===');
    } catch (e, stackTrace) {
      print('[BT] ❌ Error getting bonded devices: $e');
      print('[BT] Stack trace: $stackTrace');
    }
  }

  Future<void> startScan() async {
    print('[BT] 🔄 === startScan START ===');

    if (Platform.isIOS) {
      // iOS: Just reload the audio devices
      print('[BT] 🍎 iOS - refreshing audio devices...');
      isScanning.value = true;
      await _loadIOSAudioDevices();
      isScanning.value = false;
      print('[BT] 🔄 === startScan END (iOS) ===');
      return;
    }

    // Request permissions FIRST (before checking Bluetooth state)
    print('[BT] 🔐 Checking permissions FIRST...');
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      print('[BT] ❌ Permissions NOT granted');
      AppSnackbar.error('bluetooth_scan_permission'.tr, title: 'permission_denied'.tr);
      return;
    }
    print('[BT] ✅ Permissions granted');

    if (!isBluetoothOn.value) {
      print('[BT] ❌ Bluetooth is OFF - requesting to enable...');
      try {
        final result = await FlutterBluetoothSerial.instance.requestEnable();
        if (result != true) {
          print('[BT] ❌ User denied Bluetooth enable request');
          AppSnackbar.warning('turn_on_bluetooth'.tr, title: 'bluetooth_off'.tr);
          return;
        }
        print('[BT] ✅ Bluetooth enabled by user');
        isBluetoothOn.value = true;
      } catch (e) {
        print('[BT] ❌ Error enabling Bluetooth: $e');
        AppSnackbar.warning('turn_on_bluetooth'.tr, title: 'bluetooth_off'.tr);
        return;
      }
    }
    print('[BT] ✅ Bluetooth is ON');

    try {
      print('[BT] 🗑️ Clearing scannedDevices list');
      scannedDevices.clear();

      // Load bonded devices first
      print('[BT] 🔍 Loading bonded devices...');
      await getBondedDevices();

      // Start discovery
      print('[BT] 📡 Starting Bluetooth discovery...');
      isScanning.value = true;

      _discoverySubscription?.cancel();
      _discoverySubscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
        (result) {
          print('[BT] 📱 Discovered device: ${result.device.name ?? "<no name>"} (${result.device.address})');
          print('[BT]    - RSSI: ${result.rssi}');
          print('[BT]    - Type: ${result.device.type}');
          print('[BT]    - isBonded: ${result.device.isBonded}');

          final index = scannedDevices.indexWhere((d) => d.address == result.device.address);
          if (index != -1) {
            scannedDevices[index] = result.device;
          } else {
            scannedDevices.add(result.device);
            print('[BT] ➕ Added to scannedDevices list (total: ${scannedDevices.length})');
          }
        },
        onDone: () {
          print('[BT] 🏁 Discovery completed');
          isScanning.value = false;
        },
        onError: (error) {
          print('[BT] ❌ Discovery error: $error');
          isScanning.value = false;
        },
      );

      print('[BT] ⏳ Discovery started, waiting for results...');
      print('[BT] 🔄 === startScan END ===');
    } catch (e, stackTrace) {
      print('[BT] ❌ Error during scan: $e');
      print('[BT] Stack trace: $stackTrace');
      isScanning.value = false;
    }
  }

  Future<void> stopScan() async {
    print('[BT] 🛑 Stopping scan...');
    try {
      if (Platform.isIOS) {
        isScanning.value = false;
        print('[BT] ✅ Scan stopped (iOS)');
        return;
      }
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      isScanning.value = false;
      print('[BT] ✅ Scan stopped');
    } catch (e) {
      print('[BT] ❌ Error stopping scan: $e');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    print('[BT] 🔗 === connectToDevice START ===');
    print('[BT] 📱 Device: ${device.name ?? "<no name>"} (${device.address})');

    try {
      await stopScan();

      // Disconnect existing connection if any
      if (activeAudioDevice.value != null || ((_connection != null) && _connection!.isConnected)) {
        print('[BT] 🔄 Disconnecting existing connection...');
        await disconnectDevice();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (Platform.isIOS) {
        // iOS: Connect via native audio routing
        print('[BT] 🍎 iOS: Connecting via native audio routing...');
        final nativeConnected = await _connectAudioNative(device.address);

        if (nativeConnected) {
          print('[BT] ✅ iOS native audio connection successful!');
          activeAudioDevice.value = device;
          await _saveActiveAudioDevice(device.address);
          bondedDevices.refresh();

          AppSnackbar.success(
            'connected_to'.trParams({'device': device.name ?? 'unknown_device_t'.tr}),
            title: 'audio_device'.tr,
            duration: const Duration(seconds: 3),
          );
        } else {
          print('[BT] ❌ iOS native connect failed');
          AppSnackbar.info(
            'audio_device_paired_msg'.trParams({'device': device.name ?? 'unknown_device_t'.tr}),
            title: 'audio_device'.tr,
            duration: const Duration(seconds: 3),
          );
        }
        print('[BT] 🔗 === connectToDevice END (iOS) ===');
        return;
      }

      // Android: Try SPP first, then native A2DP/HFP
      print('[BT] 🔗 Attempting to connect...');
      print('[BT] 💡 Note: For audio devices like AirPods, this creates a data connection');
      print('[BT] 💡 Audio routing is handled by Android system automatically');

      try {
        _connection = await BluetoothConnection.toAddress(device.address);

        if (_connection != null && _connection!.isConnected) {
          print('[BT] ✅ Connected successfully!');
          connectedDevice.value = device;
          // Clear active audio device since we have a real data connection
          activeAudioDevice.value = null;
          await _saveActiveAudioDevice(null);

          // Listen to connection done (disconnection)
          _connection!.input!.listen(
            (_) {},
            onDone: () {
              print('[BT] 🔌 Connection closed');
              if (connectedDevice.value?.address == device.address) {
                connectedDevice.value = null;
                _connection = null;
              }
            },
            onError: (error) {
              print('[BT] ❌ Connection error: $error');
              if (connectedDevice.value?.address == device.address) {
                connectedDevice.value = null;
                _connection = null;
              }
            },
          );

          AppSnackbar.success(
            'connected_to'.trParams({'device': device.name?.isNotEmpty == true ? device.name! : 'unknown_device_t'.tr}),
            title: 'connected'.tr,
          );
        } else {
          throw Exception('Connection object is null or not connected');
        }
      } on Exception catch (e) {
        print('[BT] ❌ Connection failed: $e');

        // For audio devices, connection might fail but they're still usable for audio
        // Since flutter_bluetooth_serial creates data connections, audio devices might refuse
        print('[BT] 💡 This might be an audio-only device (like AirPods)');
        print('[BT] 💡 Trying native A2DP/HFP connection...');

        // Try native A2DP/HFP connect
        final nativeConnected = await _connectAudioNative(device.address);

        if (nativeConnected) {
          print('[BT] ✅ Native audio connection successful!');
          activeAudioDevice.value = device;
          await _saveActiveAudioDevice(device.address);

          AppSnackbar.success(
            'connected_to'.trParams({'device': device.name ?? 'unknown_device_t'.tr}),
            title: 'audio_device'.tr,
            duration: const Duration(seconds: 3),
          );
        } else {
          print('[BT] 💡 Native connect also failed, marking as active for UI');
          activeAudioDevice.value = device;
          await _saveActiveAudioDevice(device.address);

          AppSnackbar.info(
            'audio_device_paired_msg'.trParams({'device': device.name ?? 'unknown_device_t'.tr}),
            title: 'audio_device'.tr,
            duration: const Duration(seconds: 3),
          );
        }
      }

      print('[BT] 🔗 === connectToDevice END ===');
    } catch (e, stackTrace) {
      print('[BT] ❌ Error connecting to device: $e');
      print('[BT] Stack trace: $stackTrace');

      String errorMessage = 'failed_to_connect_device'.tr;
      if (e.toString().contains('read failed')) {
        errorMessage = 'audio_device_connection_failed_msg'.tr;
      }

      AppSnackbar.error(
        errorMessage,
        title: 'connection_failed'.tr,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> disconnectDevice() async {
    print('[BT] 🔌 === disconnectDevice START ===');

    try {
      // Close SPP data connection if any
      if (_connection != null) {
        print('[BT] 🔌 Closing SPP connection...');
        await _connection!.close();
        _connection = null;
      }

      final deviceAddress = connectedDevice.value?.address ?? activeAudioDevice.value?.address;
      final deviceName = connectedDevice.value?.name ?? activeAudioDevice.value?.name;

      if (deviceAddress != null) {
        // Disconnect native A2DP/HFP audio profiles
        print('[BT] 🔌 Disconnecting native audio profiles for: $deviceName ($deviceAddress)');
        final nativeDisconnected = await _disconnectAudioNative(deviceAddress);
        print('[BT] 🔌 Native audio disconnect result: $nativeDisconnected');

        // Wait a bit for the system to process
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify disconnection
        final stillConnected = await _isAudioDeviceConnectedNative(deviceAddress);
        print('[BT] 🔌 Device still connected after disconnect: $stillConnected');

        // Clear both devices
        connectedDevice.value = null;
        activeAudioDevice.value = null;
        await _saveActiveAudioDevice(null);

        // Force UI update
        bondedDevices.refresh();

        if (!stillConnected) {
          AppSnackbar.info('disconnected_msg'.tr, title: 'disconnected'.tr);
        } else {
          AppSnackbar.info(
            'device_disconnect_system_msg'.tr,
            title: 'disconnected'.tr,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        print('[BT] ⚠️ No device to disconnect');
      }

      print('[BT] 🔌 === disconnectDevice END ===');
    } catch (e, stackTrace) {
      print('[BT] ❌ Error disconnecting: $e');
      print('[BT] Stack trace: $stackTrace');

      // Clear connection anyway
      _connection = null;
      connectedDevice.value = null;
      activeAudioDevice.value = null;
      await _saveActiveAudioDevice(null);
      bondedDevices.refresh();
    }
  }

  Future<void> toggleConnection(BluetoothDevice device) async {
    if (connectedDevice.value?.address == device.address || activeAudioDevice.value?.address == device.address) {
      await disconnectDevice();
    } else {
      await connectToDevice(device);
    }
  }

  String getDeviceIcon(BluetoothDevice device) {
    // flutter_bluetooth_serial's BluetoothDeviceType enum
    final typeString = device.type.toString();

    if (typeString.contains('audio') || typeString.contains('AUDIO')) {
      return 'bluetooth_audio';
    } else if (typeString.contains('phone') || typeString.contains('PHONE')) {
      return 'phone_bluetooth_speaker';
    } else if (typeString.contains('health') || typeString.contains('HEALTH')) {
      return 'monitor_heart';
    }

    return 'bluetooth';
  }

  bool isDeviceConnected(BluetoothDevice device) {
    return connectedDevice.value?.address == device.address || activeAudioDevice.value?.address == device.address;
  }

  String getDeviceName(BluetoothDevice device) {
    return device.name?.isNotEmpty == true ? device.name! : 'Unknown Device';
  }

  // Save active audio device address to storage
  Future<void> _saveActiveAudioDevice(String? address) async {
    try {
      if (address != null) {
        await _storage.write(_activeDeviceKey, address);
        print('[BT] 💾 Saved active audio device: $address');
      } else {
        await _storage.remove(_activeDeviceKey);
        print('[BT] 💾 Cleared active audio device from storage');
      }
    } catch (e) {
      print('[BT] ❌ Error saving active audio device: $e');
    }
  }

  // Load active audio device from storage and restore if still bonded
  Future<void> _loadActiveAudioDevice() async {
    try {
      final savedAddress = _storage.read(_activeDeviceKey) as String?;

      if (savedAddress != null) {
        print('[BT] 💾 Found saved active audio device: $savedAddress');

        // Check if device is actually still connected via native A2DP/HFP
        final isActuallyConnected = await _isAudioDeviceConnectedNative(savedAddress);
        print('[BT] 🔍 Native connection check: $isActuallyConnected');

        // Check if device is still bonded
        final device = bondedDevices.firstWhereOrNull(
          (d) => d.address == savedAddress,
        );

        if (device != null && isActuallyConnected) {
          activeAudioDevice.value = device;
          print('[BT] ✅ Restored active audio device: ${device.name} (actually connected)');
        } else if (device != null) {
          print('[BT] ⚠️ Saved device found but NOT connected at system level, clearing...');
          activeAudioDevice.value = null;
          await _storage.remove(_activeDeviceKey);
        } else {
          print('[BT] ⚠️ Saved device not found in bonded list, clearing...');
          await _storage.remove(_activeDeviceKey);
        }
      } else {
        // No saved device - check if any bonded device is connected via A2DP
        print('[BT] 💾 No saved active audio device, checking system connections...');
        await _detectConnectedAudioDevices();
      }
    } catch (e) {
      print('[BT] ❌ Error loading active audio device: $e');
    }
  }

  // Detect currently connected audio devices from Android system
  Future<void> _detectConnectedAudioDevices() async {
    try {
      final List<dynamic> devices = await _audioChannel.invokeMethod('getConnectedAudioDevices');
      print('[BT] 🔍 System connected audio devices: ${devices.length}');

      for (var deviceMap in devices) {
        final address = deviceMap['address'] as String?;
        final name = deviceMap['name'] as String?;
        print('[BT]   - $name ($address)');

        if (address != null) {
          final bondedDevice = bondedDevices.firstWhereOrNull(
            (d) => d.address == address,
          );

          if (bondedDevice != null) {
            activeAudioDevice.value = bondedDevice;
            await _saveActiveAudioDevice(address);
            print('[BT] ✅ Auto-detected connected audio device: ${bondedDevice.name}');
            break; // Take the first connected device
          }
        }
      }
    } catch (e) {
      print('[BT] ❌ Error detecting connected audio devices: $e');
    }
  }

  // Native method: Connect audio device via A2DP/HFP
  Future<bool> _connectAudioNative(String address) async {
    try {
      final result = await _audioChannel.invokeMethod<bool>(
        'connectAudioDevice',
        {'address': address},
      );
      print('[BT] 🔌 Native connectAudioDevice result: $result');
      return result ?? false;
    } catch (e) {
      print('[BT] ❌ Native connectAudioDevice error: $e');
      return false;
    }
  }

  // Native method: Disconnect audio device via A2DP/HFP
  Future<bool> _disconnectAudioNative(String address) async {
    try {
      final result = await _audioChannel.invokeMethod<bool>(
        'disconnectAudioDevice',
        {'address': address},
      );
      print('[BT] 🔌 Native disconnectAudioDevice result: $result');
      return result ?? false;
    } catch (e) {
      print('[BT] ❌ Native disconnectAudioDevice error: $e');
      return false;
    }
  }

  // Native method: Check if audio device is connected
  Future<bool> _isAudioDeviceConnectedNative(String address) async {
    try {
      final result = await _audioChannel.invokeMethod<bool>(
        'isAudioDeviceConnected',
        {'address': address},
      );
      return result ?? false;
    } catch (e) {
      print('[BT] ❌ Native isAudioDeviceConnected error: $e');
      return false;
    }
  }
}
