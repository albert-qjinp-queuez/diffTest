//
//  main.swift
//  diffTest
//
//  Created by Albert Q Park on 9/6/25.
//

import Foundation
import ArgumentParser

enum DiffTestError: Error {
    case unkown
}

struct DiffTest: ParsableCommand {
    static var configuration = CommandConfiguration(
        subcommands: [Mark.self, Test.self]
    )
}

DiffTest.main()
