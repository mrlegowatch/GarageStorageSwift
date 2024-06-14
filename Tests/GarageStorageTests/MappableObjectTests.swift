//
//  MappableObjectTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/12/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import XCTest

import Foundation
import GarageStorage
import CoreData

// This set of tests use Swift-declared Objective-C-compatible MappableObjects.
class MappableObjectTests: XCTestCase {
    
    override class func setUp() {
        TestSetup.classSetUp()
    }
    
    override func setUp() {
        // Reset the underlying storage before running each test.
        let garage = Garage()
        garage.deleteAllObjects()
    }
    
    func testMappableObject() {
        let garage = Garage()
        
        // Create a "Sam" person and park it.
        do {
            let sam = objCPerson()
            XCTAssertNoThrow(try garage.parkObject(sam), "parkObject")
        }
        
        // Retrieve the "Sam" person.
        do {
            let sam = try? garage.retrieveObject(ObjCPerson.self, identifier: "Sam")
            XCTAssertNotNil(sam, "Failed to retrieve 'Sam' from garage store")
            XCTAssertEqual(sam?.name ?? "", "Sam", "expected Sam to be Sam")
            XCTAssertEqual(sam?.importantDates.count ?? 0, 3, "expected 3 important dates")
            
            // Make sure brother and siblings worked out.
            let brother = sam?.brother
            XCTAssertNotNil(brother, "O brother, my brother")
            XCTAssertEqual(brother?.name ?? "", "Nick", "expected brother to be Nick")
            XCTAssertEqual(sam?.siblings.count, 2, "expected 2 siblings")
        }
    }
    
    func testArrayOfMappable() {
        let garage = Garage()
        
        // Create a pair of people and park them.
        do {
            let nick = objCPerson2()
            let emily = objCPerson3()
            XCTAssertNoThrow(try garage.parkObjects([nick, emily]), "parkObjects")
        }
        
        // Retrieve each person.
        do {
            let nick = try? garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            XCTAssertNotNil(nick, "Failed to retrieve 'Nick' from garage store")
            
            let emily = try? garage.retrieveObject(ObjCPerson.self, identifier: "Emily")
            XCTAssertNotNil(emily, "Failed to retrieve 'Emily' from garage store")
            
            let sam = try? garage.retrieveObject(ObjCPerson.self, identifier: "Sam")
            XCTAssertNil(sam, "Should not have been able to retrieve 'Sam' from garage store")
        }
    }
    
    func testMissingIdentifyingAttribute() {
        let garage = Garage()
        
        // This should emit a logging message.
        // FIX: Once the GS implementation is converted to Swift, as each implementation is
        // converted to Codable, the 'identifying attribute' could be replaced by the hash value, and
        // then all we need to know is, should we use an object's hash value to uniquely identify it?
        do {
            let boat = ObjCBoat()
            boat.name = "BoatyMcBoatBoat"
            XCTAssertNoThrow(try garage.parkObject(boat), "parkObject")
        }
    }
    
    func testMissingReferencedObject() {
        let garage = Garage()

        // Create a "Sam" person and park it.
        do {
            let sam = objCPerson()
            XCTAssertNoThrow(try garage.parkObject(sam), "parkObject")
        }
        
        // Retrieve Nick and remove him
        do {
            let nick = try? garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            XCTAssertNotNil(nick, "Failed to retrieve 'Nick' from garage store")
            
            XCTAssertNoThrow(try garage.deleteObject(nick!))
        }
        
        // Now try to retrieve Sam. This should fail because Sam references Nick, and Nick has been removed from storage.
        do {
            let sam = try? garage.retrieveObject(ObjCPerson.self, identifier: "Sam")
            XCTAssertNil(sam, "Should not have been able to retrieve 'Sam' from garage store")
        }
    }
    
    func testNilObject() {
        // This tests the Objective-C interface to parkObject, which throws in Swift.
        let garage = Garage()
        
        // This should emit a logging message, and an error.
        
        do {
            XCTAssertThrowsError(try garage.__parkObjectObjC(nil), "Should have thrown an error")
        }
    }
    
