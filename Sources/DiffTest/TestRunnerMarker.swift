//
//  TestRunnerMarker.swift
//  diffTest
//
//  Created by Albert Q Park on 9/13/25.
//

import Foundation
import XCResultKit

extension TestRunner {
    
    func runFullBuild(xcodeFile: String) throws -> URL {
        return try self.runTest(xcodeFile: xcodeFile,
                                testOnly: nil,
                                mode: .buildForTest)
    }
    
    func runFullTest(xcodeFile: String, mode: XCBuildMode = .buildAndTest) throws -> URL {
        return try self.runTest(xcodeFile: xcodeFile, testOnly: nil, mode: mode)
    }
    
    func runTestCoverage(xcodeFile: String, test: TestModel, mode: XCBuildMode = .buildAndTest) throws -> URL {
        return try self.runTest(xcodeFile: xcodeFile, testOnly: test, mode: mode)
    }
    
    func collectTestCoverage(xcodeFile: String, test: TestModel?) throws -> URL {
        let path = test?.identifierPath() ?? fullTestPath
        let buildPath = buildPath ?? path
        let bashCommand = """
cd \(projectRoot)
slather coverage \
  --workspace \(xcodeFile) \
  --scheme \(schema) \
  --build-directory \(buildPath)/build \
  --output-directory \(path) \
  --json \
\(xcodeFile)
"""
        let _ = try ScriptUtil.bashScript(command: bashCommand)
        let resultURL =  URL(fileURLWithPath: projectRoot)
            .appending(path:  path)
            .appending(path: slatherReport)
        return resultURL.standardizedFileURL
    }
    
    func extractTests(resultUrl: URL) -> [TestModel] {
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
        var testGroups = Set<TestModel>()
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
                        testGroups.insert(model)
                    }
                }
            }
        }
        return [TestModel](testGroups)
    }

    /// @return
    /// - true when test marker is ready to mark
    /// - false when test marker is already exists
    func checkTag() -> Bool {
        let bashCommand = """
cd \(gitRoot)
git fetch
COMMIT_HASH=$(git rev-parse HEAD)
git rev-parse -q --verify "test_marker/$COMMIT_HASH"
"""
        do {
            _ = try ScriptUtil.bashScript(command: bashCommand)
        } catch {
            return false
        }
        return true
    }
    
    func commit(message: String) throws {
        let bashCommand = """
cd \(gitRoot)
git fetch
COMMIT_HASH=$(git rev-parse HEAD)
echo $COMMIT_HASH > \(Const.markerDirPath)/marked_hash.txt
git add \(Const.markerDirPath)/
git commit --message "DiffTest Marker Against $COMMIT_HASH | \(message) \n "
git tag "test_marker/$COMMIT_HASH" -m "per test coverage marked"
"""
        _ = try ScriptUtil.bashScript(command: bashCommand)
    }
}
