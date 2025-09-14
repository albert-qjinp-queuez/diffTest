//
//  CommandTest.swift
//  diffTest
//
//  Created by Albert Q Park on 9/13/25.
//

import Foundation
import ArgumentParser

struct Test: ParsableCommand {
    @Option(name: .shortAndLong, help: "root directory of the project")
    var root: String?
    
    func run() {
        let args = CommandLine.arguments
        print("args: \(args)")
        let root = root ?? runningRoot()
        let url = URL(filePath: root, directoryHint: .isDirectory)
        let finalReportURL = url.appending(path: Const.markerPath)
        
    }
    
    func runningRoot() -> String {
        if let root = root  {
            return root
        }
        let args = CommandLine.arguments
        guard args.count > 1 else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        let runningPath: NSString = args[0] as NSString
        return runningPath.deletingLastPathComponent
    }
}
