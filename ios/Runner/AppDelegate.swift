import Flutter
import UIKit
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
    
  private let bluetoothAudioHelper = BluetoothAudioHelper()
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure audio session for Bluetooth support
    setupAudioSession()
    
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
        
      case "showSystemAudioRoutePicker":
        DispatchQueue.main.async {
          self.showAudioRoutePicker()
        }
        result(true)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
      NSLog("[AppDelegate] Audio session configured for Bluetooth support")
    } catch {
      NSLog("[AppDelegate] Failed to configure audio session: \(error.localizedDescription)")
    }
  }
  
  private func showAudioRoutePicker() {
    // MPVolumeView contains Apple's native audio route picker button
    // We programmatically trigger it to show the system Bluetooth device selector
    let volumeView = MPVolumeView(frame: .zero)
    volumeView.alpha = 0.01 // Nearly invisible
    
    guard let rootVC = window?.rootViewController else { return }
    rootVC.view.addSubview(volumeView)
    
    // Find and trigger the route button inside MPVolumeView
    for subview in volumeView.subviews {
      if let button = subview as? UIButton {
        button.sendActions(for: .touchUpInside)
        break
      }
    }
    
    // Remove after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      volumeView.removeFromSuperview()
    }
  }
}
