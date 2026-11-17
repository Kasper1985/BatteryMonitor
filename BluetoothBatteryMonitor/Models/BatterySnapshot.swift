//
//  BatterySnapshot.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import Foundation

struct BatterySnapshot: Codable {
    let devices: [BatteryDevice]
    let lastUpdated: Date
}
