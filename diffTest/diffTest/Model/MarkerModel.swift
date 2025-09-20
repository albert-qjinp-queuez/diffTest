//
//  Model.swift
//  diffTest
//
//  Created by Albert Q Park on 9/7/25.
//

import Foundation
import XCResultKit

struct TestModel: Hashable {
    let result: XCResultKit.ActionTestMetadata
    var identifier: String
    
    func identifierPath() -> String {
        return Const.tempPath + "/" + identifier.replacingOccurrences(of: "()", with: "")
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier.hashValue)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

struct SlatherFileCoverage: Codable {
    let file: String
    let coverage: [Int?]
    var coverageMap: [Int: CoverageMap?]?
    
    mutating func prepareCoverageMap(line: Int, fullCoverage: Int) {
        var coverageMap = coverageMap ?? [Int: CoverageMap?]()
        coverageMap[line] = CoverageMap(line: line, coverage: fullCoverage, perTestCoverages: [])
        self.coverageMap = coverageMap
    }
    
    mutating func addCoverage(testIdentifier: String, line: Int, coverage: Int) throws {
        guard coverage > 0 else {
            return
        }
        var coverageMap = coverageMap ?? [Int: CoverageMap?]()
        var coverageOfLine: CoverageMap
        if testIdentifier.hasSuffix("testLaunch") {
            print("why is this looping 4 times? \(testIdentifier) \(line)")
        }
        guard let coverageMapLine = coverageMap[line],
           let coverageMapLine = coverageMapLine else {
            throw DiffTestError.unkown
        }
        coverageOfLine = coverageMapLine
        let ptc = PerTestCoverage(coverage: coverage, testIdentifier: testIdentifier)
        coverageOfLine.perTestCoverages.append(ptc)
        coverageMap[line] = coverageOfLine
        self.coverageMap = coverageMap
    }
}

struct CoverageMap: Codable {
    var line: Int
    var coverage: Int
    var perTestCoverages: [PerTestCoverage]
}

struct PerTestCoverage: Codable {
    var coverage: Int
    var testIdentifier: String
}

