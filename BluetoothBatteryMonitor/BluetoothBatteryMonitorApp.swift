//
//  BluetoothBatteryMonitorApp.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import SwiftUI

@main
struct BluetoothBatteryMonitorApp: App {
    
    @State private var viewModel = BatteryViewModel()
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        MenuBarExtra {
            if viewModel.devices.isEmpty {
                Text("No devices found")
            } else {
                Text("Show in menu bar")
                
                ForEach(viewModel.devices) { device in
                    Toggle(isOn: Binding(
                        get: { viewModel.isShownInMenuBar(device) },
                        set: { viewModel.setShownInMenuBar($0, for: device) }
                    )) {
                        Label(
                            "\(device.name): \(device.percentage)%",
                            systemImage: device.iconName
                        )
                    }
                }
            }
            
            Divider()
            
            Button("Refresh") {
                viewModel.refresh()
            }
            .keyboardShortcut("r")
            
            Button("Open Battery Monitor") {
                show(windowID: "main")
            }
            
            Button("Settings…") {
                show(windowID: "settings")
            }
            .keyboardShortcut(",")
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            MenuBarLabelView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.menu)
        
        Window("Battery Monitor", id: "main") {
            ContentView(viewModel: viewModel)
                .hidesDockIconWhenClosed()
        }
        
        Window("Settings", id: "settings") {
            SettingsView(viewModel: viewModel)
                .hidesDockIconWhenClosed()
        }
        .windowResizability(.contentSize)
    }
    
    /// Menu-bar-only apps can't bring windows to the front, so the app temporarily becomes a regular app.
    private func show(windowID: String) {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: windowID)
        NSApp.activate()
    }
}

private struct HidesDockIconWhenClosed: ViewModifier {
    func body(content: Content) -> some View {
        content.onDisappear {
            Task { @MainActor in
                let hasWindow = NSApp.windows.contains { $0.isVisible && $0.styleMask.contains(.titled) }
                if !hasWindow {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }
}

private extension View {
    func hidesDockIconWhenClosed() -> some View {
        modifier(HidesDockIconWhenClosed())
    }
}
