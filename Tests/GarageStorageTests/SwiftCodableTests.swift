//
//  SwiftCodableTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/30/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import XCTest
import GarageStorage
import CoreData

// This set of tests checks Codable (hence "Swift-y") types.
class SwiftCodableTests: XCTestCase {

    override class func setUp() {
        TestSetup.classSetUp()
    }
    
    override func setUp() {
        // Reset the underlying storage before running each test.
        let garage = Garage(named: testStoreName)
        garage.deleteAllObjects()
    }
    
    func testIdentifiable() {
        let garage = Garage(named: testStoreName)
        
        // Create a "Sam" person and park it.
        do {
            let sam = swiftPerson()
            try? garage.park(sam)//XCTAssertNoThrow(..., "parkObject")
        }
        
        // Retrieve the "Sam" person.
        do {
            let sam = try? garage.retrieve(SwiftPerson.self, identifier: "Sam")
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

    func testMappableNonString() {
        let garage = Garage(named: testStoreName)
        
        // Create a "Peaches" pet and park it.
        do {
            let pet = swiftPet()
            let pet2 = swiftPet2()
            try? garage.parkAll([pet, pet2])
        }
        
        // Retrieve each pet by identifier.
        do {
            let pet = try? garage.retrieve(SwiftPet.self, identifier: 3)
            XCTAssertNotNil(pet, "Failed to retrieve 'Peaches' from garage")
            XCTAssertEqual(pet?.name ?? "", "Peaches", "expected Peaches to be Peaches")
    
            let pet2 = try? garage.retrieve(SwiftPet.self, identifier: 5)
            XCTAssertNotNil(pet2, "Failed to retrieve 'Cream' from garage")
            XCTAssertEqual(pet2?.name ?? "", "Cream", "expected Cream to be Cream")
            
            XCTAssertNotEqual(pet, pet2, "expected different pets")
            
            let pet3 = try? garage.retrieve(SwiftPet.self, identifier: 3)
            XCTAssertNotNil(pet3, "Failed to retrieve 'Cream' from garage")
            XCTAssertEqual(pet, pet3, "expected separate fetches to return equivalent objects")
        }
    }

    func testArrayOfIdentifiable() {
        let garage = Garage(named: testStoreName)
        
        // Create a pair of people and park them.
        do {
            let nick = swiftPerson2()
            let emily = swiftPerson3()
            XCTAssertNoThrow(try garage.parkAll([nick, emily]), "parkObjects")
        }
        
        // Retrieve each person.
        do {
            let nick = try? garage.retrieve(SwiftPerson.self, identifier: "Nick")
            XCTAssertNotNil(nick, "Failed to retrieve 'Nick' from garage store")
            
            let emily = try? garage.retrieve(SwiftPerson.self, identifier: "Emily")
            XCTAssertNotNil(emily, "Failed to retrieve 'Emily' from garage store")
            
            let sam = try? garage.retrieve(SwiftPerson.self, identifier: "Sam")
            XCTAssertNil(sam, "Should not have been able to retrieve 'Sam' from garage store")
        }
    }

    func testRetrievingCollections() {
        let garage = Garage(named: testStoreName)
        
        // Park heterogeneous objects
        do {
            let sam = swiftPerson()
            let nick = swiftPerson2()
            let emily = swiftPerson3()
            
            let oldAddress = swiftAddress()
            let newAddress = swiftAddress2()
            // Swift strong type checking needs arrays to be homogeneous, and therefore separately parked
            XCTAssertNoThrow(try garage.parkAll([nick, emily, sam]), "parkAll")
            XCTAssertNoThrow(try garage.parkAll([oldAddress, newAddress]), "parkAll")
        }
        
        // Retrieve persons
        do {
            let people = try garage.retrieveAll(SwiftPerson.self)
            XCTAssertEqual(people.count, 3, "Number of Persons didn't match")
            
            // Check that everybody is there
            var names = ["Sam", "Nick", "Emily"]
            for person in people {
                names.removeAll { person.name == $0 }
            }
            XCTAssertEqual(names.count, 0, "should have found all 3 people")
        }
        catch {
            XCTFail("retrieveAllObjects should not throw an error, \(error)")
        }
        
        // Retrieve Addresses
        do {
            let addresses = try garage.retrieveAll(SwiftAddress.self)
            XCTAssertEqual(addresses.count, 2, "Number of Persons didn't match")
        }
        catch {
            XCTFail("retrieveAllObjects should not throw an error, \(error)")
        }
    }
    

    func testDeletingObject() {
        let garage = Garage(named: testStoreName)
        
        // Park heterogeneous objects
        do {
            let sam = swiftPerson()
            let nick = swiftPerson2()
            let emily = swiftPerson3()
            
            XCTAssertNoThrow(try garage.parkAll([nick, emily, sam]), "parkAll")
        }
        
        // Delete a person
        do {
            let nick = try? garage.retrieve(SwiftPerson.self, identifier: "Nick")
            XCTAssertNotNil(nick, "We need nick, so we can delete him")
            if let nick = nick {
                XCTAssertNoThrow(try garage.delete(nick), "deleteObject")
            }
        }
        
        // Confirm that the person has been deleted
        do {
            let nick = try? garage.retrieve(SwiftPerson.self, identifier: "Nick")
            XCTAssertNil(nick, "Nick should be gone")
        }
    }
 
    func testDeletingCollections() {
        let garage = Garage(named: testStoreName)
        
        // Park heterogeneous objects
        do {
            let sam = swiftPerson()
            let nick = swiftPerson2()
            let emily = swiftPerson3()
            
            let oldAddress = swiftAddress()
            let newAddress = swiftAddress2()
            XCTAssertNoThrow(try garage.parkAll([nick, emily, sam]), "parkAll")
            XCTAssertNoThrow(try garage.parkAll([oldAddress, newAddress]), "parkAll")
        }
        
        // Delete persons
        do {
            garage.deleteAll(SwiftPerson.self)
        }
        
        // Confirm that there are no persons
        do {
            let persons = try garage.retrieveAll(SwiftPerson.self)
            XCTAssertEqual(persons.count, 0, "Should not be any Persons")
            
            let addresses = try garage.retrieveAll(SwiftAddress.self)
            XCTAssertEqual(addresses.count, 2, "Should have 2 Addresses")
            XCTAssertEqual(addresses[0].city, "Boston", "all addresses should be based in Boston")
        }
        catch {
            XCTFail("retrieveAll should not throw an error, \(error)")
        }
    }


    func testDeletingAllObjects() {
        let garage = Garage(named: testStoreName)
        
        // Park heterogeneous objects
        do {
            let sam = swiftPerson()
            let nick = swiftPerson2()
            let emily = swiftPerson3()
            
            let oldAddress = swiftAddress()
            let newAddress = swiftAddress2()
            XCTAssertNoThrow(try garage.parkAll([nick, emily, sam]), "parkAll")
            XCTAssertNoThrow(try garage.parkAll([oldAddress, newAddress]), "parkAll")
        }
        
        // Delete everything
        do {
            garage.deleteAllObjects()
        }
        
        // Confirm that there are no persons
        do {
            let persons = try garage.retrieveAll(SwiftPerson.self)
            XCTAssertEqual(persons.count, 0, "Should not be any Persons")
            
            let addresses = try garage.retrieveAll(SwiftAddress.self)
            XCTAssertEqual(addresses.count, 0, "Should not be any Addresses")
        }
        catch {
            XCTFail("retrieveAllObjects should not throw an error, \(error)")
        }
        
        // Delete everything again (hits the no-op case, for code coverage)
        do {
            garage.deleteAll(SwiftPerson.self)
            garage.deleteAllObjects()
        }
    }

    
    func testDates() {
        let garage = Garage(named: testStoreName)
        
        do {
            let sam = swiftPerson()
            
            // Set sam's birthdate to 1950/01/01 04:00:00

            let timeZone = TestSetup.timeZone
            var dateComponents = DateComponents()
            dateComponents.day = 1
            dateComponents.month = 1
            dateComponents.year = 1950
            dateComponents.timeZone = timeZone
            
            var calendar = Calendar.current
            calendar.timeZone = timeZone
            sam.birthdate = calendar.date(from: dateComponents)!
            XCTAssertEqual(sam.birthdate.timeIntervalSinceReferenceDate, -1609459200.0, "Making assumption about the test")
            
            XCTAssertNoThrow(try garage.park(sam), "parkObject")
        }
        
        do {
            let sam = try? garage.retrieve(SwiftPerson.self, identifier: "Sam")
            XCTAssertNotNil(sam, "Failed to retrieve 'Sam' from garage store")

            XCTAssertEqual(sam?.birthdate.timeIntervalSinceReferenceDate ?? 0, -1609459200.0, "Reconstituted date failed")
        }
    }
    
    func testIdentifiableReferences() {
        let garage = Garage(named: testStoreName)

        do {
            // Configure a tree consisting of lots of referenced branches
            let topBranch = SwiftBranch(name: "Top")
            let upperBranch = SwiftBranch(name: "Upper")
            let lowerBranch = SwiftBranch(name: "Lower")
            let bottomBranch = SwiftBranch(name: "Bottom")
            
            // Careful with structs! Once rightBranch goes into leftBranch's branches, changing rightBranch's branches does not affect the one that went into leftBranch.
            // Use references when you mean to use them.
            var rightBranch = SwiftBranch(name: "Right")
            rightBranch.branches = [lowerBranch, bottomBranch]
            var leftBranch = SwiftBranch(name: "Left")
            leftBranch.branches = [upperBranch, rightBranch, topBranch]
            
            let tree = SwiftTree(name: "Tree", mainBranch: leftBranch)

            // Note that we only need to park the toplevel object, the rest are parked for free.
            XCTAssertNoThrow(try garage.park(tree), "park should not throw")
        }
        
        do {
            let tree = try? garage.retrieve(SwiftTree.self, identifier: "Tree")
            XCTAssertNotNil(tree, "tree should be non-nil")
            
            let leftBranch = try? garage.retrieve(SwiftBranch.self, identifier: "Left")
            XCTAssertNotNil(leftBranch, "leftBranch should be non-nil")

            XCTAssertEqual(tree?.mainBranch.branches.count ?? 0, 3, "Should have 3 branches")
            XCTAssertEqual(tree?.mainBranch, leftBranch, "Should be equal")

            let rightBranch = try? garage.retrieve(SwiftBranch.self, identifier: "Right")
            XCTAssertNotNil(rightBranch, "rightBranch should be non-nil")

            XCTAssertEqual(rightBranch?.branches.count ?? 0, 2, "Should have 2 branches")

        }
    }
    
    func testNonExistentObject() {
        let garage = Garage(named: testStoreName)
        
        do {
            let frodo = try garage.retrieve(SwiftPerson.self, identifier: "Frodo")
            XCTAssertNil(frodo, "Should be nil")
        }
        catch {
            XCTFail("Should not have thrown an error: \(error)")
        }
    }
    
    // This test seeks to ensure that an Identifiable can also be encoded to pure JSON (no references, only values).
    func testPureSwiftCodable() {
        // No garage
        
        let data: Data
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let sam = swiftPerson()
            data = try encoder.encode(sam)
            
            // For debugging:
            //let string = String(data: data, encoding: .utf8)!
            //print(string)
        }
        catch {
            XCTFail("Should not fail to decode")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let sam = try decoder.decode(SwiftPerson.self, from: data)
            XCTAssertEqual(sam.name, "Sam", "name")
            XCTAssertEqual(sam.address, swiftAddress(), "address")
            XCTAssertNotNil(sam.brother, "brother")
            XCTAssertEqual(sam.siblings.count, 2, "siblings")
        }
        catch let error as NSError {
            XCTFail("Should not fail to decode, error: \(error.debugDescription)")
            return
        }
    }
}