    func testRetrievingCollections() {
        let garage = Garage()
        
        // Park heterogeneous objects
        do {
            let sam = objCPerson()
            let nick = objCPerson2()
            let emily = objCPerson3()
            
            let oldAddress = objCAddress()
            let newAddress = objCAddress2()
            XCTAssertNoThrow(try garage.parkObjects([nick, emily, sam, oldAddress, newAddress]), "parkObjects")
        }
        
        // Retrieve persons
        do {
            let people = try garage.retrieveAllObjects(ObjCPerson.self)
            XCTAssertEqual(people.count, 3, "Number of Persons didn't match")
        }
        catch {
            XCTFail("retrieveAllObjects should not throw an error, \(error)")
        }
        
        // Retrieve Addresses
        do {
            let addresses = try garage.retrieveAllObjects(ObjCAddress.self)
            XCTAssertEqual(addresses.count, 2, "Number of Persons didn't match")
        }
        catch {
            XCTFail("retrieveAllObjects should not throw an error, \(error)")
        }
    }
    
    func testDeletingObject() {
        let garage = Garage()
        
        // Park heterogeneous objects
        do {
            let sam = objCPerson()
            let nick = objCPerson2()
            let emily = objCPerson3()
            
            XCTAssertNoThrow(try garage.parkObjects([nick, emily, sam]), "parkObjects")
        }
        
        // Delete a person
        do {
            let nick = try? garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            XCTAssertNotNil(nick, "We need nick, so we can delete him")
            
            XCTAssertNoThrow(try garage.deleteObject(nick!), "deleteObject")
        }
        
        // Confirm that the person has been deleted
        do {
            let nick = try? garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            XCTAssertNil(nick, "Nick should be gone")
        }
    }
    
    func testDeletingCollections() {
        let garage = Garage()
        
        // Park heterogeneous objects
        do {
            let sam = objCPerson()
            let nick = objCPerson2()
            let emily = objCPerson3()
            
            let oldAddress = objCAddress()
            let newAddress = objCAddress2()
            XCTAssertNoThrow(try garage.parkObjects([nick, emily, sam, oldAddress, newAddress]), "parkObjects")
        }
        
        // Delete persons
        do {
            garage.deleteAllObjects(ObjCPerson.self)
        }
        
        // Confirm that there are no persons
        do {
            let persons = try garage.retrieveAllObjects(ObjCPerson.self)
            XCTAssertEqual(persons.count, 0, "Should not be any Persons")
            
            let addresses = try garage.retrieveAllObjects(ObjCAddress.self)
            XCTAssertEqual(addresses.count, 2, "Should have 2 Addresses")
            XCTAssertEqual(addresses[0].city, "Boston", "all addresses should be based in Boston")
        }
        catch {
            XCTFail("retrieveAllObjects should not throw an error, \(error)")
        }
    }
    
    func testDeletingAllObjects() {
        let garage = Garage()
        
        // Park heterogeneous objects
        do {
            let sam = objCPerson()
            let nick = objCPerson2()
            let emily = objCPerson3()
            
            let oldAddress = objCAddress()
            let newAddress = objCAddress2()
            XCTAssertNoThrow(try garage.parkObjects([nick, emily, sam, oldAddress, newAddress]), "parkObjects")
        }
        
        // Delete everything
        do {
            garage.deleteAllObjects()
        }
        
        // Confirm that there are no persons
        do {
            let persons = try garage.retrieveAllObjects(ObjCPerson.self)
            XCTAssertEqual(persons.count, 0, "Should not be any Persons")
            
            let addresses = try garage.retrieveAllObjects(ObjCAddress.self)
            XCTAssertEqual(addresses.count, 0, "Should have 2 Addresses")
        }
        catch {
            XCTFail("retrieveAllObjects should not throw an error, \(error)")
        }
        
        // Delete everything again (hits the no-op case, for code coverage)
        do {
            garage.deleteAllObjects(ObjCPerson.self)
            garage.deleteAllObjects()
        }
    }

