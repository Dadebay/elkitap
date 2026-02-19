import Foundation
import AVFoundation
import CoreBluetooth

class BluetoothAudioHelper: NSObject {
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    /// Get currently connected audio output devices (AirPods, Bluetooth headphones, etc.)
    func getConnectedAudioDevices() -> [[String: String]] {
        var devices: [[String: String]] = []
        
        let currentRoute = audioSession.currentRoute
        for output in currentRoute.outputs {
            let portType = output.portType
            
            // Check for Bluetooth audio devices
            if portType == .bluetoothA2DP || portType == .bluetoothHFP || portType == .bluetoothLE {
                devices.append([
                    "name": output.portName,
                    "address": output.uid,
                    "profile": portType.rawValue
                ])
                NSLog("[BluetoothAudioHelper] Found connected audio device: \(output.portName) (\(output.uid)) - \(portType.rawValue)")
            }
        }
        
        NSLog("[BluetoothAudioHelper] Total connected audio devices: \(devices.count)")
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
            try audioSession.setCategory(.playback, mode: .default, options: [])
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
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
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
