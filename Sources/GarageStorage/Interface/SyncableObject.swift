//
//  SyncableObject.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/11/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation


/// An optional protocol for managing the web server sync status of an Objective-C ``MappableObject``.
///
/// This can be used to retrieve all objects of a specific class and sync status, eliminating the need to fetch all instances of a specific class then filtering on sync status.
@objc(GSSyncableObject)
public protocol SyncableObject: NSObjectProtocol {
    
    @objc var syncStatus: SyncStatus { get set }
}
