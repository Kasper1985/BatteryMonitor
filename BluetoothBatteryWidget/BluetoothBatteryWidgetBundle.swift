//
//  BluetoothBatteryWidgetBundle.swift
//  BluetoothBatteryWidget
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import WidgetKit
import SwiftUI

@main
struct BluetoothBatteryWidgetBundle: WidgetBundle {
    var body: some Widget {
        BluetoothBatterySingleDeviceWidget()
        BluetoothBatteryWidget()
        BluetoothBatteryWidgetControl()
    }
}
