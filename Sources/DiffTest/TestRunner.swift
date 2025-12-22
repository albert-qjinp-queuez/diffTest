//
//  TestRunner.swift
//  diffTest
//
//  Created by Albert Q Park on 9/6/25.
//

import Foundation

struct Const {
    static let tempDirPath = "./temp"
    static let fullBuildDirPath = "./temp/result/full-build"
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

class TestRunner {
    let fullTestPath = Const.fullTestDirPath
    let xcResult = Const.xcResultFileName
    let slatherReport = Const.slatherReportFileNaem
    let tempResultPath = Const.tempResultDirPath
    
    var projectRoot: String
    var buildPath: String?
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
    
    enum XCBuildMode {
        case build
        case buildForTest
        case buildAndTest
        case testOnly
        
        func xcodeParam() -> String{
            switch self {
            case .build:
                return "build"
            case .buildAndTest:
                return "test"
            case .buildForTest:
                return "build-for-testing"
            case .testOnly:
                return "test-without-building"
            }
        }
    }
    
    func testResultURL(test: TestModel?) -> URL {
        let path = test?.identifierPath() ?? fullTestPath
        var filePath = URL(fileURLWithPath: "\(projectRoot)")
        filePath = filePath.appendingPathComponent(path)
        filePath = filePath.appendingPathComponent(xcResult)
        return filePath
    }
    
    
    func runTest(xcodeFile: String,
                 testOnly: TestModel? = nil,
                 skipTest: String = "",
                 mode: XCBuildMode = .buildAndTest) throws -> URL {
        var resultPath = testOnly?.identifierPath() ?? fullTestPath
        let derivePath: String
        switch mode {
        case .testOnly:
            derivePath = Const.fullBuildDirPath
        case .buildForTest:
            derivePath = Const.fullBuildDirPath
            resultPath = Const.fullBuildDirPath
            buildPath = derivePath
        default:
            derivePath = resultPath
            buildPath = derivePath
        }
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
-derivedDataPath \(derivePath)/build \
-resultBundlePath \(resultPath)/\(xcResult) \
-enableCodeCoverage YES \
 \(testingScope) \
 \(skipTest) \
 \(mode.xcodeParam())
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
