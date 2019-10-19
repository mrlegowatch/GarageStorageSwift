//
//  SwiftyTree.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 10/8/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

// This class is used to test multiple references.
struct SwiftBranch: Mappable {
    
    var id: String = ""
    var branches: [SwiftBranch] = []
    
    init(name: String) {
        self.id = name
    }
}

// Make conformance to Equatable, for testing.
extension SwiftBranch: Equatable { }

class SwiftTree: Mappable {
    
    var id: String = ""
    var mainBranch: SwiftBranch // non-optional, to test required properties.

    init(name: String, mainBranch: SwiftBranch) {
        self.id = name
        self.mainBranch = mainBranch
    }
}
