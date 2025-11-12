//
//  SwiftyTree.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 10/8/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

// NOTE: No imports

// This class is used to test multiple Identifiable references.
struct SwiftBranch: Codable, Identifiable {
    
    var id: String = ""
    var branches: [SwiftBranch] = []
    
    init(name: String) {
        self.id = name
    }
}

// Make conformance to Equatable, for testing.
extension SwiftBranch: Equatable { }

class SwiftTree: Codable, Identifiable {
    
    var id: String = ""
    var mainBranch: SwiftBranch // non-optional, to test required properties.

    init(name: String, mainBranch: SwiftBranch) {
        self.id = name
        self.mainBranch = mainBranch
    }
}
