// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import ArgumentParser

enum DiffTestError: Error {
    case unkown
}

@main
@MainActor
struct DiffTest: @preconcurrency ParsableCommand {
    @MainActor static var configuration = CommandConfiguration(
        subcommands: [Mark.self, Test.self]
    )
}
