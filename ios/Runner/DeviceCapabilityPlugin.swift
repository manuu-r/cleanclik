import Flutter
import UIKit
import ARKit

public class DeviceCapabilityPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vibesweep/device_capabilities", binaryMessenger: registrar.messenger())
        let instance = DeviceCapabilityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkARKitSupport":
            result(checkARKitSupport())
        case "hasHighPerformanceGPU":
            result(hasHighPerformanceGPU())
        case "getAvailableMemory":
            result(getAvailableMemory())
        case "getDeviceInfo":
            result(getDeviceInfo())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func checkARKitSupport() -> Bool {
        if #available(iOS 11.0, *) {
            return ARWorldTrackingConfiguration.isSupported
        }
        return false
    }

    private func hasHighPerformanceGPU() -> Bool {
        // Heuristic based on device model
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        // Consider high-performance for newer devices
        if #available(iOS 12.0, *) {
            return ProcessInfo.processInfo.physicalMemory > 3 * 1024 * 1024 * 1024 // 3GB+
        }
        return false
    }

    private func getAvailableMemory() -> Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        // Return available memory in MB (simplified calculation)
        return Int(physicalMemory / (1024 * 1024))
    }

    private func getDeviceInfo() -> [String: Any] {
        return [
            "model": UIDevice.current.model,
            "systemName": UIDevice.current.systemName,
            "systemVersion": UIDevice.current.systemVersion,
            "identifierForVendor": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            "physicalMemory": ProcessInfo.processInfo.physicalMemory
        ]
    }
}