//
//  BluetoothBatteryWidget.swift
//  BluetoothBatteryWidget
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    private let store = BatterySnapshotStore()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), snapshot: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, snapshot: try? store.load())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration, snapshot: try? store.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let snapshot: BatterySnapshot?
}

// MARK: - Widget View

struct BluetoothBatteryWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: Provider.Entry

    private var devices: [BatteryDevice] {
        entry.snapshot?.devices ?? []
    }

    /// Devices chosen in the widget configuration; all devices when none are chosen.
    private var selectedDevices: [BatteryDevice] {
        let selectedNames = Set(entry.configuration.devices ?? [])
        guard !selectedNames.isEmpty else { return devices }
        return devices.filter { selectedNames.contains($0.name) }
    }

    var body: some View {
        Group {
            switch family {

            case .systemLarge:
                largeLayout

            default:
                mediumLayout
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Layout

    private var mediumLayout: some View {
        HStack(spacing: 20) {
            ForEach(selectedDevices.prefix(4)) { device in
                VStack(spacing: 8) {
                    batteryRing(device, size: 60, showPercentage: false)

                    Text("\(device.percentage)%")
                        .font(.caption.bold())
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
    }

    // MARK: - Large Layout

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Battery Status").font(.headline)

                    Spacer()

                    if let lastUpdated = entry.snapshot?.lastUpdated {
                        Text(lastUpdated, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 12)

                if let devices = entry.snapshot?.devices, !devices.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(devices) { device in
                            HStack(spacing: 12) {
                                Image(systemName: deviceIcon(for: device.name))
                                    .font(.system(size: 18))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28)

                                Text(device.name)
                                    .font(.system(.body, design: .rounded))
                                    .lineLimit(1)

                                Spacer()

                                Text("\(device.percentage)%")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(batteryColor(for: device.percentage))
                            }
                            .padding(.vertical, 10)

                            if device.id != devices.last?.id {
                                Divider()
                            }
                        }
                    }
                } else {
                    Text("No battery devices found")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
    }

    // MARK: - Battery Ring

    private func batteryRing(_ device: BatteryDevice, size: CGFloat, showPercentage: Bool = true) -> some View {
        BatteryRingView(name: device.name, percentage: device.percentage, size: size, showPercentage: showPercentage)
    }

    // MARK: - Device Icon

    private func deviceIcon(for name: String) -> String {
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

    // MARK: - Battery Color

    private func batteryColor(for percentage: Int) -> Color {
        switch percentage {

        case 0..<20:
            return .red

        case 20..<50:
            return .orange

        default:
            return .green
        }
    }
}

// MARK: - Battery Ring

/// Device icon surrounded by a ring showing the battery level. A nil percentage means the device is unavailable.
struct BatteryRingView: View {
    let name: String
    let percentage: Int?
    let size: CGFloat
    var showPercentage = true
    var usesCustomImage = false
    
    /// Asset name of a custom picture for known devices, if any.
    private var customImageName: String? {
        guard usesCustomImage else { return nil }
        return BatteryDevice(id: "", name: name, percentage: 0).customImageName
    }
    
    private var color: Color {
        guard let percentage else { return .secondary }
        
        switch percentage {
        case 0..<20: return .red
        case 20..<50: return .orange
        default: return .green
        }
    }
    
    private var iconName: String {
        BatteryDevice(id: "", name: name, percentage: percentage ?? 0).iconName
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: size * 0.09)
            
            Circle()
                .trim(from: 0, to: CGFloat(percentage ?? 0) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                if let customImageName {
                    Image(customImageName)
                        .resizable()
                        .widgetAccentedRenderingMode(.fullColor)
                        .scaledToFit()
                        .frame(width: size * 0.55, height: size * 0.4)
                        .opacity(percentage == nil ? 0.4 : 1)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: size * (showPercentage ? 0.4 : 0.5)))
                        .foregroundStyle(percentage == nil ? .secondary : .primary)
                }
                
                if showPercentage {
                    Text(percentage.map { "\($0)%" } ?? "–")
                        .font(.system(size: size * 0.2, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Small Widget (single device)

struct SingleDeviceEntry: TimelineEntry {
    let date: Date
    let name: String
    let percentage: Int?
}

struct SingleDeviceProvider: AppIntentTimelineProvider {
    private let store = BatterySnapshotStore()
    
    func placeholder(in context: Context) -> SingleDeviceEntry {
        SingleDeviceEntry(date: Date(), name: "Keyboard", percentage: 80)
    }
    
    func snapshot(for configuration: SingleDeviceIntent, in context: Context) async -> SingleDeviceEntry {
        entry(for: configuration)
    }
    
    func timeline(for configuration: SingleDeviceIntent, in context: Context) async -> Timeline<SingleDeviceEntry> {
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry(for: configuration)], policy: .after(nextUpdate))
    }
    
    /// Uses the configured device, or the first known device when none is chosen.
    private func entry(for configuration: SingleDeviceIntent) -> SingleDeviceEntry {
        let devices = (try? store.load())?.devices ?? []
        
        if let chosen = configuration.device {
            let match = devices.first { $0.name == chosen }
            return SingleDeviceEntry(date: Date(), name: chosen, percentage: match?.percentage)
        }
        
        if let first = devices.first {
            return SingleDeviceEntry(date: Date(), name: first.name, percentage: first.percentage)
        }
        
        return SingleDeviceEntry(date: Date(), name: "No device", percentage: nil)
    }
}

struct SingleDeviceWidgetView: View {
    let entry: SingleDeviceEntry
    
    var body: some View {
        VStack(spacing: 8) {
            BatteryRingView(name: entry.name, percentage: entry.percentage, size: 90, usesCustomImage: true)
            
            Text(entry.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct BluetoothBatterySingleDeviceWidget: Widget {
    let kind: String = "BluetoothBatterySingleDeviceWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SingleDeviceIntent.self, provider: SingleDeviceProvider()) { entry in
            SingleDeviceWidgetView(entry: entry)
        }
        .configurationDisplayName("Device Battery")
        .description("Shows the battery level of one device.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Widget Configuration

struct BluetoothBatteryWidget: Widget {
    let kind: String = "BluetoothBatteryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) {
            entry in BluetoothBatteryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bluetooth Battery Monitor")
        .description("Monitor your Bluetooth device batteries.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

