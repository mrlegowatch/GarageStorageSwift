//
//  SwiftyPerson.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/30/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

// In order to be a top-level type that is parked and retrieved in a garage, a type must conform to Mappable (a Codable with an identifier). This happens to be a reference type (class).
// It may optionally implement Syncable.
class SwiftPerson: Mappable, Syncable {

    // Map the identifier to a preferred property, if desired.
    var id: String { name }
    
    // This example sets all properties to default values, so that an init() method is not required.
    var name: String = ""
    
    // For testing migration from "ObjCAddress" to "SwiftyAddress", we wrap the address property with @Migratable.
    @Migratable var address: SwiftAddress?
    var age: Int = 0
    var birthdate: Date = Date()
    var importantDates: [Date] = []
    var siblings: [SwiftPerson] = []
    var brother: SwiftPerson?
        
    // Types with sync status need to skip syncStatus for coding, because it's archived
    // separately in the underlying core data object, in order to fetch based on sync status.
    private enum CodingKeys: String, CodingKey {
        case name
        case address
        case age
        case birthdate
        case importantDates
        case siblings
        case brother
    }
    
    // Syncable protocol
    var syncStatus: SyncStatus = .undetermined
}

// Note that SwiftyPerson can conform to Swift Identifiable, because Mappable is compatible with Identifiable where ID == String.
// This is here for shizzles, it's not actually needed or used by anything in the tests.
extension SwiftPerson: Identifiable { }
