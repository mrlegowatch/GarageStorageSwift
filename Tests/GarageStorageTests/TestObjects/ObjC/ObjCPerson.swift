//
//  Person.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/12/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

@objc class ObjCPerson: NSObject, MappableObject, SyncableObject {
    
    // This example sets all properties to default values, so that an init() method is not required.
    // The @objc is required for Key-Value Coding to work.
    @objc var name: String = ""
    @objc var address: ObjCAddress?
    @objc var age: Int = 0
    @objc var birthdate: Date = Date()
    @objc var importantDates: [Date] = []
    @objc var siblings: [ObjCPerson] = []
    @objc var brother: ObjCPerson?
    
    // SyncableObject protocol
    var syncStatus: SyncStatus = .undetermined

    // MappableObject protocol
    static var objectMapping: ObjectMapping {
        let mapping = ObjectMapping(for: self)
        mapping.addMappings(["name", "address", "age", "birthdate", "importantDates", "siblings", "brother"])
        mapping.identifyingAttribute = "name"
        return mapping
    }

}
