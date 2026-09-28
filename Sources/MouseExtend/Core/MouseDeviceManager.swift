import Foundation
import IOKit
import IOKit.hid
import Combine

public enum MouseScrollDirection: String, Codable, CaseIterable, Identifiable {
    case natural = "natural"         // 自然滚动（随手势移动）
    case traditional = "traditional" // 反转滚动（经典 Windows 模式）
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .natural: return "自然滚动 (系统默认)"
        case .traditional: return "反转滚动 (传统模式)"
        }
    }
}

public struct MouseDeviceInfo: Identifiable, Codable, Equatable {
    public var id: String // unique key e.g. "vendor_product_name"
    public var name: String
    public var vendorID: Int
    public var productID: Int
    public var transport: String
    public var isConnected: Bool
    public var scrollDirection: MouseScrollDirection
}

public final class MouseDeviceManager: ObservableObject {
    public static let shared = MouseDeviceManager()
    
    @Published public var recognizedMice: [MouseDeviceInfo] = []
    
    private var hidManager: IOHIDManager?
    
    public var currentActiveScrollDirection: MouseScrollDirection {
        // Return direction of currently connected mouse, or default to traditional if set
        if let connected = recognizedMice.first(where: { $0.isConnected }) {
            return connected.scrollDirection
        }
        return .natural
    }
    
    private init() {
        setupHIDManager()
        refreshDevices()
    }
    
    private func setupHIDManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = manager
        
        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse
        ]
        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
        
        // Callbacks for matching & removal
        let matchingCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let mgr = Unmanaged<MouseDeviceManager>.fromOpaque(context).takeUnretainedValue()
            mgr.refreshDevices()
        }
        
        let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let mgr = Unmanaged<MouseDeviceManager>.fromOpaque(context).takeUnretainedValue()
            mgr.refreshDevices()
        }
        
        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    
    public func refreshDevices() {
        guard let manager = hidManager else { return }
        
        var currentMiceMap: [String: MouseDeviceInfo] = [:]
        
        if let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> {
            for dev in deviceSet {
                let name = IOHIDDeviceGetProperty(dev, kIOHIDProductKey as CFString) as? String ?? "通用鼠标"
                let vendor = IOHIDDeviceGetProperty(dev, kIOHIDVendorIDKey as CFString) as? Int ?? 0
                let product = IOHIDDeviceGetProperty(dev, kIOHIDProductIDKey as CFString) as? Int ?? 0
                let transport = IOHIDDeviceGetProperty(dev, kIOHIDTransportKey as CFString) as? String ?? ""
                
                // Exclude internal trackpad / keyboard
                if name.contains("Trackpad") || name.contains("Internal Keyboard") || (vendor == 0 && transport == "FIFO") {
                    continue
                }
                
                let deviceKey = "\(vendor)_\(product)_\(name)"
                
                // Load saved scroll preference or default to .traditional (most users want mouse wheel inverted from trackpad)
                let savedRaw = UserDefaults.standard.string(forKey: "mouse_scroll_direction_\(deviceKey)")
                let direction = MouseScrollDirection(rawValue: savedRaw ?? "") ?? .traditional
                
                let info = MouseDeviceInfo(
                    id: deviceKey,
                    name: name,
                    vendorID: vendor,
                    productID: product,
                    transport: transport,
                    isConnected: true,
                    scrollDirection: direction
                )
                currentMiceMap[deviceKey] = info
            }
        }
        
        // Also keep previously saved mice so user can see them even if momentarily disconnected
        var updatedList: [MouseDeviceInfo] = []
        for (_, mouse) in currentMiceMap {
            updatedList.append(mouse)
        }
        
        DispatchQueue.main.async {
            self.recognizedMice = updatedList
        }
    }
    
    public func setScrollDirection(_ direction: MouseScrollDirection, for mouseID: String) {
        objectWillChange.send()
        UserDefaults.standard.set(direction.rawValue, forKey: "mouse_scroll_direction_\(mouseID)")
        
        if let idx = recognizedMice.firstIndex(where: { $0.id == mouseID }) {
            recognizedMice[idx].scrollDirection = direction
        }
    }
}
