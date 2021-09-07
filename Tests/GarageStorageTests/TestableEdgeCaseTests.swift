//
//  TestableEdgeCaseTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/17/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import XCTest
import CoreData

@testable import GarageStorage

// This set of tests require access to internal GarageStorage APIs, to varying degrees.
class TestableEdgeCaseTests: XCTestCase {
    
    override class func setUp() {
        TestSetup.classSetUp()
    }
    
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
    
    func testInvalidStoreGarage() {
        let invalidStoreName = "Wazzup/OtherGarage.sqlite"
        let description = Garage.makePersistentStoreDescription(invalidStoreName)
        let garage = Garage(with: [description])
        garage.loadPersistentStores { (description, error) in
            XCTAssertNotNil(error, "Should have thrown an error")
        }
        
    }
        
    func testDateFormatter() {
        
        let timeZone = TestSetup.timeZone
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.month = 1
        dateComponents.year = 1950
        dateComponents.timeZone = timeZone
        
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let date = calendar.date(from: dateComponents)!
        XCTAssertEqual(date.timeIntervalSinceReferenceDate, -1609459200.0, "Making assumption about the test")

        do {
            let dateString = date.isoString
            XCTAssertEqual(dateString, "1950-01-01T00:00:00Z", "isoString failed")
        }
        
        do {
            let dateString = "1950-01-01T00:00:00-05:00"
            let date = Date.isoDate(for: dateString)
            XCTAssertNotNil(date)
            XCTAssertEqual(date?.timeIntervalSinceReferenceDate ?? 0, -1609441200.0, "Making assumption about the test")
        }
    }
    
    func testCustomEncryptor() {
        let storeName = "CustomEncryptorGarage.sqlite"
        let description = Garage.makePersistentStoreDescription(storeName)
#if os(iOS)
        description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
#endif
        let encryptor = CustomDataEncryptor()
        let garage = Garage(with: [description])
        garage.dataEncryptionDelegate = encryptor
        garage.loadPersistentStores { (description, error) in
            XCTAssertNil(error, "Should not have thrown an error")
        }
        
        let unencryptedStoreName = "NoEncryptorGarage.sqlite"
        let unencryptedDescription = Garage.makePersistentStoreDescription(unencryptedStoreName)
        let unencryptedGarage = Garage(with: [unencryptedDescription])
        unencryptedGarage.loadPersistentStores { (description, error) in
            XCTAssertNil(error, "Should not have thrown an error")
        }
        
        // And this, kids, is why you sometimes need to validate implementation details for things that are hidden from the public API. Because, you see, I first wrote the above code passing in CustomDataEncryptor() directly, which meant it went out of scope by the time the data encoding / encryption would take place, so the resulting string was not encrypted, or decrypted, and the test passed anyway. I fixed the code above, but not before confirming the code below would fail first.
        do {
            let sam = swiftPerson()
            XCTAssertNoThrow(try garage.park(sam), "parkObject")
            XCTAssertNoThrow(try unencryptedGarage.park(sam), "parkObject")

            let className = String(describing: type(of: sam))
            let coreDataObject = garage.fetchObject(for: className, identifier: "Sam")
            
            let unencryptedCoreDataObject = unencryptedGarage.fetchObject(for: className, identifier: "Sam")
            
            guard let encryptedString = coreDataObject?.gs_data,
                let unencryptedString = unencryptedCoreDataObject?.gs_data else {
                    XCTFail("Failed to encode data, bailing test")
                    return
            }
            XCTAssertNotEqual(encryptedString, unencryptedString, "should not match")
        }
    }

}
