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
    
    // TODO: diff with markedHash
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
    
    
    // TODO: collect changed line numbers in diff
    func parseDiff(rootURL: URL) throws {
        
        let brokenReporter = try GitBrokenLineReporter(rootDir: rootURL)
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
    
    // TODO: get markerCoverageMapFile > perTestCoverageMap
    // TODO: collect test in changed line > testNeeded
    // TODO: get test_list > testList
    // TODO: filter testNeeded from testList > testNotNeeded
    // TODO: xcode build test with -skip-testing:testNotNeeded
    // TODO: can we create and insert TestPlan with this? - so that i can run it in Xcode UI > display result more easy
}
