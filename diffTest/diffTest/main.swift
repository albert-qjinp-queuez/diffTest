//
//  main.swift
//  diffTest
//
//  Created by Albert Q Park on 9/6/25.
//

import Foundation
import ArgumentParser

enum DiffTestError: Error {
    case unkown
}

struct Mark: ParsableCommand {
    @Option(name: .shortAndLong, help: "root directory of the project")
    var root: String?
    
    func run() {
        let args = CommandLine.arguments
        print("args: \(args)")
        let root = root ?? runningRoot()
        let url = URL(filePath: root, directoryHint: .isDirectory)
        let resultReporter = ResultReporter(rootDir: url.appending(path: ".test_marker") )
        resultReporter.prepare()
        guard let xcodeFiles = findXcodeFile(url: url),
            xcodeFiles.count > 0,
            let xcodeFile = xcodeFiles.first
            , let fullBuildResult = URL(string: root + "/temp/result/total-test/results.xcresult")
        else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        let xcodeFilePath = String(xcodeFile.absoluteString.trimmingPrefix("file://"))
        print("xcodeFile : \(xcodeFilePath)")
        
        do {
//            try TestRunner.runBuildForTest(xcodeFile: xcodeFilePath, root: root)
//            _ = try TestRunner.runFullTest(xcodeFile: xcodeFilePath, root: root)
            let testResults = TestRunner.extractTests(resultUrl: fullBuildResult)
            resultReporter.testList(tests: testResults)
            for test in testResults {
//                _ = try TestRunner.runTestCoverage(xcodeFile: xcodeFilePath, root: root, test: test)
                try TestRunner.collectTestCoverage(xcodeFile: xcodeFilePath,root: root, test: test)
            }
            
        } catch {
            DiffTest.exit(withError: error)
        }
        print("done")
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

struct DiffTest: ParsableCommand {
    static var configuration = CommandConfiguration(
        subcommands: [Mark.self]
    )
}

DiffTest.main()
