//
//  SwiftMigrationTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 10/14/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Testing
import GarageStorage
import Foundation

@Suite("Swift Migration Tests")
struct SwiftMigrationTests {

    init() {
        TestSetup.classSetUp()
    }

    @Test("Migrating a single mappable object")
    func oneMappable() throws {
        let garage = makeTestGarage()
        
        let nick = objCPerson2()
        try garage.parkObject(nick)
        
        try garage.migrateAll(from: ObjCPerson.self, to: SwiftPerson.self)

        let migratedNick = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Nick"))
        #expect(migratedNick.address == swiftAddress(), "Address should survive round-trip")
    }
    
    @Test("Migrating nested mappable objects with relationships")
    func nestedMappable() throws {
        let garage = makeTestGarage()
        
        // Save Sam as a MappableObject (Objective-C-based) person
        let sam = objCPerson()
        try garage.parkObject(sam)
        
        // Do the migration
        try garage.migrateAll(from: ObjCPerson.self, to: SwiftPerson.self)

        // Retrieve the "Sam" person as a Swift-y object
        let migratedSam = try #require(try garage.retrieve(SwiftPerson.self, identifier: "Sam"))
        #expect(migratedSam.name == "Sam", "expected Sam to be Sam")
        #expect(migratedSam.importantDates.count == 3, "expected 3 important dates")
        #expect(migratedSam.address == swiftAddress(), "Expected address round-trip")
        
        // Make sure brother and siblings worked out.
        let brother = try #require(migratedSam.brother)
        #expect(brother.name == "Nick", "expected brother to be Nick")
        #expect(migratedSam.siblings.count == 2, "expected 2 siblings")
    }
}
