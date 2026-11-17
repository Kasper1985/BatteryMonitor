//
//  DeviceBatteryView.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import SwiftUI

struct DeviceBatteryView: View {
    let device: BatteryDevice
    
    private var batteryColor: Color {
        switch device.percentage {
        case 0..<20:
            return .red
        case 20..<50:
            return .orange
        default:
            return .green
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let imageName = device.customImageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: device.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(batteryColor)
                }
            }
            .frame(width: 56, height: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(device.name)
                    .font(.headline)
                
                Text("Bluetooth accessory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(device.percentage)%")
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(batteryColor)
        }
        .padding(.vertical, 8)
    }
}
