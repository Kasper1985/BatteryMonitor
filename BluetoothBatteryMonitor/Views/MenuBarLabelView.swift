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
        let items = viewModel.menuBarItems
        
        if items.isEmpty {
            Image(systemName: "battery.100percent")
        } else if let image = renderedImage(for: items) {
            Image(nsImage: image)
        } else {
            Text(items.map { $0.percentage.map { "\($0)%" } ?? "?" }.joined(separator: " "))
        }
    }
    
    /// The menu bar only keeps colors for non-template images, so the label is rendered to a bitmap.
    private func renderedImage(for items: [MenuBarItem]) -> NSImage? {
        let missingColor = Self.missingColor(for: viewModel.refreshStatus)
        
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
