//
//  Model.swift
//  diffTest
//
//  Created by Albert Q Park on 9/7/25.
//

import Foundation
import XCResultKit


struct TestModel {
    let result: XCResultKit.ActionTestMetadata
    var identifier: String
    
    func identifierPath() -> String {
        return "./temp/result/" + identifier.replacingOccurrences(of: "()", with: "")
    }
}

struct SlatherFileCoverage: Codable {
    let file: String
    let coverage: [Int?]
    var coverageMap: [Int: CoverageMap?]?
    
    mutating func addCoverage(testIdentifier: String, line: Int, coverage: Int) {
        var coverageMap = coverageMap ?? [Int: CoverageMap?]()
        var coverageOfLine = coverageMap[line] ?? CoverageMap(coverage: line, perTestCoverages: [])
        let ptc = PerTestCoverage(coverage: coverage, testIdentifier: testIdentifier)
        coverageOfLine?.perTestCoverages.append(ptc)
        coverageMap[line] = coverageOfLine
        self.coverageMap = coverageMap
    }
}

struct CoverageMap: Codable {
    var coverage: Int
    var perTestCoverages: [PerTestCoverage]
}

struct PerTestCoverage: Codable {
    var coverage: Int
    var testIdentifier: String
}

