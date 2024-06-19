//
//  Syncable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/11/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

/// Possible sync status states with respect to, say, a web service.
@objc(GSSyncStatus)
public enum SyncStatus: Int {
    /// The object's sync status has not yet been set, or is otherwise not yet determined.
    case undetermined
    
    /// The object has not been synced with the web service.
    case notSynced
    
    /// The object is in the process of syncing with the web service.
    case syncing
    
    /// The object has been successfully synced with the web service.
    case synced
}
