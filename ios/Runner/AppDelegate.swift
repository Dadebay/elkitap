import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    
  private let bluetoothAudioHelper = BluetoothAudioHelper()
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup Bluetooth Audio MethodChannel
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.googadev.elkitap/bluetooth_audio",
      binaryMessenger: controller.binaryMessenger
    )
    
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      switch call.method {
      case "disconnectAudioDevice":
        if let args = call.arguments as? [String: Any],
           let address = args["address"] as? String {
          let success = self.bluetoothAudioHelper.disconnectAudioDevice(uid: address)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Address is required", details: nil))
        }
        
      case "connectAudioDevice":
        if let args = call.arguments as? [String: Any],
           let address = args["address"] as? String {
          let success = self.bluetoothAudioHelper.connectAudioDevice(uid: address)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Address is required", details: nil))
        }
        
      case "isAudioDeviceConnected":
        if let args = call.arguments as? [String: Any],
           let address = args["address"] as? String {
          let connected = self.bluetoothAudioHelper.isAudioDeviceConnected(uid: address)
          result(connected)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Address is required", details: nil))
        }
        
      case "getConnectedAudioDevices":
        let devices = self.bluetoothAudioHelper.getConnectedAudioDevices()
        result(devices)
        
      case "getAvailableBluetoothDevices":
        let devices = self.bluetoothAudioHelper.getAvailableBluetoothDevices()
        result(devices)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
