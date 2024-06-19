//
//  SyncableObject.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/11/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation


/// Optional protocol for managing the sync status of an Objective-C ``MappableObject``.
@objc(GSSyncableObject)
public protocol SyncableObject: NSObjectProtocol {
    
    @objc var syncStatus: SyncStatus { get set }
}
