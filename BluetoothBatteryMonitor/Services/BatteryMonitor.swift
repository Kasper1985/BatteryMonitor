//
//  BatteryMonitor.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import Foundation

struct BatteryMonitor {
    func fetchDevices() throws -> [BatteryDevice] {
        
        // 1. Create a process to execute pmset
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "accps"]
        
        // 2. Capture the command output
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        // 3. Execute the process
        try process.run()
        
        // 4. Wait until execution finishes
        process.waitUntilExit()
        
        // 5. Read the output
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let output = String(data: outputData, encoding: .utf8) else {
            return []
        }
        
        // 6. Parse the output
        return parseOutput(output)
    }
    
    func parseOutput(_ output: String) -> [BatteryDevice] {
        let pattern = #"^\s*-(.*?)\s+\(id=(\d+)\)\s+(\d+)%"#
        
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.anchorsMatchLines]
        ) else {
            return []
        }
        
        let range = NSRange(output.startIndex..., in: output)
        let matches = regex.matches(in: output, range: range)
        
        return matches.compactMap { match in
            guard
                let nameRange = Range(match.range(at: 1), in: output),
                let idRange = Range(match.range(at: 2), in: output),
                let percentageRange = Range(match.range(at: 3), in: output)
                    else {
                return nil
            }
            
            let name = String(output[nameRange])
            let id = String(output[idRange])
            let percentage = Int(output[percentageRange]) ?? 0
            
            // Ignore the Mac's internal Bateery
            guard !name.hasPrefix("InternalBattery") else {
                return nil
            }
            
            return BatteryDevice(id: id, name: name, percentage: percentage)
        }
    }
}
