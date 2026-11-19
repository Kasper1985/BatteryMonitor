//
//  BatteryMonitor.swift
//  BluetoothBatteryMonitor
//
//  Created by Yuriy Varshavskyy on 06.11.26.
//

import Foundation

struct BatteryMonitor {
    
    nonisolated enum FetchError: LocalizedError, Equatable {
        case commandFailed(status: Int32)
        case unreadableOutput
        case unrecognizedOutput
        
        var errorDescription: String? {
            switch self {
            case .commandFailed(let status):
                "pmset exited with status \(status)."
            case .unreadableOutput:
                "pmset output could not be read."
            case .unrecognizedOutput:
                "pmset output has an unexpected format."
            }
        }
    }
    
    /// Header line `pmset -g accps` prints whenever it reports power sources successfully.
    private static let outputHeader = "Now drawing from"
    
    /// Returns the connected accessories. An empty array means macOS reported no accessories;
    /// failures and unexpected output are thrown instead.
    func fetchDevices() throws -> [BatteryDevice] {
        
        // 1. Create a process to execute pmset
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "accps"]
        
        // 2. Capture the command output
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice
        
        // 3. Execute the process
        try process.run()
        
        // 4. Read the output before waiting, so a full pipe buffer can't block the process
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw FetchError.commandFailed(status: process.terminationStatus)
        }
        
        guard let output = String(data: outputData, encoding: .utf8) else {
            throw FetchError.unreadableOutput
        }
        
        // 5. Parse the output
        return try parseOutput(output)
    }
    
    func parseOutput(_ output: String) throws -> [BatteryDevice] {
        guard output.contains(Self.outputHeader) else {
            throw FetchError.unrecognizedOutput
        }
        
        let pattern = #"^\s*-(.*?)\s+\(id=(\d+)\)\s+(\d+)%"#
        
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.anchorsMatchLines]
        ) else {
            throw FetchError.unrecognizedOutput
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
