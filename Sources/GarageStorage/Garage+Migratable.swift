//
//  Garage+Migratable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/14/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation

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
        throw decoder.makeDecodingError("Failed to decode into Date")
    }
    
    return date
}

// Wrapper for migrating a referenced MappableObject with "identifiableAttribute" to a reference id.
private struct __ReferenceObjC: Decodable {
    let id: String
    
    enum CodingKeys: String, CodingKey {
        // Ignore type, it's not necessary to determine a reference.
        case id = "gs_identifier"
    }
}

// Extension that enables automatic decoding of Mappable references with identifyingAttributes
public extension KeyedDecodingContainer {

    func decodeReferenceIfPresent(forKey key: KeyedDecodingContainer<K>.Key) throws -> String? {
        let reference: String?
        
        // Swift Codable encodes the identifier directly
        // Objective-C MappableObject encodes a dictionary of identifier and non-anonymous type
        if let identifier = try? decodeIfPresent(String.self, forKey: key) {
            reference = identifier
        } else if let referenceObject = try? decodeIfPresent(__ReferenceObjC.self, forKey: key) {
            reference = referenceObject.id
        } else {
            reference = nil
        }
        
        return reference
    }

    func decodeReference(forKey key: KeyedDecodingContainer<K>.Key) throws -> String {
        guard let reference = try decodeReferenceIfPresent(forKey: key) else {
            throw try superDecoder().makeDecodingError("Failed to decode Mappable reference")
        }
        
        return reference
    }
    
    func decodeReferencesIfPresent(forKey key: KeyedDecodingContainer<K>.Key) throws -> [String] {
        let references: [String]
        
        // Swift Codable encodes the array of identifiers directly
        // Objective-C MappableObjects encode an array of dictionaries of identifier and type
        if let identifiers = try? decodeIfPresent([String].self, forKey: key) {
            references = identifiers
        } else if let dictionaries = try? decodeIfPresent([[String:String]].self, forKey: key) {
            references = dictionaries.map { $0[CoreDataObject.Attribute.identifier]! }
        } else {
            references = []
        }
        
        return references
    }
}

// Wrapper for migrating an embedded "anonymous" MappableObject to extract its data.
private struct __AnonymousObjC: Decodable {
    let data: String
    let syncStatus: Int?
    
    enum CodingKeys: String, CodingKey {
        // Ignore type and identifier, they're not necessary to determine anonymous data.
        case data = "kGSAnonymousDataKey"
        case syncStatus = "gs_syncStatus"
    }
}

/// Optional property wrapper for migrating previously nested MappableObjects with no identifyingAttribute to Swift Codable.
///
/// Use directly on a containing class's property, for an object that was previously of type MappableObject.
@propertyWrapper
public struct Migratable<Value: Decodable>: Decodable {
    public var wrappedValue: Value?
    
    public init() { }
    
    public init(from decoder: Decoder) throws {
        if let decoded = try? Value(from: decoder) {
            wrappedValue = decoded
        } else if let anonymousObject = try? __AnonymousObjC(from: decoder) {
            guard let garage = decoder.garage else {
                throw decoder.makeDecodingError("Failed to decode migratable object")
            }
            var anonymous: Value = try garage.decodeData(anonymousObject.data)
            
            if var syncable = anonymous as? Syncable, let syncStatus = anonymousObject.syncStatus {
                syncable.syncStatus = SyncStatus(rawValue: syncStatus)!
                anonymous = syncable as! Value
            }
            wrappedValue = anonymous
        } else {
            throw decoder.makeDecodingError("Failed to decode migratable object")
        }
    }
}

extension Migratable: Encodable where Value: Encodable {

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension Garage {

    /// Migrates all instances of one type to another type, on the assumption that the new type can decode the old type's data.
    ///
    /// - parameter oldClass: The old class.
    /// - parameter newClass: The new object class.
    public func migrateAll<T: Codable>(from oldClass: AnyClass, to newClass: T.Type) throws {
        let oldClassName = NSStringFromClass(oldClass)
        try migrateAll(fromOldClassName: oldClassName, to: newClass)
    }
    
    /// Migrates all instances of one type to another type, on the assumption that the new type can decode the old type's data.
    ///
    /// - parameter oldClass: The old class name.
    /// - parameter newClass: The new object class.
    public func migrateAll<T: Codable>(fromOldClassName oldClassName: String, to newClass: T.Type) throws {
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
                
        autosave()
    }
}
