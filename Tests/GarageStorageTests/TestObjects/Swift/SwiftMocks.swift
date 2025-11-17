//
//  TestMocks.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/30/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation

func swiftAddress() -> SwiftAddress {
    SwiftAddress(street: "330 Congress St.", city: "Boston", zip: "02140")
}

func swiftAddress2() -> SwiftAddress {
    SwiftAddress(street: "321 Summer Street", city: "Boston", zip: "02140")
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
    person.syncStatus = .syncing

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

func swiftPet() -> SwiftPet {
    let pet = SwiftPet()
    pet.name = "Peaches"
    pet.age = 3
    return pet
}

func swiftPet2() -> SwiftPet {
    let pet = SwiftPet()
    pet.name = "Cream"
    pet.age = 5
    return pet
}

func swiftSquirrels() -> [SwiftSquirrel] {
    let squirrel1 = SwiftSquirrel(name: "Nutty")
    let squirrel2 = SwiftSquirrel(name: "Benny")
    return [squirrel1, squirrel2]
}

func swiftPersonWithParent() -> SwiftPersonWithParent {
    let person = SwiftPersonWithParent()
    person.name = "Child"
    person.parent = swiftPerson2()
    return person
}
