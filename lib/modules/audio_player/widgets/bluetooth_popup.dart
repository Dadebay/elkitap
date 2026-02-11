// dialogs/bluetooth_popup.dart
// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/audio_player/controllers/bluetooth_controller.dart';

class BluetoothPopup {
  static void show(BuildContext context) {
    final bluetoothController = Get.put(BluetoothController());
    bluetoothController.startScan();

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
      bluetoothController.stopScan();
    });
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
                  onPressed: () {
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
        final devices = bluetoothController.scannedDevices;

        // Show scanning indicator
        if (bluetoothController.isScanning.value && devices.isEmpty) {
          return _buildScanningIndicator();
        }

        // Show empty state
        if (devices.isEmpty) {
          return _buildEmptyState();
        }

        // Show device list
        return ListView.separated(
          shrinkWrap: true,
          itemCount: devices.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.white.withOpacity(0.15),
          ),
          itemBuilder: (context, index) {
            final result = devices[index];
            final device = result.device;
            final isConnected = bluetoothController.isDeviceConnected(device);
            final deviceName = bluetoothController.getDeviceName(result);

            return _buildDeviceItem(
              bluetoothController: bluetoothController,
              device: device,
              deviceName: deviceName,
              isConnected: isConnected,
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
  }) {
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
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  if (deviceName == 'Unknown Device')
                    Text(
                      device.remoteId.toString(),
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
                Icons.check,
                size: 24,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
