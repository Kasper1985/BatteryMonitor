//
//  BatterySnapshotStore.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//


import Foundation

struct BatterySnapshotStore {

    // MARK: - Configuration

    private let appGroupIdentifier = "group.com.kasper.BluetoothBatteryMonitor"
    private let storageKey = "batterySnapshot"

    // MARK: - Save

    func save(_ snapshot: BatterySnapshot) throws {

        guard let defaults = UserDefaults(
            suiteName: appGroupIdentifier
        ) else {
            throw StoreError.storageUnavailable
        }

        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)

        defaults.set(data, forKey: storageKey)
    }

    // MARK: - Load

    func load() throws -> BatterySnapshot? {

        guard let defaults = UserDefaults(
            suiteName: appGroupIdentifier
        ) else {
            throw StoreError.storageUnavailable
        }

        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }

        let decoder = JSONDecoder()

        return try decoder.decode(BatterySnapshot.self, from: data)
    }

    // MARK: - Errors

    enum StoreError: Error {
        case storageUnavailable
    }
}
