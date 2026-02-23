// dialogs/bluetooth_popup.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/audio_player/controllers/bluetooth_controller.dart';

class BluetoothPopup {
  static void show(BuildContext context) {
    print('[BT-UI] 📱 === Bluetooth Popup OPENED ===');

    final bluetoothController = Get.put(BluetoothController());

    if (Platform.isIOS) {
      // iOS: Show our popup with current active device + "Choose Audio Output" button
      // The system route picker opens only when user taps "Choose Audio Output"
      print('[BT-UI] 🍎 iOS detected - showing iOS audio popup');
      _showIOSPopup(context, bluetoothController);
      return;
    }

    // Android: Show custom device list
    print('[BT-UI] 🔍 Getting bonded devices first...');
    bluetoothController.getBondedDevices().then((_) {
      print('[BT-UI] ✅ getBondedDevices completed, starting scan...');
      bluetoothController.startScan();
    });

    _showAndroidPopup(context, bluetoothController);
  }

  static void _showIOSPopup(BuildContext context, BluetoothController bluetoothController) {
    // Refresh devices after a short delay (so the system picker has time to change route)
    Future.delayed(const Duration(seconds: 2), () {
      bluetoothController.getBondedDevices();
    });

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          Positioned(
            bottom: 80,
            right: 20,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 320,
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3633).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        _buildHeader(bluetoothController),
                        Divider(height: 1, thickness: 0.5, color: Colors.white.withOpacity(0.15)),

                        // Current audio output info
                        Obx(() {
                          final activeDevice = bluetoothController.activeAudioDevice.value;
                          final bondedDevices = bluetoothController.bondedDevices;

                          if (activeDevice != null) {
                            final isBT = bluetoothController.iosDeviceProfiles[activeDevice.address] ?? false;
                            final icon = isBT ? Icons.headphones : Icons.phone_iphone;
                            return _buildIOSDeviceRow(icon, activeDevice.name ?? 'iPhone');
                          }

                          if (bondedDevices.isNotEmpty) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: bondedDevices.map((device) {
                                final isBT = bluetoothController.iosDeviceProfiles[device.address] ?? false;
                                final icon = isBT ? Icons.headphones : Icons.phone_iphone;
                                return _buildIOSDeviceRow(icon, device.name ?? 'iPhone');
                              }).toList(),
                            );
                          }

                          // Fallback: show iPhone speaker
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_iphone, color: Colors.white70, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'iphone_speaker'.tr,
                                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                                ),
                              ],
                            ),
                          );
                        }),

                        Divider(height: 1, thickness: 0.5, color: Colors.white.withOpacity(0.15)),

                        // "Choose Audio Output" button — opens Apple's system picker
                        InkWell(
                          onTap: () {
                            print('[BT-UI] 🍎 User tapped Choose Audio Output');
                            bluetoothController.showIOSAudioRoutePicker();
                            // Refresh after user picks a device
                            Future.delayed(const Duration(seconds: 3), () {
                              bluetoothController.getBondedDevices();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(Icons.airplay, color: Colors.white, size: 22),
                                const SizedBox(width: 14),
                                Text(
                                  'choose_audio_output'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, color: Colors.white54, size: 22),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      print('[BT-UI] 🔴 Bluetooth Popup CLOSED (iOS)');
    });
  }

  static void _showAndroidPopup(BuildContext context, BluetoothController bluetoothController) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          Positioned(
            bottom: 80,
            right: 20,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 320,
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3633).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        _buildHeader(bluetoothController),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        // Device list
                        _buildDeviceList(bluetoothController),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Stop scanning when dialog closes
      print('[BT-UI] 🔴 Bluetooth Popup CLOSED - stopping scan');
      bluetoothController.stopScan();
      print('[BT-UI] 📱 === Bluetooth Popup END ===');
    });
  }

  /// A simple non-tappable row showing the current iOS audio output
  static Widget _buildIOSDeviceRow(IconData icon, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
        ],
      ),
    );
  }

  static Widget _buildHeader(BluetoothController bluetoothController) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CustomIcon(
            title: IconConstants.a6,
            height: 24,
            width: 24,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'bluetooth_devices'.tr,
              style: const TextStyle(
                fontSize: 17,
                fontFamily: 'GilroyBold',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Obx(() => bluetoothController.isScanning.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: () async {
                    print('[BT-UI] 🔄 Refresh button pressed');
                    // Refresh both bonded devices and start new scan
                    await bluetoothController.getBondedDevices();
                    bluetoothController.startScan();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )),
        ],
      ),
    );
  }

  static Widget _buildDeviceList(BluetoothController bluetoothController) {
    return Flexible(
      child: Obx(() {
        final scannedDevices = bluetoothController.scannedDevices;
        final bondedDevices = bluetoothController.bondedDevices;
        final connectedDevice = bluetoothController.connectedDevice.value;
        final activeAudioDevice = bluetoothController.activeAudioDevice.value;

        print('[BT-UI] 🔄 Building device list:');
        print('[BT-UI]   - Scanned devices: ${scannedDevices.length}');
        print('[BT-UI]   - Bonded devices: ${bondedDevices.length}');
        print('[BT-UI]   - Connected device: ${connectedDevice?.name ?? "null"}');
        print('[BT-UI]   - Active audio device: ${activeAudioDevice?.name ?? "null"}');
        print('[BT-UI]   - Is scanning: ${bluetoothController.isScanning.value}');

        // Combine bonded and scanned devices, removing duplicates
        final allDevicesMap = <String, dynamic>{};

        // Add bonded devices first
        for (var device in bondedDevices) {
          allDevicesMap[device.address] = device;
        }

        // Add scanned devices (overwrite if already exists)
        for (var device in scannedDevices) {
          allDevicesMap[device.address] = device;
        }

        final allDevices = allDevicesMap.values.toList();

        // Show scanning indicator if no devices yet
        if (bluetoothController.isScanning.value && allDevices.isEmpty) {
          print('[BT-UI] 🔄 Showing scanning indicator');
          return _buildScanningIndicator();
        }

        // Show empty state if no devices at all
        if (allDevices.isEmpty) {
          print('[BT-UI] ❌ No devices to show - showing empty state');
          return _buildEmptyState();
        }

        print('[BT-UI] 📋 Total devices to show: ${allDevices.length}');

        // Sort devices: connected first, then bonded, then discovered
        allDevices.sort((a, b) {
          final aConnected = bluetoothController.isDeviceConnected(a);
          final bConnected = bluetoothController.isDeviceConnected(b);

          if (aConnected && !bConnected) return -1;
          if (!aConnected && bConnected) return 1;

          final aBonded = a.isBonded;
          final bBonded = b.isBonded;

          if (aBonded && !bBonded) return -1;
          if (!aBonded && bBonded) return 1;

          return 0;
        });

        // Show device list
        return ListView.separated(
          shrinkWrap: true,
          itemCount: allDevices.length,
          separatorBuilder: (context, index) {
            return Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withOpacity(0.15),
            );
          },
          itemBuilder: (context, index) {
            final device = allDevices[index];
            final isConnected = bluetoothController.isDeviceConnected(device);
            final deviceName = bluetoothController.getDeviceName(device);

            return _buildDeviceItem(
              bluetoothController: bluetoothController,
              device: device,
              deviceName: deviceName,
              isConnected: isConnected,
              isBonded: device.isBonded,
            );
          },
        );
      }),
    );
  }

  static Widget _buildScanningIndicator() {
    return Padding(
      padding: EdgeInsets.all(40.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'scanning_for_devices'.tr,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(40.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            color: Colors.white54,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'no_devices_found'.tr,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'bluetooth_check_settings'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDeviceItem({
    required BluetoothController bluetoothController,
    required dynamic device,
    required String deviceName,
    required bool isConnected,
    bool isBonded = false,
  }) {
    final isAudioActive = bluetoothController.activeAudioDevice.value?.address == device.address;
    final isDataConnected = bluetoothController.connectedDevice.value?.address == device.address;

    return InkWell(
      onTap: () async {
        await bluetoothController.toggleConnection(device);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.headphones,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName == 'Unknown Device' ? 'unknown_device_t'.tr : deviceName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: isConnected ? Colors.greenAccent : Colors.white,
                    ),
                  ),
                  if (isDataConnected)
                    Text(
                      'connected'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.greenAccent,
                      ),
                    )
                  else if (isAudioActive)
                    Text(
                      'audio_active'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.lightGreenAccent,
                      ),
                    )
                  else if (isBonded)
                    Text(
                      'paired'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            if (isConnected)
              const Icon(
                Icons.check_circle,
                size: 24,
                color: Colors.greenAccent,
              ),
          ],
        ),
      ),
    );
  }
}
