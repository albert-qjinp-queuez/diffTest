//
//  Reporter.swift
//  diffTest
//
//  Created by Albert Q Park on 9/12/25.
//


import Foundation
import Combine

class PerTestCoverageReporter: NSObject {
    var perTestsCoverageMap = [String: SlatherFileCoverage]()

    func readFullCoverage(_ url: URL) throws {
        let data = try Data(contentsOf: url)
        let fileCoverages = try JSONDecoder().decode( [SlatherFileCoverage].self, from: data)
        for fileCoverage in fileCoverages {
            var mutatingFileCoverage = fileCoverage
            for (index, coverage) in mutatingFileCoverage.coverage.enumerated() {
                if let coverage = coverage {
                    mutatingFileCoverage.prepareCoverageMap(line: index, fullCoverage: coverage)
                }
            }
            perTestsCoverageMap[mutatingFileCoverage.file] = mutatingFileCoverage
        }
    }

    func mergeIndividualCoverage(_ url: URL, test: TestModel) throws {
        let data = try Data(contentsOf: url)
        let perTestCoverages = try JSONDecoder()
            .decode( [SlatherFileCoverage].self,
                     from: data)

        for fileCoverage in perTestCoverages {
            for (index, lineCoverage) in fileCoverage.coverage.enumerated() {
                if let lineCoverage = lineCoverage {
                    try perTestsCoverageMap[fileCoverage.file]?
                        .addCoverage(testIdentifier: test.identifier,
                                     line: index,
                                     coverage: lineCoverage)
                }
            }
        }
    }

    func save(_ url: URL) throws {
        let url = url.appending(path: Const.markerCoverageMapFileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        
        let data = try encoder
            .encode(perTestsCoverageMap)
        try data.write(to: url)
    }
    
    func load(_ coverageFileURL: URL) throws {
        let jsonDecoder = JSONDecoder()
        let data = try Data(contentsOf: coverageFileURL)
        perTestsCoverageMap = try jsonDecoder.decode([String: SlatherFileCoverage].self, from: data)
    }
}

class TestListReporter: NSObject {
    static let testList = Const.markerTestListFileName
    let fm = FileManager.default
    var markerRootDir: URL
    
    init(markerRootURL: URL) {
        self.markerRootDir = markerRootURL
        super.init()
        fm.delegate = self
    }
    
    func prepare() {
        var isDir = ObjCBool(true)
        if fm.fileExists(atPath: markerRootDir.standardizedFileURL.absoluteString,
                         isDirectory: &isDir) {
            try? fm.removeItem(at: markerRootDir)
        }
        try? fm.createDirectory(at: markerRootDir, withIntermediateDirectories: true)
    }
    
    func testList(tests: [TestModel]) {
        let testFile = markerRootDir.appending(path: Self.testList)
        guard let fs = OutputStream(url: testFile, append: false) else {
            return
        }
        fs.open()
        for test in tests {
            let testName = test.identifier + "\n"
            if let data = testName.data(using: .utf8) as? NSData {
                fs.write(data.bytes, maxLength: data.count)
            }
        }
        fs.close()
        
    }
}

extension TestListReporter: FileManagerDelegate {
    func fileManager(_ f: FileManager, shouldRemoveItemAt: URL) -> Bool {
        return true
    }
    func fileManager(_ f: FileManager, shouldRemoveItemAtPath: String) -> Bool {
        return true
    }
    func fileManager(_ f: FileManager, shouldProceedAfterError: any Error, removingItemAt: URL) -> Bool {
        return true
    }
    
    func fileManager(_ f: FileManager, shouldProceedAfterError: any Error, removingItemAtPath: String) -> Bool {
        return true
    }
}

class TestListIterator: IteratorProtocol {
    typealias Element = String
    
    var lineReader: LineReader
    init(lineReader: LineReader) {
        self.lineReader = lineReader
    }
    
    func next() -> String? {
        return lineReader.next()
    }
}

class TestListReader: Sequence {
    var url: URL
    init(url: URL) {
        self.url = url
    }
    
    func makeIterator() -> some IteratorProtocol {
        guard let reader = try? LineReader(url: url) else {
            DiffTest.exit(withError: DiffTestError.unkown)
        }
        return TestListIterator(lineReader: reader)
    }
}
