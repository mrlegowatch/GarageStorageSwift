//
//  Address.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/12/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

@objc class ObjCAddress : NSObject, MappableObject {

    // This example sets all properties to default values, so that an init() method is not required.
    // The @objc is required for Key-Value Coding to work.
    @objc var street: String = ""
    @objc var city: String = ""
    @objc var zip: String = ""

    // MappableObject protocol
    static var objectMapping: ObjectMapping {
        let mapping = ObjectMapping(for: self)
        mapping.addMappings(["street", "city", "zip"])
        return mapping
    }
    
}
