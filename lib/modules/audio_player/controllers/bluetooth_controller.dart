import 'dart:async';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  final RxList<ScanResult> scannedDevices = <ScanResult>[].obs;
  final Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  final RxBool isScanning = false.obs;
  final RxBool isBluetoothOn = false.obs;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  @override
  void onInit() {
    super.onInit();
    _initBluetooth();
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _adapterSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initBluetooth() async {
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      isBluetoothOn.value = state == BluetoothAdapterState.on;
    });

    final state = await FlutterBluePlus.adapterState.first;
    isBluetoothOn.value = state == BluetoothAdapterState.on;
  }

  Future<bool> requestPermissions() async {
    if (GetPlatform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } else if (GetPlatform.isIOS) {
      return true;
    }
    return false;
  }

  Future<void> getConnectedDevices() async {
    try {
      // Get already connected devices (system connected)
      // Pass empty list to get all connected devices
      final List<BluetoothDevice> connectedSystemDevices = await FlutterBluePlus.systemDevices([]);

      // Check if any system device is already connected
      for (var device in connectedSystemDevices) {
        final state = await device.connectionState.first;
        if (state == BluetoothConnectionState.connected) {
          connectedDevice.value = device;
          break;
        }
      }
    } catch (e) {
      print('Error getting connected devices: $e');
    }
  }

  Future<void> startScan() async {
    if (!isBluetoothOn.value) {
      AppSnackbar.warning('turn_on_bluetooth'.tr, title: 'bluetooth_off'.tr);
      return;
    }

    // Request permissions
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      AppSnackbar.error('bluetooth_scan_permission'.tr, title: 'permission_denied'.tr);
      return;
    }

    try {
      scannedDevices.clear();

      // Check for already connected devices first
      await getConnectedDevices();

      isScanning.value = true;
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          final index = scannedDevices.indexWhere((d) => d.device.remoteId == result.device.remoteId);
          if (index != -1) {
            scannedDevices[index] = result;
          } else {
            scannedDevices.add(result);
          }
        }
      });

      await Future.delayed(const Duration(seconds: 15));
      if (isScanning.value) {
        await stopScan();
      }
    } catch (e) {
      isScanning.value = false;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      isScanning.value = false;
    } catch (e) {}
  }

  Future<void> connectToDevice(BluetoothDevice device, {int maxRetries = 3}) async {
    int retryCount = 0;
    int delayMs = 1000; // Start with 1 second delay

    while (retryCount < maxRetries) {
      try {
        await stopScan();

        // Check if device is already connected
        final currentState = await device.connectionState.first.timeout(const Duration(seconds: 2), onTimeout: () => BluetoothConnectionState.disconnected);

        if (currentState == BluetoothConnectionState.connected) {
          connectedDevice.value = device;
          _setupConnectionListener(device);

          AppSnackbar.success('connected_to'.trParams({'device': device.platformName.isNotEmpty ? device.platformName : 'unknown_device_t'.tr}), title: 'connected'.tr);
          return;
        }

        // Disconnect any existing device
        if (connectedDevice.value != null && connectedDevice.value?.remoteId != device.remoteId) {
          await disconnectDevice();
          // Wait a bit after disconnecting before connecting to new device
          await Future.delayed(Duration(milliseconds: 500));
        }

        // Add delay before connection attempt to prevent error 133
        if (retryCount > 0) {
          print('Retry attempt $retryCount after ${delayMs}ms delay');
          await Future.delayed(Duration(milliseconds: delayMs));
        }

        // Connect to device with timeout
        await device.connect(
          license: License.free,
          autoConnect: false,
          timeout: const Duration(seconds: 10),
        );

        // Wait a moment to ensure connection is established
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify connection
        final newState = await device.connectionState.first.timeout(const Duration(seconds: 2));

        if (newState == BluetoothConnectionState.connected) {
          connectedDevice.value = device;
          _setupConnectionListener(device);

          AppSnackbar.success('connected_to'.trParams({'device': device.platformName.isNotEmpty ? device.platformName : 'unknown_device_t'.tr}), title: 'connected'.tr);
          return; // Success, exit the retry loop
        } else {
          throw Exception('Connection verification failed');
        }
      } catch (e) {
        retryCount++;
        print('Error connecting to device (attempt $retryCount/$maxRetries): $e');

        // Check if it's error 133 (ANDROID_SPECIFIC_ERROR)
        final isError133 = e.toString().contains('133') || e.toString().contains('ANDROID_SPECIFIC_ERROR');

        if (retryCount >= maxRetries) {
          // Max retries reached
          String errorMessage = 'failed_to_connect_device'.tr;

          if (isError133) {
            errorMessage = 'bluetooth_error_133_msg'.tr;
          } else if (e.toString().contains('timeout')) {
            errorMessage = 'connection_timeout_msg'.tr;
          }

          AppSnackbar.error(errorMessage, title: 'connection_failed'.tr, duration: const Duration(seconds: 4));
          break;
        }

        // Exponential backoff for retries
        delayMs *= 2; // Double the delay for next retry

        // Try to clean up the connection before retrying
        try {
          await device.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (_) {}
      }
    }
  }

  void _setupConnectionListener(BluetoothDevice device) {
    // Cancel previous connection state subscription
    _connectionSubscription?.cancel();

    // Listen to connection state changes
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if (connectedDevice.value?.remoteId == device.remoteId) {
          connectedDevice.value = null;
          _connectionSubscription?.cancel();
        }
      }
    });
  }

  Future<void> disconnectDevice() async {
    try {
      if (connectedDevice.value != null) {
        final deviceToDisconnect = connectedDevice.value!;

        // Cancel connection listener first
        await _connectionSubscription?.cancel();
        _connectionSubscription = null;

        // Disconnect the device
        await deviceToDisconnect.disconnect();

        // Clear connected device
        connectedDevice.value = null;

        // Add a small delay to ensure clean disconnection
        // This helps prevent error 133 on next connection attempt
        await Future.delayed(const Duration(milliseconds: 500));

        AppSnackbar.info('disconnected_msg'.tr, title: 'disconnected'.tr);
      }
    } catch (e) {
      print('Error disconnecting: $e');
      // Even if disconnect fails, clear the connected device
      connectedDevice.value = null;
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
    }
  }

  /// Toggle connection to a device
  Future<void> toggleConnection(BluetoothDevice device) async {
    if (connectedDevice.value?.remoteId == device.remoteId) {
      await disconnectDevice();
    } else {
      await connectToDevice(device);
    }
  }

  String getDeviceIcon(BluetoothDevice device) {
    return 'bluetooth_audio';
  }

  bool isDeviceConnected(BluetoothDevice device) {
    return connectedDevice.value?.remoteId == device.remoteId;
  }

  String getDeviceName(ScanResult result) {
    if (result.advertisementData.localName.isNotEmpty) {
      return result.advertisementData.localName;
    } else if (result.device.platformName.isNotEmpty) {
      return result.device.platformName;
    }
    return 'Unknown Device';
  }
}
