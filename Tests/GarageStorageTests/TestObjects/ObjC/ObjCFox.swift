//
//  Fox.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/26/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

class ObjCFox : NSObject, MappableObject {
    
    // This example has a nil identifying attribute.
    // The @objc is required for Key-Value Coding to work.
    @objc var name: String? = nil
    
    // MappableObject protocol
    static var objectMapping: ObjectMapping {
        let mapping = ObjectMapping(for: self)
        mapping.addMappings(["name"])
        mapping.identifyingAttribute = "name"
        return mapping
    }
    
}
