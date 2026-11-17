//
//  BatteryDevice.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import Foundation

struct BatteryDevice: Identifiable, Sendable, Codable {
    let id: String
    let name: String
    let percentage: Int
    
    static let lowBatteryThreshold = 20
    
    var isLowBattery: Bool {
        percentage < Self.lowBatteryThreshold
    }
    
    /// Asset name of a custom picture for known devices, if any.
    var customImageName: String? {
        let name = name.lowercased()
        if name.contains("keys") { return "mx-keys-s" }
        if name.contains("master") { return "mx-master-3s" }
        return nil
    }
    
    var iconName: String {
        let name = name.lowercased()
        
        switch true {
        case name.contains("keys"), name.contains("keyboard"):
            return "keyboard"
        case name.contains("master"), name.contains("mouse"):
            return "computermouse"
        case name.contains("airpods") && name.contains("case"):
            return "airpods.pro.gen3.chargingcase.wireless"
        case name.contains("airpods"):
            return "airpods.pro"
        default:
            return "battery.100percent"
        }
    }
}
