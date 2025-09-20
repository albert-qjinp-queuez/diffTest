//
//  ScriptUtil.swift
//  diffTest
//
//  Created by Albert Q Park on 9/13/25.
//

import Foundation


struct ScriptUtil {
    static func bashScript(command: String) throws -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-l", "-c", command]
        print("bash command: \n\n")
        print(command)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        var totalScript = ""
        // 백그라운드에서 읽기
        pipe.fileHandleForReading.readabilityHandler = { handle in
            if let line = String(data: handle.availableData, encoding: .utf8),
               !line.isEmpty {
                print("SCRIPT:", line)
                totalScript += line
            }
        }

        process.waitUntilExit()

        pipe.fileHandleForReading.readabilityHandler = nil
        return totalScript
    }
}
