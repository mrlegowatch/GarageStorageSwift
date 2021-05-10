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
        let garage = Garage()
        garage.deleteAllObjects()
    }

    func testOneMappable() {
        let garage = Garage()
        
        do {
            let nick = objCPerson2()
            XCTAssertNoThrow(try garage.parkObject(nick), "parkObject")
        }
        
        XCTAssertNoThrow(try garage.migrateAll(from: ObjCPerson.self, to: SwiftPerson.self))

        do {
            let nick = try? garage.retrieve(SwiftPerson.self, identifier: "Nick")
            XCTAssertNotNil(nick, "Failed to retrieve 'Nick' from garage store")
            XCTAssertEqual(nick?.address, swiftAddress(), "Address should survive round-trip")
        }
    }
    
    func testNestedMappable() {
        let garage = Garage()
        
        // Save Sam as a MappableObject (Objective-C-based) person
        do {
            let sam = objCPerson()
            XCTAssertNoThrow(try garage.parkObject(sam), "parkObject")
        }
        
        // Do the migration
        XCTAssertNoThrow(try garage.migrateAll(from: ObjCPerson.self, to: SwiftPerson.self))

        // Retrieve the "Sam" person as a Swift-y object
        do {
            let sam = try? garage.retrieve(SwiftPerson.self, identifier: "Sam")
            XCTAssertNotNil(sam, "Failed to retrieve 'Sam' from garage store")
            XCTAssertEqual(sam?.name ?? "", "Sam", "expected Sam to be Sam")
            XCTAssertEqual(sam?.importantDates.count ?? 0, 3, "expected 3 important dates")
            XCTAssertEqual(sam?.address, swiftAddress(), "Expected address round-trip")
            
            // Make sure brother and siblings worked out.
            let brother = sam?.brother
            XCTAssertNotNil(brother, "O brother, my brother")
            XCTAssertEqual(brother?.name ?? "", "Nick", "expected brother to be Nick")
            XCTAssertEqual(sam?.siblings.count, 2, "expected 2 siblings")
        }
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
