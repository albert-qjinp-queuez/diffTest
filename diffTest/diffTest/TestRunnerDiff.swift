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
        var hash = hash.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        let bashCommand = """
    cd \(projectRoot)
    mkdir temp
    git diff \(hash) > \(Const.diffPath)
    """
        let _ = try ScriptUtil.bashScript(command: bashCommand)
    }
    
    // TODO: collect changed line numbers in diff
    func parseDiff(rootURL: URL) throws {
        let diffURL = rootURL.appending(path: Const.diffPath)
        let parser = try GitDiffStreamParser(url: diffURL)
        parser.parse { hunk in
            print("hunk.old \(hunk.old.file)")
            print("hunk.new \(hunk.new.file)")
            print("hunk.broakenLines \(hunk.broakenLines)")
        }
    }
    
    // TODO: get markerCoverageMapFile > perTestCoverageMap
    // TODO: collect test in changed line > testNeeded
    // TODO: get test_list > testList
    // TODO: filter testNeeded from testList > testNotNeeded
    // TODO: xcode build test with -skip-testing:testNotNeeded
    // TODO: can we create and insert TestPlan with this? - so that i can run it in Xcode UI > display result more easy
}
