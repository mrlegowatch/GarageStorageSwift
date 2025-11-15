//
//  MappableObjectTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/12/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Testing

import Foundation
import GarageStorage
import CoreData

// This set of tests use Swift-declared Objective-C-compatible MappableObjects.
@Suite("MappableObject Tests")
struct MappableObjectTests {
    
    init() {
        TestSetup.classSetUp()
    }
    
    @Test("Test mappable object parking and retrieval")
    func testMappableObject() async throws {
        let garage = makeTestGarage()
        
        // Create a "Sam" person and park it.
        do {
            let sam = objCPerson()
            try garage.parkObject(sam)
        }
        
        // Retrieve the "Sam" person.
        do {
            let sam = try garage.retrieveObject(ObjCPerson.self, identifier: "Sam")
            #expect(sam != nil, "Failed to retrieve 'Sam' from garage store")
            #expect(sam?.name == "Sam", "expected Sam to be Sam")
            #expect(sam?.importantDates.count == 3, "expected 3 important dates")
            
            // Make sure brother and siblings worked out.
            let brother = sam?.brother
            #expect(brother != nil, "O brother, my brother")
            #expect(brother?.name == "Nick", "expected brother to be Nick")
            #expect(sam?.siblings.count == 2, "expected 2 siblings")
        }
    }
    
    @Test("Test parking and retrieving array of mappable objects")
    func testArrayOfMappable() async throws {
        let garage = makeTestGarage()
        
        // Create a pair of people and park them.
        do {
            let nick = objCPerson2()
            let emily = objCPerson3()
            try garage.parkObjects([nick, emily])
        }
        
        // Retrieve each person.
        do {
            let nick = try garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            #expect(nick != nil, "Failed to retrieve 'Nick' from garage store")
            
            let emily = try garage.retrieveObject(ObjCPerson.self, identifier: "Emily")
            #expect(emily != nil, "Failed to retrieve 'Emily' from garage store")
            
            let sam = try garage.retrieveObject(ObjCPerson.self, identifier: "Sam")
            #expect(sam == nil, "Should not have been able to retrieve 'Sam' from garage store")
        }
    }
    
    @Test("Test parking object with missing identifying attribute")
    func testMissingIdentifyingAttribute() async throws {
        let garage = makeTestGarage()
        
        // This should emit a logging message.
        // FIX: Once the GS implementation is converted to Swift, as each implementation is
        // converted to Codable, the 'identifying attribute' could be replaced by the hash value, and
        // then all we need to know is, should we use an object's hash value to uniquely identify it?
        do {
            let boat = ObjCBoat()
            boat.name = "BoatyMcBoatBoat"
            try garage.parkObject(boat)
        }
    }
    
    @Test("Test retrieving object with missing referenced object")
    func testMissingReferencedObject() async throws {
        let garage = makeTestGarage()

        // Create a "Sam" person and park it.
        do {
            let sam = objCPerson()
            try garage.parkObject(sam)
        }
        
        // Retrieve Nick and remove him
        do {
            let nick = try garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            let unwrappedNick = try #require(nick, "Failed to retrieve 'Nick' from garage store")
            
            try garage.deleteObject(unwrappedNick)
        }
        
        // Now try to retrieve Sam. This should fail because Sam references Nick, and Nick has been removed from storage.
        do {
            let sam = try garage.retrieveObject(ObjCPerson.self, identifier: "Sam")
            #expect(sam == nil, "Should not have been able to retrieve 'Sam' from garage store")
        } catch let error as NSError {
            // Refine this test point after we adopt Error enums.
            #expect(error.domain == Garage.errorDomain, "Unexpected error domain")
        }
    }
    
