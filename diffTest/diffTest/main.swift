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
        let finalReportURL = url.appending(path: ".test_marker")
        let resultReporter = TestListReporter(rootDir:  finalReportURL)
        resultReporter.prepare()
        guard let xcodeFiles = findXcodeFile(url: url),
            xcodeFiles.count > 0,
            let xcodeFile = xcodeFiles.first
        else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        let xcodeFilePath = String(xcodeFile.absoluteString.trimmingPrefix("file://"))
        print("xcodeFile : \(xcodeFilePath)")
        let perTestCoverage = PerTestCoverageReporter()
        do {
//*            try TestRunner.runBuildForTest(xcodeFile: xcodeFilePath, root: root) */
            let fullBuildResult = try TestRunner.runFullTest(xcodeFile: xcodeFilePath, root: root)
            let fullTestCoverage = try TestRunner.collectTestCoverage(xcodeFile: xcodeFilePath, root: root, test: nil)
            try perTestCoverage.readFullCoverage(fullTestCoverage)
            let testResults = TestRunner.extractTests(resultUrl: fullBuildResult)
            resultReporter.testList(tests: testResults)
            for test in testResults {
                _ = try TestRunner.runTestCoverage(xcodeFile: xcodeFilePath, root: root, test: test)
                let ptc = try TestRunner.collectTestCoverage(xcodeFile: xcodeFilePath, root: root, test: test)
                try perTestCoverage.mergeIndividualCoverage(ptc, test: test)
            }
            try perTestCoverage.save(finalReportURL)
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
