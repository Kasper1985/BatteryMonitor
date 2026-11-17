//
//  BatteryViewModel.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
final class BatteryViewModel {
    
    // MARK: - Properties
    
    private(set) var devices: [BatteryDevice] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var lastUpdated: Date?
    
    /// IDs of devices chosen in Settings to be shown in the menu bar.
    var menuBarDeviceIDs: Set<String> = Set(
        UserDefaults.standard.stringArray(forKey: BatteryViewModel.menuBarDevicesKey) ?? []
    ) {
        didSet {
            UserDefaults.standard.set(Array(menuBarDeviceIDs), forKey: Self.menuBarDevicesKey)
        }
    }
    
    /// Selected devices that are currently connected.
    var menuBarDevices: [BatteryDevice] {
        devices.filter { menuBarDeviceIDs.contains($0.id) }
    }
    
    private let store = BatterySnapshotStore()
    
    nonisolated static let menuBarDevicesKey = "menuBarDeviceIDs"
    
    func isShownInMenuBar(_ device: BatteryDevice) -> Bool {
        menuBarDeviceIDs.contains(device.id)
    }
    
    func setShownInMenuBar(_ shown: Bool, for device: BatteryDevice) {
        if shown {
            menuBarDeviceIDs.insert(device.id)
        } else {
            menuBarDeviceIDs.remove(device.id)
        }
    }
    
    // MARK: - Initialization
    
    init() {
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
            do {
                let fetchedDevices = try await Task.detached(priority: .utility) {
                    try await BatteryMonitor().fetchDevices()
                }.value
                
                // Update application state
                self.devices = fetchedDevices
                
                // Create snapshot
                let updateDate = Date()
                self.lastUpdated = updateDate
                let snapshot = BatterySnapshot(devices: fetchedDevices, lastUpdated: updateDate)
                
                // Save snapshot for the widget
                try store.save(snapshot)
                
                // Request widget refresh
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            
            self.isLoading = false
        }
    }
}
