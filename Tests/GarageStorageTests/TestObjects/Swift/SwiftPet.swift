//
//  SwiftPet.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 1/4/24.
//  Copyright © 2024 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

// In order to be a top-level type that is parked and retrieved in a garage, a type must conform to Mappable (a Codable with an identifier). This happens to be a reference type (class).
class SwiftPet: Mappable {

    // Map the identifier to a preferred property, if desired.
    var id: String { name }
    
    // This example sets all properties to default values, so that an init() method is not required.
    var name: String = ""
    
    var age: Int = 0
}
