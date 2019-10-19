//
//  SwiftMocks.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/17/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import XCTest


extension XCTestCase {
    
    func objCAddress() -> ObjCAddress {
        let address = ObjCAddress()
        address.street = "330 Congress St."
        address.city = "Boston"
        address.zip = "02140"
        return address
    }
    
    func objCAddress2() -> ObjCAddress {
        let address = ObjCAddress()
        address.street = "321 Summer Street"
        address.city = "Boston"
        address.zip = "02140"
        return address
    }
    
    func objCPerson() -> ObjCPerson {
        let person = ObjCPerson()
        person.name = "Sam"
        person.age = 31
        person.birthdate = Date()
        person.address = objCAddress()
        person.importantDates = [Date(), Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 100)]
        person.brother = objCPerson2()
        person.siblings = [person.brother!, objCPerson3()]
        person.syncStatus = .syncing
        
        return person
    }
    
    func objCPerson2() -> ObjCPerson {
        let person = ObjCPerson()
        person.name = "Nick"
        person.address = objCAddress()
        person.age = 26
        return person
    }
    
    func objCPerson3() -> ObjCPerson {
        let person = ObjCPerson()
        person.name = "Emily"
        person.address = objCAddress()
        person.age = 24
        return person
    }
}
