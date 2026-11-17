//
//  AppIntent.swift
//  BluetoothBatteryWidget
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import WidgetKit
import AppIntents

// MARK: - Device Options

/// Offers the names of the devices the app last saw. Plain strings are used because
/// the widget can't resolve custom AppEntity values on macOS.
struct DeviceNameOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let devices = (try? BatterySnapshotStore().load())?.devices ?? []
        return devices.map(\.name)
    }
}

// MARK: - Configuration Intents

/// Medium (and large) widget: the devices to show. Empty means all devices.
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Devices" }
    static var description: IntentDescription { "Choose which devices the widget shows." }
    
    @Parameter(title: "Devices", optionsProvider: DeviceNameOptionsProvider())
    var devices: [String]?
    
    init() {}
}

/// Small widget: the single device to show.
struct SingleDeviceIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Device" }
    static var description: IntentDescription { "Choose which device the widget shows." }
    
    @Parameter(title: "Device", optionsProvider: DeviceNameOptionsProvider())
    var device: String?
    
    init() {}
}
