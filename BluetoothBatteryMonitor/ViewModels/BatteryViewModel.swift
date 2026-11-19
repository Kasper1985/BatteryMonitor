//
//  BatteryViewModel.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import Foundation
import Observation
import WidgetKit

/// One selected device as shown in the menu bar.
struct MenuBarItem: Identifiable {
    let id: String
    let iconName: String
    /// `nil` when the device was not reported by the latest refresh.
    let percentage: Int?
}

enum RefreshStatus {
    case notRefreshed
    case succeeded
    case failed
}

@Observable
@MainActor
final class BatteryViewModel {
    
    // MARK: - Properties
    
    /// Devices from the last successful refresh. Kept unchanged when a refresh fails.
    private(set) var devices: [BatteryDevice] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var lastUpdated: Date?
    private(set) var refreshStatus: RefreshStatus = .notRefreshed
    
    /// Names of the devices chosen for the menu bar. Names stay the same when macOS
    /// assigns a new ID to an accessory after a reconnect.
    var menuBarDeviceNames: Set<String> = Set(
        UserDefaults.standard.stringArray(forKey: BatteryViewModel.menuBarDeviceNamesKey) ?? []
    ) {
        didSet {
            UserDefaults.standard.set(Array(menuBarDeviceNames), forKey: Self.menuBarDeviceNamesKey)
        }
    }
    
    /// Selected devices for the menu bar. A selected device that the latest refresh did not
    /// report is included with a `nil` percentage.
    var menuBarItems: [MenuBarItem] {
        menuBarDeviceNames.sorted().map { name in
            let device = devices.first { $0.name == name }
            return MenuBarItem(
                id: name,
                iconName: (device ?? BatteryDevice(id: name, name: name, percentage: 0)).iconName,
                percentage: device?.percentage
            )
        }
    }
    
    private let store = BatterySnapshotStore()
    
    nonisolated static let menuBarDeviceNamesKey = "menuBarSelectedDeviceNames"
    
    /// Keys of the former ID-based selection, which collected stale IDs.
    private static let legacySelectionKeys = ["menuBarDeviceIDs", "menuBarDeviceNames"]
    
    func isShownInMenuBar(_ device: BatteryDevice) -> Bool {
        menuBarDeviceNames.contains(device.name)
    }
    
    func setShownInMenuBar(_ shown: Bool, for device: BatteryDevice) {
        if shown {
            menuBarDeviceNames.insert(device.name)
        } else {
            menuBarDeviceNames.remove(device.name)
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // The old ID-based selection can't be converted (stale IDs have no names); devices are selected once more.
        for key in Self.legacySelectionKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        refresh()
    }
    
    // MARK: - Actions
    
    func refresh() {
        
        guard !isLoading else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            defer { self.isLoading = false }
            
            let fetchedDevices: [BatteryDevice]
            do {
                fetchedDevices = try await Task.detached(priority: .utility) {
                    try await BatteryMonitor().fetchDevices()
                }.value
            } catch {
                // Keep the last successful readings; only report the failure.
                self.errorMessage = error.localizedDescription
                self.refreshStatus = .failed
                return
            }
            
            // Update application state
            self.devices = fetchedDevices
            self.refreshStatus = .succeeded
            
            // Create snapshot
            let updateDate = Date()
            self.lastUpdated = updateDate
            let snapshot = BatterySnapshot(devices: fetchedDevices, lastUpdated: updateDate)
            
            // Save snapshot for the widget. A storage failure doesn't invalidate the readings.
            do {
                try store.save(snapshot)
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("Failed to save battery snapshot: \(error)")
            }
        }
    }
}
