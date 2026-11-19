//
//  BluetoothBatteryMonitorTests.swift
//  BluetoothBatteryMonitorTests
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import Testing
@testable import Battery_Monitor

struct BluetoothBatteryMonitorTests {

    @Test func parsesBluetoothDevices() throws {
        
        // Arrange
        let output = """
        Now drawing from 'AC Power'
         -InternalBattery-0 (id=36241507) 100%; charged
         -MX Master 3S (id=54662027) 65%;
         -MX KEYS S (id=54662028) 95%;
         -AirPods Pro 3 - Yuriy (id=63378329) 80%; charging
        """

        let monitor = BatteryMonitor()

        // Act
        let devices = try monitor.parseOutput(output)

        // Assert
        #expect(devices.count == 3)

        #expect(devices[0].name == "MX Master 3S")
        #expect(devices[0].percentage == 65)

        #expect(devices[1].name == "MX KEYS S")
        #expect(devices[1].percentage == 95)

        #expect(devices[2].name == "AirPods Pro 3 - Yuriy")
        #expect(devices[2].percentage == 80)
    }

    @Test func validOutputWithoutAccessoriesReturnsEmptyList() throws {
        let output = """
        Now drawing from 'AC Power'
         -InternalBattery-0 (id=36241507) 100%; charged
        """

        let devices = try BatteryMonitor().parseOutput(output)

        #expect(devices.isEmpty)
    }

    @Test func unrecognizedOutputThrows() {
        #expect(throws: BatteryMonitor.FetchError.unrecognizedOutput) {
            try BatteryMonitor().parseOutput("")
        }
    }

}
