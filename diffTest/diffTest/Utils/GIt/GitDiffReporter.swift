//
//  GitDiffReporter.swift
//  diffTest
//
//  Created by Albert Q Park on 9/20/25.
//

import Foundation

class GitBrokenLineReporter {
    var ofs: OutputStream
    
    init(rootDir: URL) throws {
        let brokenFilePath = rootDir
            .appending(path: Const.tempDirPath)
            .appending(path: Const.broakenFileName)
            .standardizedFileURL
        guard let outputStream = OutputStream(url: brokenFilePath, append: false) else {
            throw DiffTestError.unkown
        }
        outputStream.open()
        ofs = outputStream
    }
    
    func writeLine(lineNumber: Int, filePath: String) throws {
        let line = String(format: "%ld\t%@\n", lineNumber, filePath)
        guard let data = line.data(using: .utf8) as? NSData else {
            throw DiffTestError.unkown
        }
        print("ofs :\(ofs.streamStatus)\n\(line)")
        ofs.write(data.bytes, maxLength: data.count)
    }
    
    func close() {
        ofs.close()
    }
    
    deinit {
        close()
    }
}
