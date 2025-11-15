//
//  RawStorageTests.swift
//  
//
//  Created by Brian Arnold on 6/7/24.
//

import Testing
@testable import GarageStorage

class TestCoreData: Codable { }

@Suite("Raw Storage Tests")
struct RawStorageTests {

    /// Test what happens if a core data object is created, but its `gs_data` never got set.
    @Test("Retrieve fails when gs_data is not set")
    func rawStorage() async throws {
        let garage = makeTestGarage()

        do {
            _ = garage.makeCoreDataObject("TestCoreData", identifier: "TestIdentifier")
            garage.save()
        }
        
        do {
            let _: TestCoreData? = try garage.retrieve(TestCoreData.self, identifier: "TestIdentifier")
            // If we reach here without throwing, the test should fail
            Issue.record("Expected retrieve to throw an error")
        } catch {
            // we want to catch the error, and verify it
            #expect(error.localizedDescription.contains("failed to retrieve gs_data"))
        }
    }
}
