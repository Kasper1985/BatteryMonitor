//
//  ContentView.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import SwiftUI

struct ContentView: View {
    
    let viewModel: BatteryViewModel
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Battery Monitor")
                        .font(.largeTitle.bold())
                    
                    Text("Bluetooth accessories")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
                .help("Refresh battery levels")
            }
            
            Divider()
            
            // Device list
            if viewModel.isLoading && viewModel.devices.isEmpty {
                ProgressView("Reading battery levels...")
            } else if let error = viewModel.errorMessage, viewModel.devices.isEmpty {
                ContentUnavailableView(
                    "Unable to read batteries",
                    systemImage: "battery.0",
                    description: Text(error)
                )
            } else if viewModel.devices.isEmpty {
                ContentUnavailableView(
                    "No devices found",
                    systemImage: "bluetooth",
                    description: Text("No Bluetooth accessories reported my macOS.")
                )
            } else {
                List(viewModel.devices) { device in
                    DeviceBatteryView(device: device)
                }
                .listStyle(.inset)
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("\(viewModel.devices.count) devices detected")
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                
                if viewModel.refreshStatus == .failed, !viewModel.devices.isEmpty {
                    Label("Last refresh failed", systemImage: "exclamationmark.triangle")
                        .help(viewModel.errorMessage ?? "")
                }
                
                if let lastUpdated = viewModel.lastUpdated {
                    Text("Last update: \(lastUpdated.formatted(date: .omitted, time: .standard))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 350)
    }
}
