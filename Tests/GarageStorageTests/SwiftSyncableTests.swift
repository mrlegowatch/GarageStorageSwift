//
//  SwiftSyncableTests.swift
//  GarageStorage
//
//  Created by Brian Arnold on 11/15/25.
//

import Testing
import GarageStorage

struct SwiftSyncableTests {
    
    init() {
        TestSetup.classSetUp()
    }
    
    @Test("Managing sync status of objects")
    func syncStatus() throws {
        let garage = makeTestGarage()
        
        let sam = swiftPerson()
        let nick = swiftPerson2()
        let emily = swiftPerson3()
        
        let oldAddress = swiftAddress()
        let newAddress = swiftAddress2()
        
        let pet = swiftPet()
        
        // Park heterogeneous objects
        try garage.parkAll([nick, emily, sam])
        try garage.parkAll([oldAddress, newAddress])
        try garage.parkAll([pet])
        
        // Validate sync status of Persons
        // WARNING: This will succeed by accident, because there is only one object of type SwiftPerson syncing,
        // but if there was another object of a different type syncing, then this would fail.
        // Use retrieveAll(_ objectClass: T, withStatus: SyncStatus) instead to focus on the specific type.
        let syncing: [SwiftPerson] = try garage.retrieveAll(withStatus: .syncing)
        
        #expect(syncing.count == 1, "1 item should be syncing")
        
        // TODO: heterogeneous Codable subtype arrays
        //let undetermined: [?] = try garage.retrieveAll(withStatus: .undetermined)
        //#expect(undetermined.count == 4, "4 items should be undetermined")
        
        // This will throw because there are different types of objects not synced.
        // Don't use retrieveAll without an objectClass if you work with heterogeneous objects that may have the same sync status.
        // let notSynced: [SwiftPerson] = try garage.retrieveAll(withStatus: .notSynced))
        
        // This is the correct way to fetch all of a specific type that are not synced
        let notSynced: [SwiftPerson] = try garage.retrieveAll(SwiftPerson.self, withStatus: .notSynced)
        #expect(notSynced.count == 0, "no items should be not synced")
        
        // Change Sam's sync status and validate that it changed
        try garage.setSyncStatus(.notSynced, for: sam)
        
        // Add in an unrelated object type, to ensure that retrieveAll below works on just one type
        try garage.setSyncStatus(.notSynced, for: pet)
        
        let syncingAfterChange: [SwiftPerson] = try garage.retrieveAll(SwiftPerson.self, withStatus: .syncing)
        #expect(syncingAfterChange.count == 0, "no items should be syncing")
        
        let notSyncedAfterChange: [SwiftPerson] = try garage.retrieveAll(SwiftPerson.self, withStatus: .notSynced)
        #expect(notSyncedAfterChange.count == 1, "1 item should be not synced")
        
        // Test setting sync status for a collection
        try garage.setSyncStatus(.undetermined, for: [nick, sam])
        let nickStatus = try garage.syncStatus(for: nick)
        #expect(nickStatus == .undetermined, "Nick should have undetermined sync status")
    }
    
    @Test("Setting sync status for unparked object throws error")
    func invalidSyncStatus() throws {
        let garage = makeTestGarage()
        
        // Create, but don't park, sam
        let sam = swiftPerson()
        
        // Verify that setting sync status on an unparked object throws an error
        #expect(throws: Error.self) {
            try garage.setSyncStatus(.notSynced, for: sam)
        }
        
        #expect(throws: Error.self) {
            try garage.setSyncStatus(.notSynced, for: [sam])
        }
    }
}
