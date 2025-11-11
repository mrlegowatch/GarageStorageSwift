//
//  XCTest+Swift.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/30/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    
    func swiftAddress() -> SwiftAddress {
        let address = SwiftAddress(street: "330 Congress St.", city: "Boston", zip: "02140")
        return address
    }
    
    func swiftAddress2() -> SwiftAddress {
        let address = SwiftAddress(street: "321 Summer Street", city: "Boston", zip: "02140")
        return address
    }
    
    func swiftPerson() -> SwiftPerson {
        let person = SwiftPerson()
        person.name = "Sam"
        person.age = 31
        person.birthdate = Date()
        person.address = swiftAddress()
        person.importantDates = [Date(), Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 100)]
        person.brother = swiftPerson2()
        person.siblings = [person.brother!, swiftPerson3()]
        
        return person
    }
    
    func swiftPerson2() -> SwiftPerson {
        let person = SwiftPerson()
        person.name = "Nick"
        person.address = swiftAddress()
        person.age = 26
        return person
    }
    
    func swiftPerson3() -> SwiftPerson {
        let person = SwiftPerson()
        person.name = "Emily"
        person.address = swiftAddress()
        person.age = 24
        return person
    }
}
