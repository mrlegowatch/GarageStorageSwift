//
//  SwiftPet.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 1/4/24.
//  Copyright © 2024 Wellframe. All rights reserved.
//

import GarageStorage // for Mappable, Syncable

// In order to be a top-level type that is parked and retrieved in a garage, a type must conform to Mappable (a Codable with an identifier). This happens to be a reference type (class).
// It may optionally implement Syncable.
class SwiftPet: Mappable, Syncable {

    // This declaration helps validate that non-String ID types such as `Int` conform to `LosslessStringConvertible` and pass a round-trip.
    var id: Int { age }
    
    // This example sets all properties to default values, so that an init() method is not required.
    var name: String = ""
    
    var age: Int = 0
        
    // Types with sync status need to skip syncStatus for coding, because it's archived
    // separately in the underlying core data object, in order to fetch based on sync status.
    private enum CodingKeys: String, CodingKey {
        case name
        case age
    }
    
    // Syncable protocol
    var syncStatus: SyncStatus = .notSynced
}

extension SwiftPet: Equatable {
    static func == (lhs: SwiftPet, rhs: SwiftPet) -> Bool {
        return lhs.id == rhs.id
    }
}
