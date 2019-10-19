//
//  Syncable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/11/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation

/// Possible sync status states with respect to, say, a web service.
@objc(GSSyncStatus)
public enum SyncStatus: Int {
    case undetermined
    case notSynced
    case syncing
    case synced
}
