//
//  TestRunner.swift
//  diffTest
//
//  Created by Albert Q Park on 9/6/25.
//

import Foundation
import XCResultKit

struct Util {
    static func bashScript(command: String) throws -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-l", "-c", command]
        print("bash command: \n\n")
        print(command)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        var totalScript = ""
        // 백그라운드에서 읽기
        pipe.fileHandleForReading.readabilityHandler = { handle in
            if let line = String(data: handle.availableData, encoding: .utf8),
               !line.isEmpty {
                print("SCRIPT:", line)
                totalScript += line
            }
        }

        process.waitUntilExit()

        pipe.fileHandleForReading.readabilityHandler = nil
        return totalScript
    }
}

struct TestRunner {
// feel like this is tricking the test result and code coverages disable for now
//    static func runBuildForTest(xcodeFile: String, root: String) throws {
//        let bashCommand = """
//cd \(root)
//xcodebuild \
//-project \(xcodeFile) \
//-scheme DiffTestSample \
//-destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" \
//-configuration Debug \
//-derivedDataPath ./temp/build \
//-enableCodeCoverage YES \
// build-for-testing
//"""
//        let _ = try Util.bashScript(command: bashCommand)
//    }

    static func runFullTest(xcodeFile: String, root: String) throws -> URL {
        let bashCommand = """
cd \(root)
xcodebuild \
-project \(xcodeFile) \
-scheme DiffTestSample \
-destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" \
-configuration Debug \
-derivedDataPath ./temp/result/total-test/build \
-resultBundlePath ./temp/result/total-test/results.xcresult \
-enableCodeCoverage YES \
 test
"""
        let _ = try Util.bashScript(command: bashCommand)
        return URL(fileURLWithPath: "\(root)/temp/result/total-test-results.xcresult")
    }
    
    static func runTestCoverage(xcodeFile: String, root: String, test: TestModel) throws -> URL {
        let path = test.identifierPath()
        let bashCommand = """
cd \(root)
xcodebuild \
-project \(xcodeFile) \
-scheme DiffTestSample \
-destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" \
-configuration Debug \
-derivedDataPath \(path)/build \
-resultBundlePath \(path)/results.xcresult \
-enableCodeCoverage YES \
-only-testing:"\(test.identifier)" \
 test
"""
        let _ = try Util.bashScript(command: bashCommand)
        return URL(fileURLWithPath: "\(root)/temp/result/\(path)")
    }
    
    static func collectTestCoverage(xcodeFile: String, root: String, test: TestModel) throws {
        let path = test.identifierPath()
        let bashCommand = """
cd \(root)
slather coverage \
  --workspace \(xcodeFile) \
  --scheme DiffTestSample \
  --build-directory \(path)/build \
  --output-directory \(path) \
  --json \
  ./DiffTestSample.xcodeproj
"""
        let _ = try Util.bashScript(command: bashCommand)
    }
    
    static func coverageReportPath(path: String) -> String {
        return "./temp/result/" + path.replacingOccurrences(of: "()", with: "")
    }

    static func clean(root: String) throws {
        let bashCommand = """
cd \(root)
rm -rf ./temp/result
"""
        let _ = try Util.bashScript(command: bashCommand)
    }

    static func extractTests(resultUrl: URL) -> [TestModel] {
        let resultFile = XCResultFile(url: resultUrl)
        let invocationRecord = resultFile.getInvocationRecord()
        guard let testsRef = invocationRecord?.actions.first?.actionResult.testsRef
        else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }

        let testID = testsRef.id
        guard let testPlanRunSummaries = resultFile.getTestPlanRunSummaries(id: testID) else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        print("\n\n\(testPlanRunSummaries)")
        var testGroups = [TestModel]()

        for testSum in testPlanRunSummaries.summaries {
            for testable in testSum.testableSummaries {
                for testClass in testable.tests {
                    for testFunction in testClass.subtests {
                        let schemeName = invocationRecord?.actions.first?.testPlanName ?? ""
                        let idURL = testFunction.identifierURL ?? ""
                        let schemeRange = idURL.firstRange(of: schemeName)
                        let startIndex = schemeRange?.upperBound ?? idURL.startIndex

                        let testID = String(idURL[idURL.index(after: startIndex)..<idURL.endIndex])
                        let model = TestModel(result: testFunction,
                            identifier: testID)
                        testGroups.append(model)
                    }
                }
            }
        }

        return testGroups
    }
}

class ResultReporter: NSObject {
    static let testList = "test_list.txt"
    var fm = FileManager.default
    
    var rootDir: URL
    init(rootDir: URL) {
        self.rootDir = rootDir
        super.init()
        fm.delegate = self
    }
    
    func prepare() {
        var isDir = ObjCBool(true)
        if fm.fileExists(atPath: rootDir.standardizedFileURL.absoluteString,
                         isDirectory: &isDir) {
            try? fm.removeItem(at: rootDir)
        }
        try? fm.createDirectory(at: rootDir, withIntermediateDirectories: true)
    }
    
    func testList(tests: [TestModel]) {
        let testFile = rootDir.appending(path: Self.testList)
        guard let fs = OutputStream(url: testFile, append: false) else {
            return
        }
        fs.open()
        for test in tests {
            let testName = test.identifier + "\n"
            if let data = testName.data(using: .utf8) as? NSData {
                fs.write(data.bytes, maxLength: data.count)
            }
        }
        fs.close()
        
    }
}

extension ResultReporter: FileManagerDelegate {
    func fileManager(_ f: FileManager, shouldRemoveItemAt: URL) -> Bool {
        return true
    }
    func fileManager(_ f: FileManager, shouldRemoveItemAtPath: String) -> Bool {
        return true
    }
    func fileManager(_ f: FileManager, shouldProceedAfterError: any Error, removingItemAt: URL) -> Bool {
        return true
    }
    
    func fileManager(_ f: FileManager, shouldProceedAfterError: any Error, removingItemAtPath: String) -> Bool {
        return true
    }
    

}
