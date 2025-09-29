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

    @Argument(help: "default: buildonly and testonly, nobuild: use old build file, full: every test will do the full build testing")
    var runFullTest = "default"
    
    @Argument(help: "bypass individual tests if result is already exists")
    var runPerTest = true
    
    func run() {
        let args = CommandLine.arguments
        print("args: \(args)")
        let root = root ?? runningRoot()
        let url = URL(filePath: root, directoryHint: .isDirectory)
        let finalReportURL = url.appending(path: Const.markerDirPath)
        let resultReporter = TestListReporter(markerRootURL:  finalReportURL)
        resultReporter.prepare()
        let xcodeFilePath = ScriptUtil.findXcodeFilePath(url: url)

        let perTestCoverage = PerTestCoverageReporter()
        let testRunner = TestRunner(root: root)
        do {
            let fullBuildResult: URL
            switch runFullTest {
            case "nobuild":
                fullBuildResult = testRunner.testResultURL(test: nil)
            case "full":
                fullBuildResult = try testRunner.runFullTest(xcodeFile: xcodeFilePath)
            default:
                _ = try testRunner.runFullBuild(xcodeFile: xcodeFilePath)
                fullBuildResult = try testRunner.runFullTest(xcodeFile: xcodeFilePath, mode: .testOnly)
            }
            let fullTestCoverage = try testRunner.collectTestCoverage(xcodeFile: xcodeFilePath, test: nil)
            try perTestCoverage.readFullCoverage(fullTestCoverage)
            let testResults = testRunner.extractTests(resultUrl: fullBuildResult)
            resultReporter.testList(tests: testResults)
            for test in testResults {
                if runPerTest {
                    _ = try testRunner.runTestCoverage(xcodeFile: xcodeFilePath, test: test, mode: .testOnly)
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
}
