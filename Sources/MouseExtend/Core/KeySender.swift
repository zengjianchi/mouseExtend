import Foundation
import CoreGraphics
import Cocoa

public final class KeySender {
    public static let shared = KeySender()
    
    private init() {}
    
    public func switchLeft() {
        triggerSpaceSwitch(keyCode: 123) // macOS Left Arrow (Move left a space)
    }
    
    public func switchRight() {
        triggerSpaceSwitch(keyCode: 124) // macOS Right Arrow (Move right a space)
    }
    
    private func triggerSpaceSwitch(keyCode: CGKeyCode) {
        // Method 1: AppleScript via System Events (Proven to trigger WindowServer Space Switching reliably)
        DispatchQueue.global(qos: .userInteractive).async {
            let scriptSource = "tell application \"System Events\" to key code \(keyCode) using control down"
            if let script = NSAppleScript(source: scriptSource) {
                var errorInfo: NSDictionary?
                script.executeAndReturnError(&errorInfo)
                if let err = errorInfo {
                    print("[MouseExtend] AppleScript dispatch error: \(err)")
                }
            }
        }
        
        // Method 2: Clean CoreGraphics Hardware Event (Clean arrow with maskControl flag, without invalid modifier keyDown)
        let source = CGEventSource(stateID: .hidSystemState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = .maskControl
            keyDown.post(tap: .cghidEventTap)
        }
        
        usleep(15000) // 15ms hold time
        
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = .maskControl
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
