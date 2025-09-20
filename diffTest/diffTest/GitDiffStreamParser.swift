//
//  GitDiffStreamParser.swift
//  diffTest
//
//  Created by Albert Q Park on 9/19/25.
//

import Foundation

struct HunkChange {
    var file: String
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
}

class GitDiffStreamParser {
    var lineReader: LineReader
    init(url: URL) throws {
        guard let lr = try LineReader(url: url) else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        lineReader = lr
    }

    enum HunkStage {
        case unknown
        case diff
        case new
        case index
        case oldFile
        case newFile
        case HunkNumbers
        case deleted
        case added
        case noChange
    }
    
    func parse(eachHunk:(Hunk)->()) {
        var currentHunk: Hunk?
        var oldLineCount = 0
        var previousStage = HunkStage.unknown
        while let line = lineReader.next() {
            if line.hasPrefix("diff") {
                if let currentHunk = currentHunk {
                    eachHunk(currentHunk)
                }
                currentHunk = Hunk(old: HunkChange(file: "", startLine: 0, change: 0),
                                   new: HunkChange(file: "", startLine: 0, change: 0))
                oldLineCount = 0
                previousStage = .diff
            } else if line.hasPrefix("new") {
                // not my interest
                previousStage = .new
            } else if line.hasPrefix("index") {
                // not my interest
                previousStage = .index
            } else if line.hasPrefix("---") {
                currentHunk?.old.file = line
                previousStage = .oldFile
            } else if line.hasPrefix("+++") {
                currentHunk?.new.file = line
                previousStage = .newFile
            } else if line.hasPrefix("@@") {
                if let hunkToSend = currentHunk,
                   hunkToSend.isStarted {
                    eachHunk(hunkToSend)
                    currentHunk = Hunk(copy: hunkToSend)
                }
                let pattern = #"@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@"#
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    if let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                        // 각 그룹 캡처
                        let match1 = match.range(at: 1)
                        if match1.location != NSNotFound {
                            let oldStartLine = Int((line as NSString).substring(with: match1))
                            currentHunk?.old.startLine = oldStartLine ?? 0
                        }
                        let match2 = match.range(at: 2)
                        if match2.location != NSNotFound {
                            let oldLineLength = Int((line as NSString).substring(with: match2))
                            currentHunk?.old.change = oldLineLength ?? 1
                        }else {
                            currentHunk?.old.change = 1
                        }
                        let match3 = match.range(at: 3)
                        if match3.location != NSNotFound {
                            let newStartLine = Int((line as NSString).substring(with: match3))
                            currentHunk?.new.startLine = newStartLine ?? 0
                        }
                        let match4 = match.range(at: 4)
                        if match4.location != NSNotFound {
                            let newLineLength = Int((line as NSString).substring(with: match4))
                            currentHunk?.new.change = newLineLength ?? 1
                        }else {
                            currentHunk?.new.change = 1
                        }
                        currentHunk?.isStarted = true
                    }
                }
                previousStage = .HunkNumbers
            } else if line.hasPrefix("-") {
                var line = currentHunk?.old.startLine ?? 0
                line += oldLineCount
                currentHunk?.broakenLines.add(line)
                oldLineCount += 1
                previousStage = .deleted
            } else if line.hasPrefix("+") {
                if previousStage != .deleted,
                   previousStage != .added {
                    var line = currentHunk?.old.startLine ?? 0
                    line += oldLineCount
                    currentHunk?.broakenLines.add(line)
                    currentHunk?.broakenLines.add(line+1)
                }
                previousStage = .added
            } else {
                oldLineCount += 1
                previousStage = .noChange
            }
        }
        if let hunkToSend = currentHunk,
           hunkToSend.isStarted {
            eachHunk(hunkToSend)
        }
    }
    
}



