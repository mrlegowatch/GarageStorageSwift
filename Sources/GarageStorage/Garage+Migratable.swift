//
//  Garage+Migratable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/14/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

// This file contains support for migrating MappableObject properties to Codable properties in-place.

// Wrapper for migrating MappableObject "transformable date" dictionary to a Codable date.
private struct __TransformableDateObjC: Decodable {
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        // Ignore type and transformable type, they're not necessary to determine transformable date type.
        case date = "gs_transformableData"
    }
}

// Function to pass into DateDecodingStrategy.custom(_) to enable parsing transformable Date.
internal func decodeTransformableDate(_ decoder: Decoder) throws -> Date {
    let date: Date
    
    let container = try decoder.singleValueContainer()
    
    // Swift Codable encodes the date as a string directly
    // Objective-C MappableObject encodes a dictionary of transformable type
    if let string = try? container.decode(String.self) {
        date = Date.isoDate(for: string)!
    } else if let transformableDate = try? container.decode(__TransformableDateObjC.self) {
        date = transformableDate.date
    } else {
        let description = "Failed to decode into Date"
        let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: description)
        throw DecodingError.dataCorrupted(context)
    }
    
    return date
}

// Wrapper for migrating a referenced MappableObject with "identifiableAttribute" to a reference id.
internal struct __ReferenceObjC: Decodable {
    let id: String
    
    enum CodingKeys: String, CodingKey {
        // Ignore type, it's not necessary to determine a reference.
        case id = "gs_identifier"
    }
}

// Wrapper for migrating a nested "anonymous" MappableObject to extract its data.
private struct __AnonymousObjC: Decodable {
    let data: String
    let syncStatus: Int?
    
    enum CodingKeys: String, CodingKey {
        // Ignore type and identifier, they're not necessary to determine anonymous data.
        case data = "kGSAnonymousDataKey"
        case syncStatus = "gs_syncStatus"
    }
}

/// An optional property wrapper for migrating a previously nested ``MappableObject`` with no ``ObjectMapping/identifyingAttribute`` to Swift `Codable` in-place.
///
/// Use directly on a containing class's property, for an object that was previously of type ``MappableObject``.
@propertyWrapper
public struct Migratable<Value: Decodable>: Decodable {
    public var wrappedValue: Value?
    
    public init() { }
    
    public init(from decoder: Decoder) throws {
        if let decoded = try? Value(from: decoder) {
            wrappedValue = decoded
        } else if let anonymousObject = try? __AnonymousObjC(from: decoder) {
            guard let garage = decoder.garage else {
                let description = "Failed to decode migratable object"
                let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: description)
                throw DecodingError.dataCorrupted(context)
            }
            var anonymous: Value = try garage.decodeData(anonymousObject.data)
            
            if var syncable = anonymous as? Syncable, let syncStatus = anonymousObject.syncStatus {
                syncable.syncStatus = SyncStatus(rawValue: syncStatus)!
                anonymous = syncable as! Value
            }
            wrappedValue = anonymous
        } else {
            let description = "Failed to decode migratable object"
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: description)
            throw DecodingError.dataCorrupted(context)
        }
    }
}

extension Migratable: Encodable where Value: Encodable {

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension Garage {

    /// Migrates all instances of a class conforming to ``MappableObject`` to another type conforming to `Codable`, on the assumption that the new type can decode the old class's data.
    ///
    /// - parameter oldClass: The old class.
    /// - parameter newType: The new object type.
    public func migrateAll<T: Codable>(from oldClass: AnyClass, to newType: T.Type) throws {
        let oldClassName = NSStringFromClass(oldClass)
        try migrateAll(fromOldClassName: oldClassName, to: newType)
    }
    
    /// Migrates all instances of a class name (formerly conforming to ``MappableObject``) to another type conforming to `Codable`, on the assumption that the new type can decode the old class's data.
    ///
    /// - parameter oldClassName: The old class name.
    /// - parameter newType: The new object type.
    public func migrateAll<T: Codable>(fromOldClassName oldClassName: String, to newType: T.Type) throws {
        try context.performAndWait {
            let coreDataObjects = fetchObjects(for: oldClassName, identifier: nil)
            guard coreDataObjects.count > 0 else { return }
            
            // First, change the types all at once, for decodeData's recursive calls to retrieve() to work.
            let newClassName = String(describing: T.self)
            for coreDataObject in coreDataObjects {
                coreDataObject.gs_type = newClassName
            }
            
            // Then, decode the old data directly, and re-encode it in the more Swift-friendly Codable format.
            for coreDataObject in coreDataObjects {
                let codable: T = try decodeData(coreDataObject.data)
                coreDataObject.data = try encodeData(codable)
            }
        }
        
        autosave()
    }
}
