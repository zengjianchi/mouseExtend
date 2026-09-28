import SwiftUI

public struct SettingsView: View {
    @ObservedObject var config = AppConfig.shared
    @ObservedObject var eventTap = EventTapManager.shared
    @ObservedObject var permissionManager = PermissionManager.shared
    @ObservedObject var deviceManager = MouseDeviceManager.shared
    @ObservedObject var launchManager = LaunchAtLoginManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Header Bar
                HStack(spacing: 12) {
                    let appIcon: NSImage = {
                        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"), let img = NSImage(contentsOf: url) {
                            return img
                        }
                        return NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
                    }()
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 38, height: 38)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MouseExtend")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("鼠标快速切屏与专属滚轮方向工具")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Master Enable Toggle Pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(config.isEnabled && permissionManager.isAccessibilityGranted ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(config.isEnabled ? (permissionManager.isAccessibilityGranted ? "运行中" : "未授权") : "已暂停")
                            .font(.caption)
                            .fontWeight(.medium)
                        Toggle("", isOn: $config.isEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .scaleEffect(0.75)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 4)
                
                // Section 1: Mouse Recognition & Scroll Wheel Direction
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "computermouse.fill")
                            .font(.subheadline)
                            .foregroundColor(.teal)
                        Text("已识别鼠标与滚轮方向")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            deviceManager.refreshDevices()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("重新检测已连接的鼠标")
                    }
                    
                    if deviceManager.recognizedMice.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.secondary)
                            Text("未检测到外接鼠标，插入 USB 或连接蓝牙鼠标后将自动识别。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                    } else {
                        ForEach(deviceManager.recognizedMice) { mouse in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(mouse.name)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                        Text(mouse.transport.isEmpty ? "外接设备" : mouse.transport)
                                            .font(.system(size: 9))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.teal.opacity(0.15))
                                            .foregroundColor(.teal)
                                            .cornerRadius(4)
                                    }
                                    Text("专属滚轮设置已保存，下次连接自动生效无需再调")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Picker("", selection: Binding(
                                    get: { mouse.scrollDirection },
                                    set: { newDir in
                                        deviceManager.setScrollDirection(newDir, for: mouse.id)
                                    }
                                )) {
                                    ForEach(MouseScrollDirection.allCases) { dir in
                                        Text(dir.title).tag(dir)
                                    }
                                }
                                .frame(width: 170)
                            }
                            .padding(10)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Section 2: Switch Left Card
                directionCard(
                    direction: .left,
                    title: "向左切屏 (上一空间 / 触控板四指向右划)",
                    icon: "arrow.left.circle.fill",
                    color: .blue,
                    currentButtonNumber: config.leftButton,
                    currentButtonName: config.leftButtonName
                )
                
                // Section 3: Switch Right Card
                directionCard(
                    direction: .right,
                    title: "向右切屏 (下一空间 / 触控板四指向左划)",
                    icon: "arrow.right.circle.fill",
                    color: .purple,
                    currentButtonNumber: config.rightButton,
                    currentButtonName: config.rightButtonName
                )
                
                // Section 4: Live Test Area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.indigo)
                        Text("实时按键映射测试")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        if let test = eventTap.lastTestInfo {
                            Circle()
                                .fill(test.triggeredAction != nil ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text("捕获按键：\(test.buttonName)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if let action = test.triggeredAction {
                                HStack(spacing: 4) {
                                    Text("生效 ➔")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(action)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(4)
                            } else {
                                Text("未映射 (普通按键)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("在鼠标上按下任意按键，可在此原地测试并检验切屏效果。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Section 5: Launch at Login Option
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("开机自动启动")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            if launchManager.isLaunchAtLoginEnabled {
                                Text("已开启")
                                    .font(.system(size: 9))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        Text("登录系统后自动在后台静默运行，无需每次手动打开")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if launchManager.requiresApproval {
                        Button("系统设置允许") {
                            launchManager.openSystemSettings()
                        }
                        .font(.caption2)
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Toggle("", isOn: Binding(
                        get: { launchManager.isLaunchAtLoginEnabled },
                        set: { launchManager.setEnabled($0) }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .scaleEffect(0.8)
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Section 6: Bottom Bar: Permissions & Reset
                if !permissionManager.isAccessibilityGranted {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("需辅助功能授权 (Accessibility)", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        
                        Text("由于更新过代码，若系统列表中已有旧项，请在系统设置中选中按【-】删除，再重新添加。")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                permissionManager.promptForPermission()
                            }) {
                                Text("1. 打开系统设置")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                            Button(action: {
                                permissionManager.revealInFinder()
                            }) {
                                Text("2. 在访达中定位")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button(action: {
                                config.resetToDefaults()
                                eventTap.cancelRecording()
                            }) {
                                Text("恢复默认")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(10)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
                    )
                } else {
                    HStack {
                        Label("系统辅助功能已就绪", systemImage: "checkmark.shield.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Button(action: {
                            config.resetToDefaults()
                            eventTap.cancelRecording()
                        }) {
                            Text("恢复默认键位 (侧键4/5)")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(16)
        }
        .frame(width: 490, height: 570)
    }
    
    @ViewBuilder
    private func directionCard(
        direction: SwitchDirection,
        title: String,
        icon: String,
        color: Color,
        currentButtonNumber: Int,
        currentButtonName: String
    ) -> some View {
        let isRecording = (eventTap.recordingDirection == direction)
        let isBound = (currentButtonNumber >= 0)
        
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            HStack {
                if isRecording {
                    // Recording State
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("🎯 请在鼠标上按下目标按键...")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    Button("取消") {
                        eventTap.cancelRecording()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                } else {
                    // Normal Display State
                    HStack(spacing: 6) {
                        Image(systemName: "computermouse.fill")
                            .font(.caption)
                        Text(isBound ? currentButtonName : "未设置")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isBound ? color.opacity(0.12) : Color.gray.opacity(0.15))
                    .foregroundColor(isBound ? color : .secondary)
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if direction == .left {
                                KeySender.shared.switchLeft()
                            } else {
                                KeySender.shared.switchRight()
                            }
                        }) {
                            Label("立即测试", systemImage: "play.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            eventTap.startRecording(direction: direction)
                        }) {
                            Label(isBound ? "重新去绑定" : "去绑定按键", systemImage: "record.circle")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(color)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isRecording ? Color.red : Color.clear, lineWidth: 1.5)
        )
    }
}
