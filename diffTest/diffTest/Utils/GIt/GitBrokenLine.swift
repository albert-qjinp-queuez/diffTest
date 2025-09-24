//
//  GitBrokenLine.swift
//  diffTest
//
//  Created by Albert Q Park on 9/20/25.
//

import Foundation

class GitBrokenLineReporter {
    var ofs: OutputStream
    
    init(brokenFileURL: URL) throws {
        guard let outputStream = OutputStream(url: brokenFileURL, append: false) else {
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

class GitBrokenLineIterator: IteratorProtocol {
    typealias Element = Broken
    
    var lineReader: LineReader
    init(lineReader: LineReader) {
        self.lineReader = lineReader
    }
    
    func next() -> Broken? {
        let line = lineReader.next()
        guard let components = line?.components(separatedBy: "\t"),
              components.count >= 2,
              let brokenLine = Int(components[0]) else {
            return nil
        }
        let broken = Broken(filePath: components[1],
                            line: brokenLine)
        return broken
    }
    
    deinit {
        try? lineReader.close()
    }
}

class GitBrokenLineReader: Sequence {
    var url: URL
    init(url: URL) {
        self.url = url
    }
    
    func makeIterator() -> some IteratorProtocol {
        guard let reader = try? LineReader(url: url) else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        return GitBrokenLineIterator(lineReader: reader)
    }
}
