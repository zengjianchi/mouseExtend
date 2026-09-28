import Foundation
import Cocoa
import ApplicationServices
import Combine

public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()
    
    @Published public var isAccessibilityGranted: Bool = false
    
    private var timer: Timer?
    
    private init() {
        checkPermission()
        startPolling()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    @discardableResult
    public func checkPermission() -> Bool {
        let granted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.isAccessibilityGranted = granted
            if granted && !EventTapManager.shared.isRunning {
                EventTapManager.shared.start()
            }
        }
        return granted
    }
    
    public func promptForPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
        openAccessibilityPreferences()
    }
    
    public func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func revealInFinder() {
        let bundleURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
    }
    
    private func startPolling() {
        // Poll every 1.0 second so when user toggles permission in System Settings, it updates immediately
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
    }
}
