//
//  TestRunnerDiff.swift
//  diffTest
//
//  Created by Albert Q Park on 9/13/25.
//

import Foundation

extension TestRunner {
    // get marked_hash.txt > markedHash
    func readHash() throws -> String? {
        let bashCommand = """
cd \(projectRoot)
cat ./.test_marker/marked_hash.txt
"""
        let markedHash = try ScriptUtil.bashScript(command: bashCommand)
        return markedHash
    }
    
    // diff with markedHash
    func makeDiff(hash: String) throws {
        let hash = hash.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        let bashCommand = """
    cd \(projectRoot)
    rm -rf \(Const.tempDirPath)
    mkdir \(Const.tempDirPath)
    git diff \(hash) > \(Const.diffFilePath)
    """
        let _ = try ScriptUtil.bashScript(command: bashCommand)
    }
    
    
    // collect changed line numbers in diff
    func parseDiff(rootURL: URL) throws {
        let brokenFileURL = rootURL
            .appending(path: Const.tempDirPath)
            .appending(path: Const.brokenFileName)
            .standardizedFileURL
        let brokenReporter = try GitBrokenLineReporter(brokenFileURL: brokenFileURL)
        let diffURL = rootURL
            .appending(path: Const.diffFilePath)
        let parser = try GitDiffStreamParser(gitDiffURL: diffURL)
        try parser.parse { hunk in
            if let filePath = hunk.old.file {
                for case let brokenLine as Int in hunk.brokenLines {
                    try brokenReporter.writeLine(lineNumber: brokenLine, filePath: filePath)
                }
            }
        }
        brokenReporter.close()
    }
    
    // get markerCoverageMapFile > perTestCoverageMap
    // collect test in changed line > testNeeded
    func collectTestNeeded(rootURL: URL) throws -> Set<String> {
        let brokenFileURL = rootURL
            .appending(path: Const.tempDirPath)
            .appending(path: Const.brokenFileName)
            .standardizedFileURL
        let coverageFileURL = rootURL
            .appending(path: Const.markerDirPath)
            .appending(path: Const.markerCoverageMapFileName)
            .standardizedFileURL
        let perTestCoverage = PerTestCoverageReporter()
        try perTestCoverage.load(coverageFileURL)
        let brokenLines = GitBrokenLineReader(url: brokenFileURL)
        var needTest = Set<String>()
        for case let broken as Broken in brokenLines {
            if let fileCoverage = perTestCoverage.perTestsCoverageMap[broken.filePath],
               let coverageMap = fileCoverage.coverageMap,
               broken.line - 1 >= 0,
               coverageMap.count > 0,
               let coverage = coverageMap[broken.line - 1], // -1 while perTestCoverage line starts from 0 index
               let coverage = coverage {
                let tests = coverage.perTestCoverages.map { $0.testIdentifier }
                tests.forEach { needTest.insert($0) }
            }
        }
        return needTest
    }
    
    // get test_list > testList
    // TODO: filter testNeeded from testList > testNotNeeded
    func skipTesting(rootURL: URL, testNeed: Set<String>) throws -> String {
        let testListFileURL = rootURL
            .appending(path: Const.markerDirPath)
            .appending(path: Const.markerTestListFileName)
            .standardizedFileURL
        var skip_testing = ""
        let reader = TestListReader(url: testListFileURL)
        for case let testID as String in reader {
            if testNeed.contains(testID) == false {
                skip_testing += " -skip-testing \"\(testID)\" "
            }
        }
        return skip_testing
    }
    
    // TODO: xcode build test with -skip-testing:testNotNeeded
    // TODO: can we create and insert TestPlan with this? - so that i can run it in Xcode UI > display result more easy
}
