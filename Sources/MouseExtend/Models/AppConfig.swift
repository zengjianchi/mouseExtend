import Foundation
import SwiftUI
import Combine

public enum SwitchDirection: String, Codable {
    case left
    case right
}

public class AppConfig: ObservableObject {
    public static let shared = AppConfig()
    
    // Switch on/off
    @Published public var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }
    
    // Left switch button mapping
    @Published public var leftButton: Int {
        didSet { UserDefaults.standard.set(leftButton, forKey: "leftButton") }
    }
    @Published public var leftButtonName: String {
        didSet { UserDefaults.standard.set(leftButtonName, forKey: "leftButtonName") }
    }
    
    // Right switch button mapping
    @Published public var rightButton: Int {
        didSet { UserDefaults.standard.set(rightButton, forKey: "rightButton") }
    }
    @Published public var rightButtonName: String {
        didSet { UserDefaults.standard.set(rightButtonName, forKey: "rightButtonName") }
    }
    
    private init() {
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.object(forKey: "isEnabled") as? Bool ?? true
        
        // Defaults: Button 4 (CGEvent 3) = Switch Left, Button 5 (CGEvent 4) = Switch Right
        self.leftButton = defaults.object(forKey: "leftButton") as? Int ?? 3
        self.leftButtonName = defaults.string(forKey: "leftButtonName") ?? "按键 4 (侧键后退 Back)"
        
        self.rightButton = defaults.object(forKey: "rightButton") as? Int ?? 4
        self.rightButtonName = defaults.string(forKey: "rightButtonName") ?? "按键 5 (侧键前进 Forward)"
    }
    
    public func setBinding(direction: SwitchDirection, buttonNumber: Int, buttonName: String) {
        if direction == .left {
            if rightButton == buttonNumber {
                rightButton = -1
                rightButtonName = "未设置"
            }
            leftButton = buttonNumber
            leftButtonName = buttonName
        } else {
            if leftButton == buttonNumber {
                leftButton = -1
                leftButtonName = "未设置"
            }
            rightButton = buttonNumber
            rightButtonName = buttonName
        }
    }
    
    public func swapBindings() {
        let tempButton = leftButton
        let tempName = leftButtonName
        
        leftButton = rightButton
        leftButtonName = rightButtonName
        
        rightButton = tempButton
        rightButtonName = tempName
    }
    
    public func resetToDefaults() {
        isEnabled = true
        leftButton = 3
        leftButtonName = "按键 4 (侧键后退 Back)"
        rightButton = 4
        rightButtonName = "按键 5 (侧键前进 Forward)"
    }
}
