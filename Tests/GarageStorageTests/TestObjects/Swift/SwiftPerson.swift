//
//  SwiftyPerson.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/30/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

// In order to be a top-level type that is parked and retrieved in a garage, a type must conform to Codable and Identifiable. This happens to be a reference type (class).
class SwiftPerson: Codable, Identifiable {

    // Map the identifier to a preferred property, if desired.
    var id: String { name }
    
    // This example sets all properties to default values, so that an init() method is not required.
    var name: String = ""
    
    var address: SwiftAddress?
    var age: Int = 0
    var birthdate: Date = Date()
    var importantDates: [Date] = []
    var siblings: [SwiftPerson] = []
    var brother: SwiftPerson?
}
