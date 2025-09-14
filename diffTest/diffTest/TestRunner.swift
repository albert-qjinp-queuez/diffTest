//
//  TestRunner.swift
//  diffTest
//
//  Created by Albert Q Park on 9/6/25.
//

import Foundation

struct Const {
    static let fullTestPath = "./temp/result/full-test"
    static let xcResult = "results.xcresult"
    static let slatherReport = "report.json"
    static let tempPath = "./temp/result"
    static let markerPath = ".test_marker"
    static let markerHashPath = ".test_marker/marked_hash.txt"
    static let markerTestListFile = "test_list.txt"
    static let markerCoverageMapFile = "per_test_coverage_map.json"
}

struct TestRunner {
    let fullTestPath = Const.fullTestPath
    let xcResult = Const.xcResult
    let slatherReport = Const.slatherReport
    let tempPath = Const.tempPath
    
    var projectRoot: String
    var gitRoot: String //for now, but better to seperate if needed
    var destination = "platform=iOS Simulator,name=iPhone 16,OS=18.2" //for now, but better to get (or search)
    var xcodeFile = "DiffTestSample.xcproj" //for now, but better to get (or search)
    var schema = "DiffTestSample"  //for now, but better to get (or search)
    
    init(root: String) {
        self.projectRoot = root
        self.gitRoot = root //for now, but better to seperate this in the future
    }
    
    func installGitStretagy() throws {
        let bashCommand = """
git config --get merge.theirs-always.name >/dev/null 2>&1 || git config merge.theirs-always.name "always take theirs"
git config --get merge.theirs-always.driver >/dev/null 2>&1 || git config merge.theirs-always.driver "cp %B %A"

git config --get merge.theirs-ours.name >/dev/null 2>&1 || git config merge.theirs-ours.name "always take ours"
git config --get merge.theirs-ours.driver >/dev/null 2>&1 || git config merge.theirs-ours.driver "cp %A %A"

grep -q '^\(Const.markerPath)/' .gitattributes || echo '\(Const.markerPath)/* merge=theirs-always' >> .gitattributes
"""
        let _ = try ScriptUtil.bashScript(command: bashCommand)
    }
    
    func runTest(xcodeFile: String, test: TestModel?) throws -> URL {
        let path = test?.identifierPath() ?? fullTestPath
        var testingScope = ""
        if let identifier = test?.identifier {
            testingScope = "-only-testing:\"\(identifier)\""
        }
        let bashCommand = """
cd \(projectRoot)
xcodebuild \
-project \(xcodeFile) \
-scheme \(schema) \
-destination "\(destination)" \
-configuration Debug \
-derivedDataPath \(path)/build \
-resultBundlePath \(path)/\(xcResult) \
-enableCodeCoverage YES \
 \(testingScope) \
 test
"""
        let _ = try ScriptUtil.bashScript(command: bashCommand)
        return testResultURL(test: test)
    }

    func clean() throws {
        let bashCommand = """
cd \(projectRoot)
rm -rf \(tempPath)
"""
        let _ = try ScriptUtil.bashScript(command: bashCommand)
    }

}