    func testSyncStatus() {
        let garage = Garage()
        
        let sam = objCPerson()
        let nick = objCPerson2()
        let emily = objCPerson3()
        
        let oldAddress = objCAddress()
        let newAddress = objCAddress2()
        
        // Park heterogeneous objects
        do {
            XCTAssertNoThrow(try garage.parkObjects([nick, emily, sam, oldAddress, newAddress]), "parkObjects")
        }
        
        // Validate initial sync status of Persons
        do {
            let syncing = try garage.retrieveObjects(withStatus: .syncing)
            
            XCTAssertEqual(syncing.count, 1, "1 item should be syncing")
            
            let undetermined = try garage.retrieveObjects(withStatus: .undetermined)
            XCTAssertEqual(undetermined.count, 2, "2 items should be undetermined")
            
            let notSynced = try garage.retrieveObjects(withStatus: .notSynced)
            XCTAssertEqual(notSynced.count, 0, "no items should be not synced")
        }
        catch {
            XCTFail("retrieveObjects should not throw an error, \(error)")
        }
        
        // Change Sam's sync status and validate that it changed
        do {
            XCTAssertNoThrow(try garage.setSyncStatus(.notSynced, for: sam), "setSyncStatus")
            
            let syncing = try garage.retrieveObjects(withStatus: .syncing)
            XCTAssertEqual(syncing.count, 0, "items should be syncing")
            
            let undetermined = try garage.retrieveObjects(withStatus: .undetermined)
            XCTAssertEqual(undetermined.count, 2, "2 items should be undetermined")
            
            let notSynced = try garage.retrieveObjects(withStatus: .notSynced)
            XCTAssertEqual(notSynced.count, 1, "items should be not synced")
        }
        catch {
            XCTFail("retrieveObjects calls should not have thrown an error: \(error)")
        }
        
        // Test setting sync status for a collection
        do {
            XCTAssertNoThrow(try garage.setSyncStatus(.undetermined, for: [nick, sam]), "setSyncStatus")
            XCTAssertEqual(try garage.syncStatus(for: nick), .undetermined, "Nick should have undetermined sync status")
        }
        
        // Test retrieving objects with sync status of a particular class that isn't syncable
        do {
            let undetermined = try garage.retrieveObjects(withStatus: .undetermined, ofClass: ObjCAddress.self)
            XCTAssertEqual(undetermined.count, 0, "retrievedObjects should have returned 0")
        }
        catch {
            XCTFail("retrieveObjects should not have thrown an error: \(error)")
        }
        
        // Test retrieving objects with sync status of a particular class that is syncable
        do {
            let undetermined = try garage.retrieveObjects(withStatus: .undetermined, ofClass: ObjCPerson.self)
            XCTAssertEqual(undetermined.count, 3, "retrievedObjects should have returned 2")
        }
        catch {
            XCTFail("retrieveObjects should not have thrown an error: \(error)")
        }
    }
    
    func testInvalidSyncStatus() {
        let garage = Garage()
        
        // Create, but don't park, sam
        let sam = objCPerson()
        
        do {
            XCTAssertThrowsError(try garage.setSyncStatus(.notSynced, for: sam), "setSyncStatus should have thrown an error")
            XCTAssertThrowsError(try garage.setSyncStatus(.notSynced, for: [sam]), "setSyncStatus should have thrown an error")
        }
    }
    
    func testDates() {
        let garage = Garage()
        
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
            XCTAssertEqual(sam.birthdate.timeIntervalSinceReferenceDate, -1609459200.0, "Validating assumption about the test in UTC time")
            
            XCTAssertNoThrow(try garage.parkObject(sam), "parkObject")
        }
        
        do {
            let sam = try? garage.retrieveObject(ObjCPerson.self, identifier: "Sam")
            XCTAssertNotNil(sam, "Failed to retrieve 'Sam' from garage store")

            XCTAssertEqual(sam?.birthdate.timeIntervalSinceReferenceDate ?? 0, -1609459200.0, "Reconstituted date failed")
        }
    }
    
    func testNonExistentObject() {
        let garage = Garage()
        
        do {
            let sam = try? garage.retrieveObject(ObjCPerson.self, identifier: "Frodo")
            XCTAssertNil(sam, "Should not have found Frodo")
        }
    }
}
