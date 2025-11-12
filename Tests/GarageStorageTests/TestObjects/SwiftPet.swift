//
//  SwiftPet.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 1/4/24.
//  Copyright © 2024 Wellframe. All rights reserved.
//

import GarageStorage // for Mappable

// In order to be a top-level type that is parked and retrieved in a garage, a type must conform to `Codable` and `Identifiable`. This happens to be a reference type (class). Here, we declare conformance to `Mappable`, a convenience protocol that combines `Codable` and `Identifiable`.
class SwiftPet: Mappable {

    // This declaration helps validate that non-String ID types such as `Int` conform to `LosslessStringConvertible` and pass a round-trip.
    var id: Int { age }
    
    // This example sets all properties to default values, so that an init() method is not required.
    var name: String = ""
    
    var age: Int = 0
}

extension SwiftPet: Equatable {
    static func == (lhs: SwiftPet, rhs: SwiftPet) -> Bool {
        return lhs.id == rhs.id
    }
}
