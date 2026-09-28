import Foundation
import CoreGraphics
import Cocoa
import Combine

public struct DetectedTestInfo: Equatable {
    public let buttonNumber: Int
    public let buttonName: String
    public let triggeredAction: String?
}

public final class EventTapManager: ObservableObject {
    public static let shared = EventTapManager()
    
    @Published public var isRunning: Bool = false
    @Published public var lastTestInfo: DetectedTestInfo? = nil
    @Published public var recordingDirection: SwitchDirection? = nil
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var activeBoundButtons: Set<Int> = []
    
    private init() {}
    
    public func start() {
        guard eventTap == nil else { return }
        
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.rightMouseDown.rawValue) |
                        (1 << CGEventType.otherMouseDown.rawValue) |
                        (1 << CGEventType.otherMouseUp.rawValue) |
                        (1 << CGEventType.rightMouseUp.rawValue)
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
            return manager.handleEvent(type: type, event: event)
        }
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("[MouseExtend] CGEventTap creation failed. Check accessibility permission.")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        DispatchQueue.main.async { self.isRunning = true }
        print("[MouseExtend] EventTap started.")
    }
    
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
                runLoopSource = nil
            }
            eventTap = nil
            DispatchQueue.main.async { self.isRunning = false }
            print("[MouseExtend] EventTap stopped.")
        }
    }
    
    public func startRecording(direction: SwitchDirection) {
        DispatchQueue.main.async {
            self.recordingDirection = direction
        }
    }
    
    public func cancelRecording() {
        DispatchQueue.main.async {
            self.recordingDirection = nil
        }
    }
    
    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        
        let config = AppConfig.shared
        
        // Extract button number
        let btnNum: Int
        if type == .leftMouseDown {
            btnNum = 0
        } else if type == .rightMouseDown || type == .rightMouseUp {
            btnNum = 1
        } else {
            btnNum = Int(event.getIntegerValueField(.mouseEventButtonNumber))
        }
        
        // 1. Recording Mode: wait for user to click any button to bind
        if let recording = recordingDirection, type == .otherMouseDown || type == .rightMouseDown {
            // Disallow primary left click (0) to prevent breaking desktop click
            if btnNum >= 1 {
                let name = friendlyName(btnNum)
                config.setBinding(direction: recording, buttonNumber: btnNum, buttonName: name)
                cancelRecording()
                return nil // Suppress click while recording
            }
        }
        
        // 2. Suppress Mouse Up for active bound buttons
        if type == .otherMouseUp || type == .rightMouseUp {
            if activeBoundButtons.contains(btnNum) {
                activeBoundButtons.remove(btnNum)
                return nil
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 3. Normal Execution (Mouse Down)
        guard config.isEnabled, (type == .otherMouseDown || type == .rightMouseDown) else {
            return Unmanaged.passUnretained(event)
        }
        
        var actionName: String? = nil
        if btnNum == config.leftButton {
            KeySender.shared.switchLeft()
            actionName = "向左切屏 (上一空间)"
            activeBoundButtons.insert(btnNum)
        } else if btnNum == config.rightButton {
            KeySender.shared.switchRight()
            actionName = "向右切屏 (下一空间)"
            activeBoundButtons.insert(btnNum)
        }
        
        // Post live feedback for testing
        let info = DetectedTestInfo(buttonNumber: btnNum, buttonName: friendlyName(btnNum), triggeredAction: actionName)
        DispatchQueue.main.async {
            self.lastTestInfo = info
        }
        
        if actionName != nil {
            return nil // Suppress native mouse button
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    public func friendlyName(_ num: Int) -> String {
        switch num {
        case 0: return "鼠标左键"
        case 1: return "鼠标右键"
        case 2: return "鼠标中键 (滚轮按压)"
        case 3: return "按键 4 (侧键后退 Back)"
        case 4: return "按键 5 (侧键前进 Forward)"
        default: return "按键 \(num + 1) (扩展侧键)"
        }
    }
}
