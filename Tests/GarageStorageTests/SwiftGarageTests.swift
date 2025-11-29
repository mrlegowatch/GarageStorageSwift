//
//  SwiftGarageTests.swift
//  GarageStorage
//
//  Created by Brian Arnold on 11/15/25.
//

import Testing
import GarageStorage
import Foundation

@Suite("Swift Garage Tests")
struct SwiftGarageTests {
    
    init() {
        TestSetup.classSetUp()
    }

    @Test("Convenience initializer creates garage with named store")
    func convenienceInitializer() throws {
        // Use the convenience initializer that creates a garage with a named store
        let garage = Garage(named: "GarageStorageTests/ConvenienceInitializer")
        
        // Verify the garage is functional by parking and retrieving an object
        let sam = swiftPerson()
        try garage.park(sam)
        
        let retrievedSam = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Sam"))
        #expect(retrievedSam.name == "Sam", "Expected Sam to be Sam")
        #expect(retrievedSam.importantDates.count == 3, "Expected 3 important dates")
        
        // Clean up
        garage.deleteAllObjects()
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
    
    @Test("Deleting all objects from garage")
    func deletingAllObjects() async throws {
        let garage = makeTestGarage()

        // Park heterogeneous objects
        let sam = swiftPerson()
        let nick = swiftPerson2()
        let emily = swiftPerson3()
        
        let oldAddress = swiftAddress()
        let newAddress = swiftAddress2()
        try garage.parkAll([nick, emily, sam])
        try garage.parkAll([oldAddress, newAddress])
        
        await withCheckedContinuation { continuation in
            // Delete everything
            garage.deleteAllObjects {
                // Confirm that there are no persons
                do {
                    let persons = try garage.retrieveAll(SwiftPerson.self)
                    #expect(persons.count == 0, "Should not be any Persons")
                    
                    let addresses = try garage.retrieveAll(SwiftAddress.self)
                    #expect(addresses.count == 0, "Should not be any Addresses")
                } catch {
                    Issue.record("Unexpected error: \(error)")
                }
                
                // Delete everything again (hits the no-op case, for code coverage)
                garage.deleteAll(SwiftPerson.self)
                garage.deleteAllObjects()
                
                continuation.resume()
            }
        }
    }
    
    @Test("Back-to-back deleteAllObjects calls for code coverage")
    func backToBackDeleteAllObjects() async throws {
        let garage = makeTestGarage()
        
        // Park three SwiftPerson objects
        let sam = swiftPerson()
        let nick = swiftPerson2()
        let emily = swiftPerson3()
        try garage.parkAll([sam, nick, emily])
        
        // Verify all three are parked
        let allPeople = try garage.retrieveAll(SwiftPerson.self)
        #expect(allPeople.count == 3, "Should have 3 people parked")
        
        // First deleteAllObjects call with completion handler
        await withCheckedContinuation { continuation in
            garage.deleteAllObjects()
            garage.deleteAllObjects {
                continuation.resume()
            }
        }
        
        // Verify all objects are deleted
        let peopleAfterFirstDelete = try garage.retrieveAll(SwiftPerson.self)
        #expect(peopleAfterFirstDelete.count == 0, "Should have no people after first delete")
                
        // Third deleteAllObjects call for additional coverage
        garage.deleteAllObjects()
        
        // Give it a moment to complete
        try await Task.sleep(for: .milliseconds(100))
        
        // Final verification
        let peopleAfterThirdDelete = try garage.retrieveAll(SwiftPerson.self)
        #expect(peopleAfterThirdDelete.count == 0, "Should still have no people after third delete")
    }
}
