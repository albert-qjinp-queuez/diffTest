//
//  ViewModel.swift
//  diffTest
//
//  Created by Albert Q Park on 9/7/25.
//

import Foundation
import XCResultKit


struct TestModel {
    let result: XCResultKit.ActionTestMetadata
    var identifier: String
    
    func identifierPath() -> String {
        return "./temp/result/" + identifier.replacingOccurrences(of: "()", with: "")
    }
}
