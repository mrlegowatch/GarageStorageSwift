//
//  RawStorageTests.swift
//  
//
//  Created by Brian Arnold on 6/7/24.
//

import XCTest
@testable import GarageStorage

class TestCoreData: Codable { }

final class RawStorageTests: XCTestCase {

    override func setUpWithError() throws {
        let garage = Garage(named: testStoreName)
        garage.deleteAllObjects()
    }

    /// Test what happens if a core data object is created, but its `gs_data` never got set.
    func testRawStorage() throws {
        let garage = Garage(named: testStoreName)
              
        do {
            _ = garage.makeCoreDataObject("TestCoreData", identifier: "TestIdentifier")
            garage.save()
        }
        
        do {
            let _: TestCoreData? = try garage.retrieve(TestCoreData.self, identifier: "TestIdentifier")
        } catch {
            // we want to catch the error, and verify it
            XCTAssertTrue(error.localizedDescription.contains("failed to retrieve gs_data"))
        }
        
    }

}
