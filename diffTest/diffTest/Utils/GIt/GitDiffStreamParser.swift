//
//  GitDiffStreamParser.swift
//  diffTest
//
//  Created by Albert Q Park on 9/19/25.
//

import Foundation

class GitDiffStreamParser {
    var lineReader: LineReader
    init(gitDiffURL: URL) throws {
        guard let lr = try LineReader(url: gitDiffURL) else {
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
    
    func parse(eachHunk:(Hunk) throws -> ()) throws {
        var currentHunk: Hunk?
        var oldLineCount = 0
        var previousStage = HunkStage.unknown
        while let line = lineReader.next() {
            if line.hasPrefix("diff") {
                if let currentHunk = currentHunk {
                    try eachHunk(currentHunk)
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
                currentHunk?.extractOldFilePath(from: line)
                previousStage = .oldFile
            } else if line.hasPrefix("+++") {
                currentHunk?.extractNewFilePath(from: line)
                previousStage = .newFile
            } else if line.hasPrefix("@@") {
                if let hunkToSend = currentHunk,
                   hunkToSend.isStarted {
                    try eachHunk(hunkToSend)
                    currentHunk = Hunk(copy: hunkToSend)
                }
                currentHunk?.parse(hunkHeader: line)
                previousStage = .HunkNumbers
            } else if line.hasPrefix("-") {
                var line = currentHunk?.old.startLine ?? 0
                line += oldLineCount
                currentHunk?.brokenLines.add(line)
                oldLineCount += 1
                previousStage = .deleted
            } else if line.hasPrefix("+") {
                if previousStage != .deleted,
                   previousStage != .added {
                    var line = currentHunk?.old.startLine ?? 0
                    line += oldLineCount
                    currentHunk?.brokenLines.add(line)
                    currentHunk?.brokenLines.add(line+1)
                }
                previousStage = .added
            } else {
                oldLineCount += 1
                previousStage = .noChange
            }
        }
        if let hunkToSend = currentHunk,
           hunkToSend.isStarted {
            try eachHunk(hunkToSend)
        }
    }
    
}
