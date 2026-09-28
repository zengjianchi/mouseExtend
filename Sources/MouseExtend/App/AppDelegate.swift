import Cocoa
import SwiftUI
import Combine

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusBar()
        bindObservables()
        
        if !PermissionManager.shared.checkPermission() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                PermissionManager.shared.promptForPermission()
                self.openSettingsWindow()
            }
        }
        
        EventTapManager.shared.start()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.left.and.right.square", accessibilityDescription: "MouseExtend")
        }
        
        updateMenu()
    }
    
    private func bindObservables() {
        AppConfig.shared.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateMenu() }
            .store(in: &cancellables)
        
        PermissionManager.shared.$isAccessibilityGranted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                self?.updateMenu()
                if granted {
                    EventTapManager.shared.start()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        let isEnabled = AppConfig.shared.isEnabled
        let isGranted = PermissionManager.shared.isAccessibilityGranted
        
        // Status Item
        let statusTitle: String
        let statusIcon: String
        if !isGranted {
            statusTitle = "⚠️ 缺少辅助功能权限 (点击开启)"
            statusIcon = "exclamationmark.triangle"
        } else if isEnabled {
            statusTitle = "🟢 左右切屏已就绪"
            statusIcon = "checkmark.circle.fill"
        } else {
            statusTitle = "⚪ 左右切屏已暂停"
            statusIcon = "pause.circle"
        }
        
        let statusItem = NSMenuItem(title: statusTitle, action: !isGranted ? #selector(promptPermission) : nil, keyEquivalent: "")
        statusItem.image = NSImage(systemSymbolName: statusIcon, accessibilityDescription: nil)
        statusItem.target = self
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick toggle
        let toggleItem = NSMenuItem(title: isEnabled ? "暂停切屏功能" : "开启切屏功能", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let prefItem = NSMenuItem(title: "左右切屏按键设置...", action: #selector(openSettingsWindow), keyEquivalent: ",")
        prefItem.target = self
        menu.addItem(prefItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "退出 MouseExtend", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem.menu = menu
    }
    
    @objc public func toggleEnabled() {
        AppConfig.shared.isEnabled.toggle()
        updateMenu()
    }
    
    @objc public func promptPermission() {
        PermissionManager.shared.promptForPermission()
    }
    
    @objc public func openSettingsWindow() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 470, height: 370),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MouseExtend - 左右切屏按键设置"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView())
            self.settingsWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc public func quitApp() {
        EventTapManager.shared.stop()
        NSApp.terminate(nil)
    }
}
