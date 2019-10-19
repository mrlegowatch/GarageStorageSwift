//
//  ObjCSyncingAddress.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/17/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

// For edge-case testing
class ObjCSyncingAddress : ObjCAddress, SyncableObject {
    
    var syncStatus: SyncStatus = .undetermined
    
}
