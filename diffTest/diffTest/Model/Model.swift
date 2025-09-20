//
//  Model.swift
//  diffTest
//
//  Created by Albert Q Park on 9/7/25.
//

import Foundation
import XCResultKit


struct HunkChange {
    var file: String?
    var startLine: Int
    var change: Int
}

struct Hunk {
    var isStarted = false
    var old: HunkChange
    var new: HunkChange
    var broakenLines = NSMutableSet()
    
    init(old: HunkChange, new: HunkChange) {
        self.old = old
        self.new = new
    }
    
    init(copy: Hunk) {
        old = copy.old
        new = copy.new
    }
    
    mutating func parse(hunkHeader: String) {
        let pattern = #"@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            if let match = regex.firstMatch(in: hunkHeader, options: [], range: NSRange(hunkHeader.startIndex..., in: hunkHeader)) {
                // 각 그룹 캡처
                let match1 = match.range(at: 1)
                if match1.location != NSNotFound {
                    let oldStartLine = Int((hunkHeader as NSString).substring(with: match1))
                    old.startLine = oldStartLine ?? 0
                }
                let match2 = match.range(at: 2)
                if match2.location != NSNotFound {
                    let oldLineLength = Int((hunkHeader as NSString).substring(with: match2))
                    old.change = oldLineLength ?? 1
                }else {
                    old.change = 1
                }
                let match3 = match.range(at: 3)
                if match3.location != NSNotFound {
                    let newStartLine = Int((hunkHeader as NSString).substring(with: match3))
                    new.startLine = newStartLine ?? 0
                }
                let match4 = match.range(at: 4)
                if match4.location != NSNotFound {
                    let newLineLength = Int((hunkHeader as NSString).substring(with: match4))
                    new.change = newLineLength ?? 1
                }else {
                    new.change = 1
                }
                isStarted = true
            }
        }
    }
    
    mutating func extractOldFilePath(from line: String) {
        let pattern = #"^---\s+(?:a/)?(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            old.file = nil
            return
        }
        let nsrange = NSRange(line.startIndex..<line.endIndex, in: line)

        if let match = regex.firstMatch(in: line, range: nsrange),
           let range = Range(match.range(at: 1), in: line) {
            let path = String(line[range])
            // 신규 파일이면 nil 반환
            old.file = path == "/dev/null" ? nil : path
        } else {
            old.file = nil
        }
    }
    
    mutating func extractNewFilePath(from line: String) {
        let pattern = #"^\+\+\+\s+(?:b/)?(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            new.file = nil
            return
        }
        let nsrange = NSRange(line.startIndex..<line.endIndex, in: line)

        if let match = regex.firstMatch(in: line, range: nsrange),
           let range = Range(match.range(at: 1), in: line) {
            let path = String(line[range])
            // 신규 파일이면 nil 반환
            new.file = path == "/dev/null" ? nil : path
        } else {
            new.file = nil
        }
    }
}


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

