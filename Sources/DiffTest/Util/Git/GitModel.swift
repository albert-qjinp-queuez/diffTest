//
//  GitModel.swift
//  diffTest
//
//  Created by Albert Q Park on 9/20/25.
//

import Foundation

struct Broken {
    var filePath: String
    var line: Int
}

struct HunkChange {
    var file: String?
    var startLine: Int
    var change: Int
}

struct Hunk {
    var isStarted = false
    var old: HunkChange
    var new: HunkChange
    var brokenLines = NSMutableSet()
    
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
