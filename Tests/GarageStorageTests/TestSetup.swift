//
//  TestSetup.swift
//  GarageStorageTests
//
//  Created by Bob Gilmore on 5/10/21.
//

import Foundation
import GarageStorage
import CoreData

public class TestSetup {
    
    static let timeZone = TimeZone(identifier: "UTC")!
    
    static func classSetUp() {
        // Set the test time zone to UTC so that tests can compare with hardcoded UTC dates
        NSTimeZone.default = TestSetup.timeZone
    }
    
}

/// Use this test store name for Garage Storage tests.
let testStoreName = "GarageStorageTests"

/// Returns a test garage for a named specific test point that is in-memory only.
func makeTestGarage(_ name: String = #function) -> Garage {
    let persistentStore = Garage.makePersistentStoreDescription("\(name).sqlite")
    persistentStore.type = NSInMemoryStoreType
    let garage = Garage(with: [persistentStore])
    garage.loadPersistentStores { _, _ in }
    return garage
}
