//
//  TestRunner.swift
//  diffTest
//
//  Created by Albert Q Park on 9/6/25.
//

import Foundation

struct Const {
    static let tempDirPath = "./temp"
    static let fullTestDirPath = "./temp/result/full-test"
    static let tempResultDirPath = "./temp/result"
    static let markerDirPath = ".test_marker"
    static let xcResultFileName = "results.xcresult"
    static let slatherReportFileNaem = "report.json"
    static let markerTestListFileName = "test_list.txt"
    static let markerCoverageMapFileName = "per_test_coverage_map.json"
    static let brokenFileName = "broken.txt"
    static let markerHashFilePath = ".test_marker/marked_hash.txt"
    static let diffFilePath = "./temp/diff.txt"
}

struct TestRunner {
    let fullTestPath = Const.fullTestDirPath
    let xcResult = Const.xcResultFileName
    let slatherReport = Const.slatherReportFileNaem
    let tempResultPath = Const.tempResultDirPath
    
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

grep -q '^\(Const.markerDirPath)/' .gitattributes || echo '\(Const.markerDirPath)/* merge=theirs-always' >> .gitattributes
"""
        let _ = try ScriptUtil.bashScript(command: bashCommand)
    }
    
    func runTest(xcodeFile: String, testOnly: TestModel? = nil, skipTest: String = "") throws -> URL {
        let path = testOnly?.identifierPath() ?? fullTestPath
        var testingScope = ""
        if let identifier = testOnly?.identifier {
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
 \(skipTest) \
 test
"""
        let _ = try ScriptUtil.bashScript(command: bashCommand)
        return testResultURL(test: testOnly)
    }

    func clean() throws {
        let bashCommand = """
cd \(projectRoot)
rm -rf \(tempResultPath)
"""
        let _ = try ScriptUtil.bashScript(command: bashCommand)
    }

}
