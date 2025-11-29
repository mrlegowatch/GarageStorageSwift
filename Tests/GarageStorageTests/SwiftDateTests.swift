//
//  SwiftDateTests.swift
//  GarageStorage
//
//  Created by Brian Arnold on 11/15/25.
//

import Testing
import GarageStorage
import Foundation


struct SwiftDateTests {

    init() {
        TestSetup.classSetUp()
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
    
    @Test("Date encoding and decoding strategies can be temporarily changed")
    func temporaryDateStrategies() throws {
        let garage = makeTestGarage()
        
        // Create a person with a specific birthdate and time
        let nick = swiftPerson2()
        let timeZone = TestSetup.timeZone
        var dateComponents = DateComponents()
        dateComponents.day = 15
        dateComponents.month = 6
        dateComponents.year = 1985
        dateComponents.hour = 12
        dateComponents.minute = 30
        dateComponents.timeZone = timeZone
        
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let nickBirthdate = calendar.date(from: dateComponents)!
        nick.birthdate = nickBirthdate
        
        // Create a simple date formatter for testing that doesn't include time
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        simpleDateFormatter.timeZone = timeZone
        
        // Test both strategies together: Park with formatted strategy
        try garage.withDateEncodingStrategy(.formatted(simpleDateFormatter)) {
            try garage.park(nick)
        }
        
        // Retrieve with a matching decoding strategy
        let retrievedNick = try garage.withDateDecodingStrategy(.formatted(simpleDateFormatter)) {
            try garage.retrieve(SwiftPerson.self, identifier: "Nick")
        }
        let unwrappedNick = try #require(retrievedNick)
        
        // initial Date includes time, unwrapped Date no longer includes time, so they should be different.
        #expect(nick.birthdate != unwrappedNick.birthdate, "Dates should not match, unwrappedNick should have no time")
        
        // Note: Time components will be lost with the simple formatter
        let nickDateOnly = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: nickBirthdate))!
        let retrievedDateOnly = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: unwrappedNick.birthdate))!
        #expect(nickDateOnly == retrievedDateOnly, "Date (without time) should match")
        
        // Negative test: if encoded using non-default format, but decoded without the non-default format, ensure that decoding might fail.
        do {
            _ = try garage.retrieve(SwiftPerson.self, identifier: "Nick")
            // If we reach here without throwing, the test should fail
            Issue.record("Expected retrieve to throw DecodingError.dataCorrupted")
        } catch DecodingError.dataCorrupted {
            // Expected
        } catch {
            Issue.record("Expected retrieve to throw DecodingError.dataCorrupted")
        }
        
        // Ensure that deletion doesn't rely on either encoding or decoding.
        try garage.delete(nick)
    }

}
