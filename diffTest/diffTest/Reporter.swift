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
            perTestsCoverageMap[fileCoverage.file] = fileCoverage
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
                    perTestsCoverageMap[fileCoverage.file]?
                        .addCoverage(testIdentifier: test.identifier,
                                     line: index,
                                     coverage: lineCoverage)
                }
            }
        }
    }

    func save(_ url: URL) throws {
        let url = url.appending(path: "perTestCoverageMap.json")
        var encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder
            .encode(perTestsCoverageMap)
        try data.write(to: url)
    }
}

class TestListReporter: NSObject {
    static let testList = "test_list.txt"
    var fm = FileManager.default
    
    var rootDir: URL
    init(rootDir: URL) {
        self.rootDir = rootDir
        super.init()
        fm.delegate = self
    }
    
    func prepare() {
        var isDir = ObjCBool(true)
        if fm.fileExists(atPath: rootDir.standardizedFileURL.absoluteString,
                         isDirectory: &isDir) {
            try? fm.removeItem(at: rootDir)
        }
        try? fm.createDirectory(at: rootDir, withIntermediateDirectories: true)
    }
    
    func testList(tests: [TestModel]) {
        let testFile = rootDir.appending(path: Self.testList)
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
