//
//  BluetoothBatteryMonitorApp.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import SwiftUI

@main
struct BluetoothBatteryMonitorApp: App {
    @NSApplicationDelegateAdaptor(BatteryMonitorAppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        let _ = appDelegate.openWindow = openWindow

        Window("Battery Monitor", id: "main") {
            ContentView(viewModel: appDelegate.viewModel)
                .hidesDockIconWhenClosed()
        }
        
        Window("Settings", id: "settings") {
            SettingsView(viewModel: appDelegate.viewModel)
                .hidesDockIconWhenClosed()
        }
        .windowResizability(.contentSize)
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
