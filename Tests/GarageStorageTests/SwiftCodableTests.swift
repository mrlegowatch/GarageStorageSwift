//
//  SwiftCodableTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/30/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Testing
import GarageStorage
import CoreData

// This set of tests checks Codable (hence "Swift-y") types.
@Suite("Swift Codable Tests")
struct SwiftCodableTests {
    
    init() {
        TestSetup.classSetUp()
    }
    
    @Test("Identifiable objects can be parked and retrieved")
    func identifiable() throws {
        let garage = makeTestGarage()
        
        // Create a "Sam" person and park it.
        let sam = swiftPerson()
        try garage.park(sam)
        
        // Retrieve the "Sam" person.
        let retrievedSam = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Sam"))
        #expect(retrievedSam.name == "Sam", "expected Sam to be Sam")
        #expect(retrievedSam.importantDates.count == 3, "expected 3 important dates")
        
        // Make sure brother and siblings worked out.
        let brother = retrievedSam.brother
        #expect(brother != nil, "O brother, my brother")
        #expect(brother?.name == "Nick", "expected brother to be Nick")
        #expect(retrievedSam.siblings.count == 2, "expected 2 siblings")
    }

    @Test("Mappable non-string identifiers work correctly")
    func mappableNonString() throws {
        let garage = makeTestGarage()

        // Create a "Peaches" pet and park it.
        let pet = swiftPet()
        let pet2 = swiftPet2()
        try garage.parkAll([pet, pet2])
        
        // Retrieve each pet by identifier.
        let retrievedPet = try #require(try garage.retrieve(SwiftPet.self, identifier: 3))
        #expect(retrievedPet.name == "Peaches", "expected Peaches to be Peaches")

        let retrievedPet2 = try #require(try garage.retrieve(SwiftPet.self, identifier: 5))
        #expect(retrievedPet2.name == "Cream", "expected Cream to be Cream")
        
        #expect(retrievedPet != retrievedPet2, "expected different pets")
        
        let retrievedPet3 = try #require(try garage.retrieve(SwiftPet.self, identifier: 3))
        #expect(retrievedPet == retrievedPet3, "expected separate fetches to return equivalent objects")
    }

    @Test("Array of identifiable objects can be parked")
    func arrayOfIdentifiable() throws {
        let garage = makeTestGarage()

        // Create a pair of people and park them.
        let nick = swiftPerson2()
        let emily = swiftPerson3()
        try garage.parkAll([nick, emily])
        
        // Retrieve each person.
        let retrievedNick = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Nick"))
        #expect(retrievedNick.name == "Nick", "Failed to retrieve 'Nick' from garage store")
        
        let retrievedEmily = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Emily"))
        #expect(retrievedEmily.name == "Emily", "Failed to retrieve 'Emily' from garage store")
        
        let sam = try? garage.retrieve(SwiftPerson.self, identifier: "Sam")
        #expect(sam == nil, "Should not have been able to retrieve 'Sam' from garage store")
    }

    @Test("Retrieving collections of different types")
    func retrievingCollections() throws {
        let garage = makeTestGarage()

        // Park heterogeneous objects
        let sam = swiftPerson()
        let nick = swiftPerson2()
        let emily = swiftPerson3()
        
        let oldAddress = swiftAddress()
        let newAddress = swiftAddress2()
        // Swift strong type checking needs arrays to be homogeneous, and therefore separately parked
        try garage.parkAll([nick, emily, sam])
        try garage.parkAll([oldAddress, newAddress])
        
        // Retrieve persons
        let people = try garage.retrieveAll(SwiftPerson.self)
        #expect(people.count == 3, "Number of Persons didn't match")
        
        // Check that everybody is there
        var names = ["Sam", "Nick", "Emily"]
        for person in people {
            names.removeAll { person.name == $0 }
        }
        #expect(names.count == 0, "should have found all 3 people")
        
        // Retrieve Addresses
        let addresses = try garage.retrieveAll(SwiftAddress.self)
        #expect(addresses.count == 2, "Number of Addresses didn't match")
    }