    @Test("Test parking nil object throws error")
    func testNilObject() async throws {
        // This tests the Objective-C interface to parkObject, which throws in Swift.
        let garage = makeTestGarage()
        
        // This should emit a logging message, and an error.
        
        do {
            #expect(throws: Error.self) {
                try garage.__parkObjectObjC(nil)
            }
        }
    }
    
    @Test("Test retrieving collections of objects")
    func testRetrievingCollections() async throws {
        let garage = makeTestGarage()
        
        // Park heterogeneous objects
        do {
            let sam = objCPerson()
            let nick = objCPerson2()
            let emily = objCPerson3()
            
            let oldAddress = objCAddress()
            let newAddress = objCAddress2()
            try garage.parkObjects([nick, emily, sam, oldAddress, newAddress])
        }
        
        // Retrieve persons
        do {
            let people = try garage.retrieveAllObjects(ObjCPerson.self)
            #expect(people.count == 3, "Number of Persons didn't match")
        }
        
        // Retrieve Addresses
        do {
            let addresses = try garage.retrieveAllObjects(ObjCAddress.self)
            #expect(addresses.count == 2, "Number of Persons didn't match")
        }
    }
    
    @Test("Test deleting an object")
    func testDeletingObject() async throws {
        let garage = makeTestGarage()
        
        // Park heterogeneous objects
        do {
            let sam = objCPerson()
            let nick = objCPerson2()
            let emily = objCPerson3()
            
            try garage.parkObjects([nick, emily, sam])
        }
        
        // Delete a person
        do {
            let nick = try garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            let unwrappedNick = try #require(nick, "We need nick, so we can delete him")
            
            try garage.deleteObject(unwrappedNick)
        } catch {
            print("Error deleting: \(error)")
        }
        
        // Confirm that the person has been deleted
        do {
            let nick = try garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            #expect(nick == nil, "Nick should be gone")
        }
    }
    
    @Test("Test deleting collections of objects")
    func testDeletingCollections() async throws {
        let garage = makeTestGarage()
        
        // Park heterogeneous objects
        do {
            let sam = objCPerson()
            let nick = objCPerson2()
            let emily = objCPerson3()
            
            let oldAddress = objCAddress()
            let newAddress = objCAddress2()
            try garage.parkObjects([nick, emily, sam, oldAddress, newAddress])
        }
        
        // Delete persons
        do {
            garage.deleteAllObjects(ObjCPerson.self)
        }
        
        // Confirm that there are no persons
        do {
            let persons = try garage.retrieveAllObjects(ObjCPerson.self)
            #expect(persons.count == 0, "Should not be any Persons")
            
            let addresses = try garage.retrieveAllObjects(ObjCAddress.self)
            #expect(addresses.count == 2, "Should have 2 Addresses")
            #expect(addresses[0].city == "Boston", "all addresses should be based in Boston")
        }
    }
    
    @Test("Test deleting all objects")
    func testDeletingAllObjects() async throws {
        let garage = makeTestGarage()
        
        // Park heterogeneous objects
        do {
            let sam = objCPerson()
            let nick = objCPerson2()
            let emily = objCPerson3()
            
            let oldAddress = objCAddress()
            let newAddress = objCAddress2()
            try garage.parkObjects([nick, emily, sam, oldAddress, newAddress])
        }
        
        // Delete everything
        do {
            garage.deleteAllObjects()
        }
        
        // Confirm that there are no persons
        do {
            let persons = try garage.retrieveAllObjects(ObjCPerson.self)
            #expect(persons.count == 0, "Should not be any Persons")
            
            let addresses = try garage.retrieveAllObjects(ObjCAddress.self)
            #expect(addresses.count == 0, "Should have 0 Addresses")
        }
        
        // Delete everything again (hits the no-op case, for code coverage)
        do {
            garage.deleteAllObjects(ObjCPerson.self)
            garage.deleteAllObjects()
        }
    }

    @Test("Test sync status management")
    func testSyncStatus() async throws {
        let garage = makeTestGarage()
        
        let sam = objCPerson()
        let nick = objCPerson2()
        let emily = objCPerson3()
        
        let oldAddress = objCAddress()
        let newAddress = objCAddress2()
        
        // Park heterogeneous objects
        do {
            try garage.parkObjects([nick, emily, sam, oldAddress, newAddress])
        }
        
        // Validate initial sync status of Persons
        do {
            let syncing = try garage.retrieveObjects(withStatus: .syncing)
            
            #expect(syncing.count == 1, "1 item should be syncing")
            
            let undetermined = try garage.retrieveObjects(withStatus: .undetermined)
            #expect(undetermined.count == 2, "2 items should be undetermined")
            
            let notSynced = try garage.retrieveObjects(withStatus: .notSynced)
            #expect(notSynced.count == 0, "no items should be not synced")
        }
        
        // Change Sam's sync status and validate that it changed
        do {
            try garage.setSyncStatus(.notSynced, for: sam)
            
            let syncing = try garage.retrieveObjects(withStatus: .syncing)
            #expect(syncing.count == 0, "items should be syncing")
            
            let undetermined = try garage.retrieveObjects(withStatus: .undetermined)
            #expect(undetermined.count == 2, "2 items should be undetermined")
            
            let notSynced = try garage.retrieveObjects(withStatus: .notSynced)
            #expect(notSynced.count == 1, "items should be not synced")
        }
        
        // Test setting sync status for a collection
        do {
            try garage.setSyncStatus(.undetermined, for: [nick, sam])
            #expect(try garage.syncStatus(for: nick) == .undetermined, "Nick should have undetermined sync status")
        }
        
        // Test retrieving objects with sync status of a particular class that isn't syncable
        do {
            let undetermined = try garage.retrieveObjects(withStatus: .undetermined, ofClass: ObjCAddress.self)
            #expect(undetermined.count == 0, "retrievedObjects should have returned 0")
        }
        
        // Test retrieving objects with sync status of a particular class that is syncable
        do {
            let undetermined = try garage.retrieveObjects(withStatus: .undetermined, ofClass: ObjCPerson.self)
            #expect(undetermined.count == 3, "retrievedObjects should have returned 3")
        }
    }
    
    @Test("Test setting sync status on unparked object throws error")
    func testInvalidSyncStatus() async throws {
        let garage = makeTestGarage()
        
        // Create, but don't park, sam
        let sam = objCPerson()
        
        do {
            #expect(throws: Error.self) {
                try garage.setSyncStatus(.notSynced, for: sam)
            }
            #expect(throws: Error.self) {
                try garage.setSyncStatus(.notSynced, for: [sam])
            }
        }
    }
    
    @Test("Test parking and retrieving dates")
    func testDates() async throws {
        let garage = makeTestGarage()
        
        do {
            let sam = objCPerson()
            
            // Set sam's birthdate to 1950/01/01

            var dateComponents = DateComponents()
            dateComponents.day = 1
            dateComponents.month = 1
            dateComponents.year = 1950
            dateComponents.timeZone = TimeZone(abbreviation: "UTC")
            let calendar = Calendar.current
            sam.birthdate = calendar.date(from: dateComponents)!
            #expect(sam.birthdate.timeIntervalSinceReferenceDate == -1609459200.0, "Validating assumption about the test in UTC time")
            
            try garage.parkObject(sam)
        }
        
        do {
            let sam = try garage.retrieveObject(ObjCPerson.self, identifier: "Sam")
            #expect(sam != nil, "Failed to retrieve 'Sam' from garage store")

            #expect(sam?.birthdate.timeIntervalSinceReferenceDate == -1609459200.0, "Reconstituted date failed")
        }
    }
    
    @Test("Test retrieving non-existent object behavior")
    func testNonExistentObject() async throws {
        let garage = makeTestGarage()
        
        // Swift behavior: be able to return nil for not found, not throw an error.
        do {
            let frodo = try garage.retrieveObject(ObjCPerson.self, identifier: "Frodo")
            #expect(frodo == nil, "Should be nil")
        }
        
        // Objective-C behavior: throw an error so that the ObjC runtime can return nil to an ObjC caller.
        do {
            #expect(throws: Error.self) {
                _ = try garage.__retrieveObjectObjC(ObjCPerson.self, identifier: "Frodo")
            }
        }
    }
}
