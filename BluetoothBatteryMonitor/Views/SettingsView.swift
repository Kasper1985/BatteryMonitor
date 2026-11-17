//
//  SettingsView.swift
//  BluetoothBatteryMonitor
//

import SwiftUI
import ServiceManagement

enum RefreshSettings {
    static let intervalKey = "refreshIntervalSeconds"
    static let defaultInterval = 300
    
    /// Interval in seconds; 0 disables automatic refresh.
    static let options: [(title: String, seconds: Int)] = [
        ("Manual only", 0),
        ("Every 30 seconds", 30),
        ("Every minute", 60),
        ("Every 2 minutes", 120),
        ("Every 3 minutes", 180),
        ("Every 5 minutes", 300),
        ("Every 15 minutes", 900),
        ("Every 30 minutes", 1800),
        ("Every hour", 3600)
    ]
}

struct SettingsView: View {
    
    let viewModel: BatteryViewModel
    
    @AppStorage(RefreshSettings.intervalKey)
    private var interval = RefreshSettings.defaultInterval
    
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
            
            Picker("Refresh interval", selection: $interval) {
                ForEach(RefreshSettings.options, id: \.seconds) { option in
                    Text(option.title).tag(option.seconds)
                }
            }
            
            Section("Show in menu bar") {
                if viewModel.devices.isEmpty {
                    Text("No devices found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.devices) { device in
                        Toggle(isOn: Binding(
                            get: { viewModel.isShownInMenuBar(device) },
                            set: { viewModel.setShownInMenuBar($0, for: device) }
                        )) {
                            Label(device.name, systemImage: device.iconName)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
