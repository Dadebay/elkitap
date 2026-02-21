import Foundation
import AVFoundation
import CoreBluetooth

class BluetoothAudioHelper: NSObject {
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    /// Configure audio session to detect Bluetooth devices
    private func configureAudioSession() {
        do {
            // Configure with full Bluetooth routing support (output + input)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            NSLog("[BluetoothAudioHelper] Audio session configured for Bluetooth")
        } catch {
            NSLog("[BluetoothAudioHelper] Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    /// Get the currently active audio output route (all types: iPhone speaker, AirPods, BT headphones, etc.)
    func getConnectedAudioDevices() -> [[String: String]] {
        // NOTE: Do NOT call configureAudioSession() here — it would override just_audio's session
        var devices: [[String: String]] = []
        
        let currentRoute = audioSession.currentRoute
        
        NSLog("[BluetoothAudioHelper] === Current Audio Route Outputs ===")
        NSLog("[BluetoothAudioHelper] Total outputs: \(currentRoute.outputs.count)")
        
        for (index, output) in currentRoute.outputs.enumerated() {
            let portType = output.portType
            NSLog("[BluetoothAudioHelper] Output[\(index)]: \(output.portName) | Type: \(portType.rawValue) | UID: \(output.uid)")
            
            // Return ALL output types so the popup always shows the current route
            let isBluetooth = portType == .bluetoothA2DP || portType == .bluetoothHFP || portType == .bluetoothLE
            devices.append([
                "name": output.portName,
                "address": output.uid,
                "profile": portType.rawValue,
                "isBluetooth": isBluetooth ? "true" : "false"
            ])
        }
        
        NSLog("[BluetoothAudioHelper] Returning \(devices.count) audio output device(s)")
        return devices
    }
    
    /// Check if a specific audio device is currently the active audio output
    func isAudioDeviceConnected(uid: String) -> Bool {
        let currentRoute = audioSession.currentRoute
        for output in currentRoute.outputs {
            if output.uid == uid {
                let portType = output.portType
                if portType == .bluetoothA2DP || portType == .bluetoothHFP || portType == .bluetoothLE {
                    NSLog("[BluetoothAudioHelper] Device \(uid) is connected as \(portType.rawValue)")
                    return true
                }
            }
        }
        
        // Also check available inputs for HFP devices
        if let inputs = audioSession.availableInputs {
            for input in inputs {
                if input.uid == uid {
                    let portType = input.portType
                    if portType == .bluetoothHFP || portType == .bluetoothLE {
                        NSLog("[BluetoothAudioHelper] Device \(uid) is available as input \(portType.rawValue)")
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /// Attempt to override audio output to the speaker (effectively "disconnect" Bluetooth audio routing)
    func disconnectAudioDevice(uid: String) -> Bool {
        NSLog("[BluetoothAudioHelper] Attempting to disconnect audio device: \(uid)")
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
            NSLog("[BluetoothAudioHelper] Audio routed to speaker (disconnected from Bluetooth)")
            return true
        } catch {
            NSLog("[BluetoothAudioHelper] Failed to override audio: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Attempt to re-enable Bluetooth audio routing
    func connectAudioDevice(uid: String) -> Bool {
        NSLog("[BluetoothAudioHelper] Attempting to connect audio device: \(uid)")
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            try audioSession.overrideOutputAudioPort(.none)
            try audioSession.setActive(true)
            
            // Check if the device is now in the route
            let currentRoute = audioSession.currentRoute
            for output in currentRoute.outputs {
                if output.uid == uid {
                    NSLog("[BluetoothAudioHelper] Successfully routed audio to \(output.portName)")
                    return true
                }
            }
            
            // Even if not immediately in route, Bluetooth is now allowed
            // The system should route to it if it's available
            NSLog("[BluetoothAudioHelper] Bluetooth routing enabled, device may connect shortly")
            return true
        } catch {
            NSLog("[BluetoothAudioHelper] Failed to connect audio: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get all available Bluetooth audio devices (paired and in range)
    func getAvailableBluetoothDevices() -> [[String: String]] {
        // Configure audio session first to ensure Bluetooth devices are detected
        configureAudioSession()
        
        var devices: [[String: String]] = []
        
        // Check current route outputs
        let currentRoute = audioSession.currentRoute
        var addedUids = Set<String>()
        
        for output in currentRoute.outputs {
            let portType = output.portType
            if portType == .bluetoothA2DP || portType == .bluetoothHFP || portType == .bluetoothLE {
                if addedUids.insert(output.uid).inserted {
                    devices.append([
                        "name": output.portName,
                        "address": output.uid,
                        "profile": portType.rawValue,
                        "connected": "true"
                    ])
                }
            }
        }
        
        // Check available inputs for HFP devices
        if let inputs = audioSession.availableInputs {
            for input in inputs {
                let portType = input.portType
                if portType == .bluetoothHFP || portType == .bluetoothLE {
                    if addedUids.insert(input.uid).inserted {
                        devices.append([
                            "name": input.portName,
                            "address": input.uid,
                            "profile": portType.rawValue,
                            "connected": "false"
                        ])
                    }
                }
            }
        }
        
        return devices
    }
}
