//
//  GSCoreDataObject.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/11/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation
import CoreData

@objc(GSCoreDataObject)
internal class CoreDataObject: NSManagedObject {
    
    // Stringified entity name
    static let entityName = "GSCoreDataObject"
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataObject> {
        return NSFetchRequest<CoreDataObject>(entityName: entityName)
    }
    
    @NSManaged public var gs_type: String?
    @NSManaged public var gs_identifier: String?
    @NSManaged public var gs_version: NSNumber?
    @NSManaged public var gs_data: String?
    @NSManaged public var gs_creationDate: Date?
    @NSManaged public var gs_modifiedDate: Date?
    @NSManaged public var gs_syncStatus: NSNumber?
    
    // Wrapper enum property for the underlying NSNumber property
    var syncStatus: SyncStatus {
        get {
            guard let gsStatus = gs_syncStatus, let status = SyncStatus(rawValue: gsStatus.intValue) else { return .undetermined }
            return status
        }
        set {
            gs_syncStatus = NSNumber(value: newValue.rawValue)
        }
    }
    
    // Wrapper for the underlying gs_data property, updates the modified date when set.
    var data: String {
        get {
            return gs_data!
        }
        set {
            gs_data = newValue
            gs_modifiedDate = Date()
        }
    }
    
    // Stringified property key names for fetching and dictionaries
    struct Attribute {
        static let type = "gs_type"
        static let identifier = "gs_identifier"
        static let version = "gs_version"
        static let data = "gs_data"
        static let creationDate = "gs_creationDate"
        static let modifiedDate = "gs_modifiedDate"
        static let syncStatus = "gs_syncStatus"
    }
    
    // Predicate for fetching objects of a specified type, and optionally, an identifier.
    static func predicate(for type: String, identifier: String?) -> NSPredicate {
        var predicateString = "\(Attribute.type) = \"\(type)\""
        
        if let identifier = identifier {
            predicateString.append(" && \(Attribute.identifier) = \"\(identifier)\"")
        }
        
        return NSPredicate(format: predicateString)
    }
    
    // Predicate for fetching objects of a specific sync status, and optionally, a specified type.
    static func predicate(for syncStatus: SyncStatus, type: String?) -> NSPredicate {
        var predicateString = "\(Attribute.syncStatus) = \(syncStatus.rawValue)"
        
        if let type = type {
            predicateString.append(" && \(Attribute.type) = \"\(type)\"")
        }
        
        return NSPredicate(format: predicateString)
    }
    
}