    @Test("Deleting a single object")
    func deletingObject() throws {
        let garage = makeTestGarage()

        // Park heterogeneous objects
        let sam = swiftPerson()
        let nick = swiftPerson2()
        let emily = swiftPerson3()
        
        try garage.parkAll([nick, emily, sam])
        
        // Delete a person
        let nickToDelete = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Nick"))
        try garage.delete(nickToDelete)
        
        // Confirm that the person has been deleted
        let retrievedNick = try? garage.retrieve(SwiftPerson.self, identifier: "Nick")
        #expect(retrievedNick == nil, "Nick should be gone")
    }
 
    @Test("Deleting collections by type")
    func deletingCollections() throws {
        let garage = makeTestGarage()

        // Park heterogeneous objects
        let sam = swiftPerson()
        let nick = swiftPerson2()
        let emily = swiftPerson3()
        
        let oldAddress = swiftAddress()
        let newAddress = swiftAddress2()
        try garage.parkAll([nick, emily, sam])
        try garage.parkAll([oldAddress, newAddress])
        
        // Delete persons
        garage.deleteAll(SwiftPerson.self)
        
        // Confirm that there are no persons
        let persons = try garage.retrieveAll(SwiftPerson.self)
        #expect(persons.count == 0, "Should not be any Persons")
        
        let addresses = try garage.retrieveAll(SwiftAddress.self)
        #expect(addresses.count == 2, "Should have 2 Addresses")
        #expect(addresses[0].city == "Boston", "all addresses should be based in Boston")
    }

    @Test("Deleting all objects from garage")
    func deletingAllObjects() throws {
        let garage = makeTestGarage()

        // Park heterogeneous objects
        let sam = swiftPerson()
        let nick = swiftPerson2()
        let emily = swiftPerson3()
        
        let oldAddress = swiftAddress()
        let newAddress = swiftAddress2()
        try garage.parkAll([nick, emily, sam])
        try garage.parkAll([oldAddress, newAddress])
        
        // Delete everything
        garage.deleteAllObjects()
        
        // Confirm that there are no persons
        let persons = try garage.retrieveAll(SwiftPerson.self)
        #expect(persons.count == 0, "Should not be any Persons")
        
        let addresses = try garage.retrieveAll(SwiftAddress.self)
        #expect(addresses.count == 0, "Should not be any Addresses")
        
        // Delete everything again (hits the no-op case, for code coverage)
        garage.deleteAll(SwiftPerson.self)
        garage.deleteAllObjects()
    }

    @Test("Date encoding and decoding")
    func dates() throws {
        let garage = makeTestGarage()

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
        #expect(sam.birthdate.timeIntervalSinceReferenceDate == -1609459200.0, "Making assumption about the test")
        
        try garage.park(sam)
        
        let retrievedSam = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Sam"))
        #expect(retrievedSam.birthdate.timeIntervalSinceReferenceDate == -1609459200.0, "Reconstituted date failed")
    }
    
    @Test("Identifiable references are preserved")
    func identifiableReferences() throws {
        let garage = makeTestGarage()

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
        try garage.park(tree)
        
        let retrievedTree = try #require(try garage.retrieve(SwiftTree.self, identifier: "Tree"))
        
        let leftBranchRetrieved = try #require(try garage.retrieve(SwiftBranch.self, identifier: "Left"))

        #expect(retrievedTree.mainBranch.branches.count == 3, "Should have 3 branches")
        #expect(retrievedTree.mainBranch == leftBranchRetrieved, "Should be equal")

        let rightBranchRetrieved = try #require(try garage.retrieve(SwiftBranch.self, identifier: "Right"))
        #expect(rightBranchRetrieved.branches.count == 2, "Should have 2 branches")
    }
    
    @Test("Retrieving non-existent object returns nil")
    func nonExistentObject() throws {
        let garage = makeTestGarage()

        let frodo = try? garage.retrieve(SwiftPerson.self, identifier: "Frodo")
        #expect(frodo == nil, "Should be nil")
    }
    
