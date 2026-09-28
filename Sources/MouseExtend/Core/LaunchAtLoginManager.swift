import Foundation
import ServiceManagement
import Combine
import AppKit

public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()
    
    @Published public var isLaunchAtLoginEnabled: Bool = false
    @Published public var requiresApproval: Bool = false
    
    private init() {
        refreshStatus()
    }
    
    public func refreshStatus() {
        var smEnabled = false
        var approvalNeeded = false
        
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            smEnabled = (status == .enabled)
            approvalNeeded = (status == .requiresApproval)
        }
        
        let appleScriptEnabled = checkAppleScriptLoginItem()
        let finalEnabled = smEnabled || appleScriptEnabled
        
        DispatchQueue.main.async {
            self.isLaunchAtLoginEnabled = finalEnabled
            self.requiresApproval = approvalNeeded
        }
    }
    
    public func setEnabled(_ enable: Bool) {
        UserDefaults.standard.set(enable, forKey: "launch_at_login")
        
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("[MouseExtend] SMAppService register/unregister error: \(error)")
            }
        }
        
        // Sync with AppleScript Login Items for maximum reliability across macOS versions
        fallbackSetLoginItem(enable: enable)
        refreshStatus()
    }
    
    public func openSystemSettings() {
        if #available(macOS 13.0, *) {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
    
    private func checkAppleScriptLoginItem() -> Bool {
        let appName = Bundle.main.bundleURL.deletingPathExtension().lastPathComponent
        let script = "tell application \"System Events\" to exists (every login item whose name is \"\(appName)\")"
        var error: NSDictionary?
        if let desc = NSAppleScript(source: script)?.executeAndReturnError(&error), desc.booleanValue {
            return true
        }
        return false
    }
    
    private func fallbackSetLoginItem(enable: Bool) {
        let appPath = Bundle.main.bundlePath
        let appName = Bundle.main.bundleURL.deletingPathExtension().lastPathComponent
        if enable {
            let script = """
            tell application "System Events"
                delete (every login item whose name is "\(appName)")
                make login item at end with properties {path:"\(appPath)", hidden:false, name:"\(appName)"}
            end tell
            """
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        } else {
            let script = "tell application \"System Events\" to delete (every login item whose name is \"\(appName)\")"
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }
}
