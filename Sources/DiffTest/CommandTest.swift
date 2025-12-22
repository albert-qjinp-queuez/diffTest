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
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let testRunner = TestRunner(root: root)
        
        guard let hashKey = try? testRunner.readHash() else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        try? testRunner.makeDiff(hash: hashKey)
        try? testRunner.parseDiff(rootURL: rootURL)
        guard let testNeeded = try? testRunner.collectTestNeeded(rootURL: rootURL) else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        let skipTesting = try? testRunner.skipTesting(rootURL: rootURL, testNeed: testNeeded)
        let xcodeFile = ScriptUtil.findXcodeFilePath(url: rootURL)
        _ = try? testRunner.runTest(xcodeFile: xcodeFile, skipTest: skipTesting ?? "")
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

    func findXcodeFile(url rootURL: URL) ->  [URL]? {
        var xcodeFiles: [URL]?
        do {
            xcodeFiles = try FileManager
                .default
                .contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil)
            xcodeFiles = xcodeFiles?.filter() {
                return $0.pathExtension == "xcworkspace"
                    || $0.pathExtension == "xcodeproj"
            }
        } catch {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        return xcodeFiles
    }
}
