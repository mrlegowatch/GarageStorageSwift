//
//  Syncable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/11/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation


/// Optional protocol for managing the sync status of a Swift type.
public protocol Syncable {
    
    var syncStatus: SyncStatus { get set }
}
