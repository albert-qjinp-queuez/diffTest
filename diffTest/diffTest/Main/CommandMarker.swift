//
//  CommandMarker.swift
//  diffTest
//
//  Created by Albert Q Park on 9/13/25.
//

import Foundation
import ArgumentParser

struct Mark: ParsableCommand {
    @Option(name: .shortAndLong, help: "root directory of the project")
    var root: String?

    @Argument(help: "bypass full test if result is already exists")
    var runFullTest = true
    
    @Argument(help: "bypass individual tests if result is already exists")
    var runPerTest = true
    
    func run() {
        let args = CommandLine.arguments
        print("args: \(args)")
        let root = root ?? runningRoot()
        let url = URL(filePath: root, directoryHint: .isDirectory)
        let finalReportURL = url.appending(path: Const.markerPath)
        let resultReporter = TestListReporter(rootDir:  finalReportURL)
        resultReporter.prepare()
        guard let xcodeFiles = findXcodeFile(url: url),
            xcodeFiles.count > 0,
            let xcodeFile = xcodeFiles.first
        else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        let xcodeFilePath = String(xcodeFile.absoluteString.trimmingPrefix("file://"))

        let perTestCoverage = PerTestCoverageReporter()
        let testRunner = TestRunner(root: root)
        do {
            let fullBuildResult: URL
            if runFullTest {
                fullBuildResult = try testRunner.runFullTest(xcodeFile: xcodeFilePath)
            } else {
                fullBuildResult = testRunner.testResultURL(test: nil)
            }
            let fullTestCoverage = try testRunner.collectTestCoverage(xcodeFile: xcodeFilePath, test: nil)
            try perTestCoverage.readFullCoverage(fullTestCoverage)
            let testResults = testRunner.extractTests(resultUrl: fullBuildResult)
            resultReporter.testList(tests: testResults)
            for test in testResults {
                if runPerTest {
                    _ = try testRunner.runTestCoverage(xcodeFile: xcodeFilePath, test: test)
                }
                let ptcResultURL: URL
                ptcResultURL = try testRunner.collectTestCoverage(xcodeFile: xcodeFilePath, test: test)
                try perTestCoverage.mergeIndividualCoverage(ptcResultURL, test: test)
            }
            try perTestCoverage.save(finalReportURL)

            if testRunner.checkTag() {
                try testRunner.commit(message: "")
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
