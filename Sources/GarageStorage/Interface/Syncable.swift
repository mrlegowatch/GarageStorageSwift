//
//  Syncable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/11/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation


/// An optional protocol for managing the web server sync status of a stored type.
///
/// This can be used to retrieve all objects of a specific type and sync status, eliminating the need to fetch all instances of a specific type then filtering on sync status.
public protocol Syncable {
    
    var syncStatus: SyncStatus { get set }
}
