//
//  MenuBarLabelView.swift
//  BluetoothBatteryMonitor
//

import SwiftUI

/// Renders the selected devices into a compact, colored menu bar image.
enum MenuBarLabelView {
    /// The menu bar only keeps colors for non-template images, so the label is rendered to a bitmap.
    static func statusImage(for viewModel: BatteryViewModel) -> NSImage? {
        let items = viewModel.menuBarItems
        if items.isEmpty {
            let image = NSImage(systemSymbolName: "battery.100percent", accessibilityDescription: "Battery Monitor")
            image?.isTemplate = true
            return image
        }
        return renderedImage(for: items, refreshStatus: viewModel.refreshStatus)
    }

    private static func renderedImage(for items: [MenuBarItem], refreshStatus: RefreshStatus) -> NSImage? {
        let missingColor = missingColor(for: refreshStatus)
        
        let content = HStack(spacing: 8) {
            ForEach(items) { item in
                HStack(spacing: 3) {
                    Image(systemName: item.iconName)
                    Text(item.percentage.map { "\($0)%" } ?? "?")
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize() // never truncate the percentage
                }
                .foregroundStyle(item.percentage.map { Self.color(for: $0) } ?? missingColor)
            }
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 2)
        .fixedSize() // render the label at its full size
        
        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        
        guard let image = renderer.nsImage else { return nil }
        image.isTemplate = false
        return image
    }
    
    private static func color(for percentage: Int) -> Color {
        switch percentage {
        case 0..<20: .red
        case 20..<50: .orange
        default: .green
        }
    }
    
    /// Pink when a successful refresh did not find the device; gray while its state is unknown.
    private static func missingColor(for status: RefreshStatus) -> Color {
        status == .succeeded ? .pink : .gray
    }
}
