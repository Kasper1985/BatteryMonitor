import AppKit
import Observation
import SwiftUI

@MainActor
final class BatteryMonitorAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let viewModel = BatteryViewModel()
    var openWindow: OpenWindowAction?

    private var statusItem: NSStatusItem?
    private var refreshTask: Task<Void, Never>?
    private var defaultsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // AppKit's status item participates in the system's "Allow in the Menu Bar" setting.
        // Do not set isVisible ourselves: macOS owns that preference, not the device selection.
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item

        observeLabel()
        restartRefreshTimer()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.restartRefreshTimer() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTask?.cancel()
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    private func observeLabel() {
        withObservationTracking {
            updateLabel()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in self?.observeLabel() }
        }
    }

    private func updateLabel() {
        guard let button = statusItem?.button else { return }
        button.image = MenuBarLabelView.statusImage(for: viewModel)
        button.title = button.image == nil ? viewModel.menuBarItems.map {
            $0.percentage.map { "\($0)%" } ?? "?"
        }.joined(separator: " ") : ""
        button.toolTip = "Battery Monitor"
    }

    private func restartRefreshTimer() {
        refreshTask?.cancel()
        let interval = UserDefaults.standard.object(forKey: RefreshSettings.intervalKey) as? Int
            ?? RefreshSettings.defaultInterval
        guard interval > 0 else { return }

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                self?.viewModel.refresh()
            }
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if viewModel.devices.isEmpty {
            let empty = NSMenuItem(title: "No devices found", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            let heading = NSMenuItem(title: "Show in menu bar", action: nil, keyEquivalent: "")
            heading.isEnabled = false
            menu.addItem(heading)
            for device in viewModel.devices {
                let entry = NSMenuItem(
                    title: "\(device.name): \(device.percentage)%",
                    action: #selector(toggleDevice(_:)), keyEquivalent: ""
                )
                entry.target = self
                entry.representedObject = device.name
                entry.state = viewModel.isShownInMenuBar(device) ? .on : .off
                entry.image = NSImage(systemSymbolName: device.iconName, accessibilityDescription: nil)
                menu.addItem(entry)
            }
        }

        menu.addItem(.separator())
        addAction("Refresh", selector: #selector(refresh), shortcut: "r", to: menu)
        addAction("Open Battery Monitor", selector: #selector(openMainWindow), to: menu)
        addAction("Settings…", selector: #selector(openSettingsWindow), shortcut: ",", to: menu)
        menu.addItem(.separator())
        addAction("Quit", selector: #selector(quit), shortcut: "q", to: menu)
    }

    private func addAction(_ title: String, selector: Selector, shortcut: String = "", to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: shortcut)
        item.target = self
        menu.addItem(item)
    }

    @objc private func toggleDevice(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String,
              let device = viewModel.devices.first(where: { $0.name == name }) else { return }
        viewModel.setShownInMenuBar(!viewModel.isShownInMenuBar(device), for: device)
    }

    @objc private func refresh() { viewModel.refresh() }
    @objc private func openMainWindow() { show(windowID: "main") }
    @objc private func openSettingsWindow() { show(windowID: "settings") }
    @objc private func quit() { NSApp.terminate(nil) }

    private func show(windowID: String) {
        NSApp.setActivationPolicy(.regular)
        openWindow?(id: windowID)
        NSApp.activate()
    }
}