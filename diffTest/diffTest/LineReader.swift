//
//  LineReader.swift
//  diffTest
//
//  Created by Albert Q Park on 9/19/25.
//

import Foundation

class LineReader: Sequence, IteratorProtocol {
    let fileHandle: FileHandle
    let encoding: String.Encoding
    let chunkSize: Int
    var buffer: Data
    var atEOF: Bool

    init?(url: URL, chunkSize: Int = 4096, encoding: String.Encoding = .utf8) throws {
        let handle = try FileHandle(forReadingFrom: url)
        self.fileHandle = handle
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.buffer = Data()
        self.atEOF = false
    }

    func next() -> String? {
        precondition(!atEOF, "EOF reached")

        while true {
            if let range = buffer.range(of: Data([0x0a])) { // LF (줄바꿈)
                let lineData = buffer.subdata(in: 0..<range.lowerBound)
                buffer.removeSubrange(0...range.lowerBound)
                return String(data: lineData, encoding: encoding)
            }

            let chunk = fileHandle.readData(ofLength: chunkSize)
            if chunk.count > 0 {
                buffer.append(chunk)
            } else {
                atEOF = true
                return buffer.count > 0
                    ? String(data: buffer, encoding: encoding)
                    : nil
            }
        }
    }

    deinit {
        try? fileHandle.close()
    }
}
