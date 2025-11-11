//
//  SwiftMigrationTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 10/14/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import XCTest
import GarageStorage

class SwiftMigrationTests: XCTestCase {

    override class func setUp() {
        TestSetup.classSetUp()
    }
    
    override func setUp() {
        // Reset the underlying storage before running each test.
        let garage = Garage(named: testStoreName)
        garage.deleteAllObjects()
    }

    // This test seeks to ensure that a MappableObject can also be encoded to pure JSON (no references, only values).
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
        catch {
            XCTFail("Should not fail to decode")
            return
        }
    }
}
