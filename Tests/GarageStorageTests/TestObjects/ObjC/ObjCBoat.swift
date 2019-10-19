//
//  Boat.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/12/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

// This example has an incorrectly specified identifying attribute (not in mappings).
@objc class ObjCBoat : NSObject, MappableObject {
    
    // This example sets all properties to default values, so that an init() method is not required.
    // The @objc is required for Key-Value Coding to work.
    @objc var name: String = ""
    
    // MappableObject protocol
    static var objectMapping: ObjectMapping {
        let mapping = ObjectMapping(for: self)
        mapping.addMappings(["name"])
        mapping.identifyingAttribute = "whoops"
        return mapping
    }
    
}
