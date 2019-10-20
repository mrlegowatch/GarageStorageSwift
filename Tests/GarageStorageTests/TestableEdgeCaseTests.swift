//
//  TestableEdgeCaseTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/17/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import XCTest

@testable import GarageStorage

// This set of tests require access to internal GarageStorage APIs, to varying degrees.
class TestableEdgeCaseTests: XCTestCase {
    
    override func setUp() {
        // Reset the underlying storage before running each test.
        let garage = Garage()
        garage.deleteAllObjects()
    }
         
    func testBadTransformable() {
        let dictionary = [CoreDataObject.Attribute.type: Property.transformableType,
                          Property.transformableType: "Hello"]
        XCTAssertNil(Date(from: dictionary), "Transformable dictionary is missing its transformable type")
    }
    
    func testArrayOfArray() {
        let garage = Garage()
        
        do {
            let backpack = InfiniteBag("Backpack")
            let box = InfiniteBag("Box")
            backpack.contents.append(box)
            let sachel = InfiniteBag("Sachel")
            let purse = InfiniteBag("Purse")
            sachel.contents.append(purse)
            backpack.contents.append(sachel)
            
            XCTAssertNoThrow(try garage.parkObject(backpack))
        }
        
        do {
            let objects = try garage.retrieveAllObjects(InfiniteBag.self)
            XCTAssertEqual(objects.count, 4, "Should have retrieved 4 objects")
        }
        catch {
            XCTFail("retrieveAllObjects should not have failed, error = \(error)")
        }
    }
    
    func testSyncableAnonymous() {
        let garage = Garage()
        
        do {
            let address = ObjCSyncingAddress()
            address.street = "1212 Park Lane"
            address.city = "Boston"
            address.zip = "01012"
            
            let nick = objCPerson2()
            nick.address = address
            
            XCTAssertNoThrow(try garage.parkObjects([nick, address]))
        }
        
        do {
            let nick = try garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
            XCTAssertNotNil(nick, "Should be non-nil")
            guard nick != nil else {
                print("Skipping testSyncableAnonymous, nick is a nil object")
                return
            }
            
            let syncStatus = try garage.syncStatus(for: nick!)
            XCTAssertEqual(syncStatus, SyncStatus.undetermined, "Should have gotten undetermined sync status")
            
            let address = nick?.address as? ObjCSyncingAddress
            XCTAssertNotNil(address, "Should be non-nil")
        }
        catch {
            XCTFail("Should not have thrown an error: \(error)")
        }
    }
    
    func testMissingIdentifiable() {
        let garage = Garage()
        do {
            let fox = ObjCFox()
            // Ooops, missing identifiableAttribute: fox.name = "Sam"
            
            XCTAssertThrowsError(try garage.parkObject(fox), "should have thrown on missing identifier")
        }
        
        do {
            let fox = try? garage.retrieveObject(ObjCFox.self, identifier: "Sam")
            XCTAssertNil(fox, "retrieveObject should have thrown an error")
        }
    }
    
    func testMissingObjC() {
        print("Skipping test for missing @objc, because value(forKey:) throws an exception that isn't caught by XCTest")
        /*
         TODO: when we can catch an exception from value(forKey:) we can re-enabled this
         let garage = Garage()
         do {
         let goat = Goat()
         goat.name = "Sam"
         
         XCTAssertNoThrow(try garage.parkObject(goat))
         }
         
         do {
         let goat = try? garage.retrieveObject(Goat.self, identifier: "Sam")
         XCTAssertNil(goat, "retrieveObject should have thrown an error")
         }
         */
    }
    
    func testNotSyncable() {
        let garage = Garage()
        
        do {
            let address = swiftAddress()
            
            try garage.park(address)
            
            let syncStatus = try garage.syncStatus(for: address)
            XCTAssertEqual(syncStatus, .undetermined, "Sync status undetermined")
        }
        catch {
            XCTFail("No exception should have been thrown")
        }
    }
    
    func testInvalidStoreGarage() {
        let invalidStoreName = "Wazzup/OtherGarage.sqlite"
        let description = Garage.makePersistentStoreDescription(invalidStoreName)
        let garage = Garage(with: [description])
        garage.loadPersistentStores { (description, error) in
            XCTAssertNotNil(error, "Should have thrown an error")
        }
        
    }
        
    func testDateFormatter() {
        
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.month = 1
        dateComponents.year = 1950
        
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        XCTAssertEqual(date.timeIntervalSinceReferenceDate, -1609441200.0, "Making assumption about the test")

        do {
            let dateString = date.isoString
            XCTAssertEqual(dateString, "1950-01-01T00:00:00-05:00", "isoString failed")
        }
        
        do {
            let dateString = "1950-01-01T00:00:00-05:00"
            let date = Date.isoDate(for: dateString)
            XCTAssertNotNil(date)
            XCTAssertEqual(date?.timeIntervalSinceReferenceDate ?? 0, -1609441200.0, "Making assumption about the test")
        }
    }
}
