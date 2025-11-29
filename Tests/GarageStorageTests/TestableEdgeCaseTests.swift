//
//  TestableEdgeCaseTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/17/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import Testing
import CoreData

@testable import GarageStorage

// This set of tests require access to internal GarageStorage APIs, to varying degrees.
@Suite("Testable Edge Case Tests")
struct TestableEdgeCaseTests {
    
    init() {
        TestSetup.classSetUp()
    }
    
    @Test("Bad transformable dictionary should return nil")
    func badTransformable() async throws {
        let dictionary = [CoreDataObject.Attribute.type: Property.transformableType,
                          Property.transformableType: "Hello"]
        let date = Date(from: dictionary)
        #expect(date == nil, "Transformable dictionary is missing its transformable type")
    }
    
    @Test("Array of arrays should park and retrieve all nested objects")
    func arrayOfArray() async throws {
        let garage = makeTestGarage()
        
        let backpack = InfiniteBag("Backpack")
        let box = InfiniteBag("Box")
        backpack.contents.append(box)
        let sachel = InfiniteBag("Sachel")
        let purse = InfiniteBag("Purse")
        sachel.contents.append(purse)
        backpack.contents.append(sachel)
        
        try garage.parkObject(backpack)
        
        let objects = try garage.retrieveAllObjects(InfiniteBag.self)
        #expect(objects.count == 4, "Should have retrieved 4 objects")
    }
    
    @Test("Syncable anonymous objects should maintain sync status")
    func syncableAnonymous() async throws {
        let garage = makeTestGarage()
        
        let address = ObjCSyncingAddress()
        address.street = "1212 Park Lane"
        address.city = "Boston"
        address.zip = "01012"
        
        let nick = objCPerson2()
        nick.address = address
        
        try garage.parkObjects([nick, address])
        
        let retrievedNick = try garage.retrieveObject(ObjCPerson.self, identifier: "Nick")
        let unwrappedNick = try #require(retrievedNick, "Should be non-nil")
        
        let syncStatus = try garage.syncStatus(for: unwrappedNick)
        #expect(syncStatus == SyncStatus.undetermined, "Should have gotten undetermined sync status")
        
        let retrievedAddress = unwrappedNick.address as? ObjCSyncingAddress
        #expect(retrievedAddress != nil, "Should be non-nil")
    }
    
    @Test("Missing identifiable attribute should throw error")
    func missingIdentifiable() async throws {
        let garage = makeTestGarage()
        
        let fox = ObjCFox()
        // Oops, missing identifiableAttribute: fox.name = "Sam"
        
        #expect(throws: Error.self) {
            try garage.parkObject(fox)
        }
        
        let retrievedFox = try? garage.retrieveObject(ObjCFox.self, identifier: "Sam")
        #expect(retrievedFox == nil, "retrieveObject should have returned nil")
    }
         
    @Test("Date formatter ISO string conversion")
    func dateFormatter() async throws {
        
        let timeZone = TestSetup.timeZone
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.month = 1
        dateComponents.year = 1950
        dateComponents.timeZone = timeZone
        
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let date = calendar.date(from: dateComponents)!
        #expect(date.timeIntervalSinceReferenceDate == -1609459200.0, "Making assumption about the test")

        do {
            let dateString = date.isoString
            #expect(dateString == "1950-01-01T00:00:00Z", "isoString failed")
        }
        
        do {
            let dateString = "1950-01-01T00:00:00-05:00"
            let date = Date.isoDate(for: dateString)
            #expect(date != nil)
            #expect((date?.timeIntervalSinceReferenceDate ?? 0) == -1609441200.0, "Making assumption about the test")
        }
    }
    
    @Test("Custom encryptor encrypts data differently than unencrypted storage")
    func customEncryptor() async throws {
        let storeName = "GarageStorageTests/CustomEncryptorGarage.sqlite"
        let description = Garage.makePersistentStoreDescription(storeName)
#if os(iOS)
        description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
#endif
        let encryptor = CustomDataEncryptor()
        let garage = Garage(with: [description])
        garage.dataEncryptionDelegate = encryptor
        garage.loadPersistentStores { (description, error) in
            #expect(error == nil, "Should not have thrown an error")
        }
        
        let unencryptedStoreName = "NoEncryptorGarage.sqlite"
        let unencryptedDescription = Garage.makePersistentStoreDescription(unencryptedStoreName)
        let unencryptedGarage = Garage(with: [unencryptedDescription])
        unencryptedGarage.loadPersistentStores { (description, error) in
            #expect(error == nil, "Should not have thrown an error")
        }
        
        // And this, kids, is why you sometimes need to validate implementation details for things that are hidden from the public API. Because, you see, I first wrote the above code passing in CustomDataEncryptor() directly, which meant it went out of scope by the time the data encoding / encryption would take place, so the resulting string was not encrypted, or decrypted, and the test passed anyway. I fixed the code above, but not before confirming the code below would fail first.
        do {
            let sam = swiftPerson()
            // In Swift Testing, we verify that operations don't throw by not catching
            try garage.park(sam)
            try unencryptedGarage.park(sam)

            let className = String(describing: type(of: sam))
            
            nonisolated(unsafe) let garageRef = garage
            nonisolated(unsafe) let unencryptedGarageRef = unencryptedGarage
            
            let coreDataObject = garage.context.performAndWait {
                return garageRef.fetchObject(for: className, identifier: "Sam")
            }
            let unencryptedCoreDataObject = unencryptedGarage.context.performAndWait {
                return unencryptedGarageRef.fetchObject(for: className, identifier: "Sam")
            }
            guard let encryptedString = coreDataObject?.gs_data,
                let unencryptedString = unencryptedCoreDataObject?.gs_data else {
                    Issue.record("Failed to encode data, bailing test")
                    return
            }
            #expect(encryptedString != unencryptedString, "should not match")
        }
    }
}
