//
//  MenuBarLabelView.swift
//  BluetoothBatteryMonitor
//

import SwiftUI

/// Compact, colored label shown in the macOS menu bar.
struct MenuBarLabelView: View {
    
    let viewModel: BatteryViewModel
    
    @AppStorage(RefreshSettings.intervalKey)
    private var refreshInterval = RefreshSettings.defaultInterval
    
    var body: some View {
        label
            .task(id: refreshInterval) {
                guard refreshInterval > 0 else { return }
                
                // Restarts automatically when the interval setting changes
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(refreshInterval))
                    guard !Task.isCancelled else { break }
                    viewModel.refresh()
                }
            }
    }
    
    @ViewBuilder
    private var label: some View {
        let devices = viewModel.menuBarDevices
        
        if devices.isEmpty {
            Image(systemName: "battery.100percent")
        } else if let image = renderedImage(for: devices) {
            Image(nsImage: image)
        } else {
            Text(devices.map { "\($0.percentage)%" }.joined(separator: " "))
        }
    }
    
    /// The menu bar only keeps colors for non-template images, so the label is rendered to a bitmap.
    private func renderedImage(for devices: [BatteryDevice]) -> NSImage? {
        let content = HStack(spacing: 8) {
            ForEach(devices) { device in
                HStack(spacing: 3) {
                    Image(systemName: device.iconName)
                    Text("\(device.percentage)%")
                        .monospacedDigit()
                }
                .foregroundStyle(Self.color(for: device))
            }
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 2)
        
        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        
        guard let image = renderer.nsImage else { return nil }
        image.isTemplate = false
        return image
    }
    
    private static func color(for device: BatteryDevice) -> Color {
        switch device.percentage {
        case 0..<20: .red
        case 20..<50: .orange
        default: .green
        }
    }
}