    @Test("Identifiable can be encoded to pure JSON")
    func pureSwiftCodable() throws {
        // No garage
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let sam = swiftPerson()
        let data = try encoder.encode(sam)
        
        // For debugging:
        //let string = String(data: data, encoding: .utf8)!
        //print(string)
        
        let decoder = JSONDecoder()
        let decodedSam = try decoder.decode(SwiftPerson.self, from: data)
        #expect(decodedSam.name == "Sam", "name")
        #expect(decodedSam.address == swiftAddress(), "address")
        #expect(decodedSam.brother != nil, "brother")
        #expect(decodedSam.siblings.count == 2, "siblings")
    }
    
    @Test("Autosave disabled requires manual save")
    func autosaveDisabled() throws {
        let garage = makeTestGarage()
        
        // Verify autosave is enabled by default
        #expect(garage.isAutosaveEnabled == true, "Autosave should be enabled by default")
        
        // Create and park people using withAutosaveDisabled
        try garage.withAutosaveDisabled {
            let nick = swiftPerson2()
            let emily = swiftPerson3()
            try garage.park(nick)
            try garage.park(emily)
        }
        
        // Verify autosave is re-enabled after the closure
        #expect(garage.isAutosaveEnabled == true, "Autosave should be re-enabled after closure")
        
        // Now manually save the garage
        garage.save()
        
        // Retrieve the objects to verify they were saved
        let retrievedNick = try? garage.retrieve(SwiftPerson.self, identifier: "Nick")
        #expect(retrievedNick != nil, "Object should be retrievable after manual save")
        #expect(retrievedNick?.name == "Nick", "Retrieved object should have correct name")
        
        let retrievedEmily = try? garage.retrieve(SwiftPerson.self, identifier: "Emily")
        #expect(retrievedEmily != nil, "Emily should be retrievable after manual save")
        #expect(retrievedEmily?.name == "Emily", "Retrieved Emily should have correct name")
    }

    @Test("Convenience initializer creates garage with named store")
    func convenienceInitializer() throws {
        // Use the convenience initializer that creates a garage with a named store
        let garage = Garage(named: "TestGarage")
        
        // Verify the garage is functional by parking and retrieving an object
        let sam = swiftPerson()
        try garage.park(sam)
        
        let retrievedSam = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Sam"))
        #expect(retrievedSam.name == "Sam", "Expected Sam to be Sam")
        #expect(retrievedSam.importantDates.count == 3, "Expected 3 important dates")
        
        // Clean up
        garage.deleteAllObjects()
    }

    @Test("Hashable park and delete")
    func hashableParkAndDelete() throws {
        let garage = makeTestGarage()
        
        // Create and park addresses using Hashable methods
        let address1 = swiftAddress()
        let address2 = swiftAddress2()
        try garage.park(address1)
        try garage.park(address2)
        
        // Retrieve addresses using their hashValue
        let retrievedAddress1 = try #require(try garage.retrieve(SwiftAddress.self, identifier: address1.hashValue))
        #expect(retrievedAddress1.street == "330 Congress St.", "expected street to match")
        #expect(retrievedAddress1.city == "Boston", "expected city to match")
        #expect(retrievedAddress1.zip == "02140", "expected zip to match")
        
        let retrievedAddress2 = try #require(try garage.retrieve(SwiftAddress.self, identifier: address2.hashValue))
        #expect(retrievedAddress2.street == "321 Summer Street", "expected street to match")
        
        // Delete first address using Hashable delete method
        try garage.delete(address1)
        
        // Confirm first address is deleted
        let deletedAddress = try? garage.retrieve(SwiftAddress.self, identifier: address1.hashValue)
        #expect(deletedAddress == nil, "First address should be deleted")
        
        // Confirm second address still exists
        let stillExistingAddress = try #require(try garage.retrieve(SwiftAddress.self, identifier: address2.hashValue))
        #expect(stillExistingAddress == address2, "Second address should still exist")
        
        // Delete second address
        try garage.delete(address2)
        
        // Confirm both addresses are now deleted
        let allAddresses = try garage.retrieveAll(SwiftAddress.self)
        #expect(allAddresses.count == 0, "All addresses should be deleted")
    }
}
