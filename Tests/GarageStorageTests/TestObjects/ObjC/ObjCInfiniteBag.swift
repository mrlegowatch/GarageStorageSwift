//
//  ObjCInfiniteBag.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/17/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

class InfiniteBag : NSObject, MappableObject, SyncableObject {
    
    var syncStatus: SyncStatus = .undetermined
    
    // The @objc is required for Key-Value Coding to work.
    @objc var name: String
    @objc var contents = [InfiniteBag]()
    @objc var dates = [[Date(), Date()],[Date()]]
    
    override init() {
        self.name = ""
        super.init()
    }
    
    init(_ name: String) {
        self.name = name
        super.init()
    }
    
    // MappableObject protocol
    static var objectMapping: ObjectMapping {
        let mapping = ObjectMapping(for: self)
        mapping.addMappings(["name", "contents", "dates"])
        mapping.identifyingAttribute = "name"
        return mapping
    }
    
}
