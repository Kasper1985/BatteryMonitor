# Bluetooth Battery Monitor

A macOS menu bar app for checking the battery levels of connected Bluetooth accessories. It reads the accessory data reported by macOS, keeps the latest readings available to its widgets, and lets you choose which devices to keep visible in the menu bar.

## Requirements

- macOS 27.2 or later
- Xcode with the macOS SDK
- A Bluetooth accessory that macOS reports with a battery level

The app has no third-party package dependencies.

## Run the app

1. Open `BluetoothBatteryMonitor.xcodeproj` in Xcode.
2. Select the **BluetoothBatteryMonitor** scheme and a Mac run destination.
3. Click **Run** (or press **Command-R**).

The app starts in the menu bar. Open its menu and choose **Open Battery Monitor** to see the full device list, or **Settings…** to adjust the app.

## Features

- **Accessory battery readings:** Uses `/usr/bin/pmset -g accps` and excludes the Mac's internal battery. Only accessories and battery levels reported by macOS can be shown.
- **At-a-glance menu bar display:** Choose which connected devices appear in the menu bar. Battery levels are colored red below 20%, orange from 20–49%, and green at 50% or above.
- **Manual and automatic refresh:** Refresh from the app or menu bar menu, or choose an interval from manual-only to every hour. Automatic refresh defaults to every five minutes.
- **Battery widgets:** Add a small widget for one selected accessory, a medium widget for up to four selected accessories, or a large widget listing all detected devices. Widgets display the latest snapshot saved by the app and request timeline updates every 15 minutes.
- **Launch at login:** Enable or disable automatic launch in Settings.
- **Accessory-specific visuals:** Common keyboards, mice, and AirPods use matching system icons; Logitech MX Keys and MX Master devices have custom artwork in supported views.
- **Menu-bar-first behavior:** The app can open its monitor and settings windows on demand, then return to a menu-bar-only presence when those windows close.

The widget extension also currently includes a sample Timer control from the Xcode template; it is unrelated to battery monitoring.

## Using widgets

After running the app once so it can save a device snapshot, open Notification Center's widget gallery and add **Device Battery** (small) or **Bluetooth Battery Monitor** (medium or large). Configure the small widget with one accessory and the medium widget with the accessories to display. The small widget falls back to the first known accessory when none is selected; the large widget lists all detected devices.

## Tests

In Xcode, select the **BluetoothBatteryMonitor** scheme and choose **Product > Test**. The unit test covers parsing accessory entries and ignoring the Mac's internal battery.
