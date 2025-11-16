//
//  SwiftErrorTests.swift
//  GarageStorage
//
//  Created by Brian Arnold on 11/16/25.
//

import Testing
@testable import GarageStorage
import Foundation

class TestCoreData: Codable { }

@Suite("GarageError Tests")
struct SwiftErrorTests {
    
    init() {
        TestSetup.classSetUp()
    }
    
    // MARK: - Error Domain Tests
        
    @Test("Garage.errorDomain matches GarageError.errorDomain")
    func garageErrorDomainCompatibility() {
        #expect(Garage.errorDomain == GarageError.errorDomain)
        #expect(Garage.errorDomain == "GarageStorage")
    }
    
    // MARK: - NSError Conversion Tests
    
    @Test("GarageError converts to NSError with correct domain")
    func nsErrorDomain() {
        let error = GarageError.failedToRetrieveObject("TestType", "test-id")
        let nsError = error as NSError
        
        #expect(nsError.domain == "GarageStorage")
    }
    
    // MARK: - failedToRetrieveObject Tests
    
    @Test("failedToRetrieveObject error has correct userInfo")
    func failedToRetrieveObjectUserInfo() {
        let error = GarageError.failedToRetrieveObject("SwiftPerson", "Sam")
        
        let userInfo = error.errorUserInfo
        let description = userInfo[NSLocalizedDescriptionKey] as? String
        
        #expect(description != nil)
        #expect(description?.contains("SwiftPerson") == true)
        #expect(description?.contains("Sam") == true)
        #expect(description == "Failed to retrieve object of type: SwiftPerson with identifier: Sam")
    }
    
    @Test("failedToRetrieveObject NSError has localized description")
    func failedToRetrieveObjectNSError() {
        let error = GarageError.failedToRetrieveObject("SwiftPerson", "Sam")
        let nsError = error as NSError
        
        #expect(nsError.localizedDescription.contains("SwiftPerson"))
        #expect(nsError.localizedDescription.contains("Sam"))
    }
    
    // MARK: - storageDataIsNil Tests
    
    @Test("storageDataIsNil error has correct userInfo")
    func storageDataIsNilUserInfo() {
        let error = GarageError.storageDataIsNil("SwiftPerson")
        
        let userInfo = error.errorUserInfo
        let description = userInfo[NSLocalizedDescriptionKey] as? String
        
        #expect(description != nil)
        #expect(description?.contains("SwiftPerson") == true)
        #expect(description?.contains("gsData is nil") == true)
        #expect(description == "CoreDataObject.gsData is nil for type: SwiftPerson")
    }
    
    @Test("storageDataIsNil NSError has localized description")
    func storageDataIsNilNSError() {
        let error = GarageError.storageDataIsNil("SwiftPerson")
        let nsError = error as NSError
        
        #expect(nsError.localizedDescription.contains("SwiftPerson"))
        #expect(nsError.localizedDescription.contains("gsData is nil"))
    }
    
    // MARK: - Real-world Error Scenario Tests
    
    @Test("storageDataIsNil from retrieve")
    func failedToRetrieveFromDelete() {
        let garage = makeTestGarage()
        let sam = swiftPerson()
        
        do {
            try garage.delete(sam)
            Issue.record("delete should have thrown GarageError.failedToRetrieveObject")
        } catch GarageError.failedToRetrieveObject {
            // YAY
        } catch {
            Issue.record("delete should have thrown GarageError.failedToRetrieveObject")
        }
    }
    
    /// Test what happens if a core data object is created, but its `gs_data` never got set.
    /// It is possible for this to happen at runtime if there is a memory corruption around the time the object is being parked.
    @Test("Retrieve fails when gs_data is not set")
    func storageDataIsNilFromRetrieve() async throws {
        let garage = makeTestGarage()

        do {
            _ = garage.makeCoreDataObject("TestCoreData", identifier: "TestIdentifier")
            garage.save()
        }
        
        do {
            let _: TestCoreData? = try garage.retrieve(TestCoreData.self, identifier: "TestIdentifier")
            // If we reach here without throwing, the test should fail
            Issue.record("Expected retrieve to throw GarageError.storageDataIsNil")
        } catch GarageError.storageDataIsNil {
            // Expected
        } catch {
            // we want to catch the error, and verify it
            Issue.record("Expected retrieve to throw GarageError.storageDataIsNil, but it threw \(error)")
        }
    }
    
    // MARK: - missingIdentifiableReference Tests
    
    @Test("Missing required Identifiable reference throws DecodingError.dataCorrupted")
    func missingRequiredIdentifiableReference() throws {
        let garage = makeTestGarage()
        
        // Create a person with a parent reference
        let child = swiftPersonWithParent()
        try garage.park(child)
        
        // Verify the parent was parked
        let parent = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Nick"))
        
        // Delete the parent to create a missing reference
        try garage.delete(parent)
        
        // Attempting to retrieve child should throw because parent reference is missing
        do {
            _ = try garage.retrieve(SwiftPersonWithParent.self, identifier: "Child")
            Issue.record("Expected retrieve to throw DecodingError.dataCorrupted")
        } catch DecodingError.dataCorrupted(let context) {
            // Expected error - verify it mentions missing reference
            #expect(context.debugDescription.contains("Missing Identifiable reference"))
            #expect(context.debugDescription.contains("SwiftPerson"))
            #expect(context.debugDescription.contains("Nick"))
        } catch {
            Issue.record("Expected DecodingError.dataCorrupted, got: \(error)")
        }
    }
    
    @Test("Missing Identifiable reference in array throws DecodingError.dataCorrupted")
    func missingIdentifiableReferenceInArray() throws {
        let garage = makeTestGarage()
        
        // Create a person with siblings (array of references)
        let sam = swiftPerson()
        try garage.park(sam)
        
        // Verify siblings were parked
        #expect(sam.siblings.count == 2)
        let nick = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Nick"))
        
        // Delete one sibling to create a missing reference in the array
        try garage.delete(nick)
        
        // Attempting to retrieve Sam should throw because a sibling reference is missing
        do {
            _ = try garage.retrieve(SwiftPerson.self, identifier: "Sam")
            Issue.record("Expected retrieve to throw DecodingError.dataCorrupted")
        } catch DecodingError.dataCorrupted(let context) {
            // Expected error - verify it mentions missing reference
            #expect(context.debugDescription.contains("Missing Identifiable reference"))
            #expect(context.debugDescription.contains("Nick"))
        } catch {
            Issue.record("Expected DecodingError.dataCorrupted, got: \(error)")
        }
    }
}
