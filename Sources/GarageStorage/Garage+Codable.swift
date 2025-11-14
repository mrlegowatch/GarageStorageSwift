//
//  Garage+Codable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/3/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

// MARK: - Codable Hooks for Identifiable references

// The Swift runtime needs a nudge for whether an about-to-be-saved
// reference is an explicitly-parked object (an `Identifiable` with an `id`
// conforming to `LosslessStringConvertible`), so the Garage is stored and
// accessed via the encoder or decoder to ensure that they are parked
// appropriately. Without this, the references would fail to be retrieved.
// See Garage+CodableReference for the full implementation.

private extension CodingUserInfoKey {
    static let garage = CodingUserInfoKey(rawValue: "Garage")!
}

extension Encoder {
    
    /// The underlying Garage used by this Encoder, if specified.
    var garage: Garage? { self.userInfo[.garage] as? Garage }
}

extension Decoder {
    
    /// The underlying Garage used by this Decoder, if specified.
    var garage: Garage? { self.userInfo[.garage] as? Garage }
}

// MARK: - Garage Codable extensions

extension Garage {
    
    // MARK: Core Data
    
    /// Decodes string data to the specified object type, decrypting the data if a ``dataEncodingDelegate`` is specified.
    /// Uses the date decoding strategy for any dates, and resolves any `Identifiable` references.
    /// Must be called from within context.performAndWait.
    internal func decodeData<T: Decodable>(_ string: String) throws -> T {
        let data: Data = try decrypt(string)
        
        let decoder = JSONDecoder()
        decoder.userInfo[.garage] = self
        decoder.dateDecodingStrategy = .formatted(Date.isoFormatter)
        
        return try decoder.decode(T.self, from: data)
    }
    
    /// Encodes the specified object, encrypting its data if ``dataEncodingDelegate`` is specified.
    /// Uses the date encoding strategy for any dates, and encodes any `Identifiable` references.
    internal func encodeData<T: Encodable>(_ object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[.garage] = self
        encoder.dateEncodingStrategy = .formatted(Date.isoFormatter)
        let data = try encoder.encode(object)
        
        return try encrypt(data)
    }
    
    // MARK: Parking
    
    /// Fetches or creates the underlying core data object, and sets the core data object's data to the encoded object 'sdata.
    /// Must be called from within context.performAndWait.
    internal func parkEncodable<T: Encodable>(from object: T, identifier: String) throws {
        let typeName = String(describing: type(of: object))
        let coreDataObject = retrieveCoreDataObject(for: typeName, identifier: identifier)
        coreDataObject.data = try encodeData(object)
    }
    
    /// Adds an object that conforms to `Codable` and `Identifiable` to the Garage.
    ///
    /// - parameter object: An object of type `T` that conforms to `Codable` and `Identifiable`, where the `ID` is `LosslessStringConvertible`.
    public func park<T: Encodable & Identifiable>(_ object: T) throws where T.ID: LosslessStringConvertible {
        try context.performAndWait {
            try parkEncodable(from: object, identifier: String(object.id))
        }
        
        autosave()
    }
    
    /// Adds an object that conforms to `Codable` and `Hashable` to the Garage.
    ///
    /// - parameter object: An object of type `T` that conforms to `Codable` and `Hashable`.
    public func park<T: Encodable & Hashable>(_ object: T) throws {
        try context.performAndWait {
            try parkEncodable(from: object, identifier: "\(object.hashValue)")
        }
        
        autosave()
    }
    
    /// Adds an array of Encodable and Identifiable objects to the Garage.
    /// Must be called from within context.performAndWait.
    internal func parkAllEncodables<T: Encodable & Identifiable>(_ identifiables: [T]) throws where T.ID: LosslessStringConvertible {
        for identifiable in identifiables {
            try parkEncodable(from: identifiable, identifier: String(identifiable.id))
        }
    }
    
    /// Adds an array of objects that conform to `Codable` and `Identifiable` to the Garage.
    ///
    /// - parameter objects: An array of objects of the same type `T`, where the `ID` is `LosslessStringConvertible`.
    public func parkAll<T: Encodable & Identifiable>(_ objects: [T]) throws where T.ID: LosslessStringConvertible {
        try context.performAndWait {
            try parkAllEncodables(objects)
        }
        
        autosave()
    }
    
    /// Adds an array of objects that conform to `Codable` and `Hashable` to the Garage.
    ///
    /// - parameter objects: An array of objects of the same type `T`.
    public func parkAll<T: Encodable & Hashable>(_ objects: [T]) throws {
        try context.performAndWait {
            for object in objects {
                try parkEncodable(from: object, identifier: "\(object.hashValue)")
            }
        }
        
        autosave()
    }
    
    // MARK: Retrieving
    
    /// Returns a decoded instance from the specified Core Data object. Throws an error if unable to decode.
    /// Must be called from within context.performAndWait.
    private func makeCodable<T: Decodable>(from coreDataObject: CoreDataObject) throws -> T {
        guard let data = coreDataObject.gs_data else {
            throw Garage.makeError("failed to retrieve gs_data from store of type \(T.self)")
        }
        return try decodeData(data)
    }
    
    /// Returns an instance of the specified type string and identifier string.
    /// Must be called from within context.performAndWait.
    private func retrieveDecodable<T: Decodable>(typeName: String, identifier identifierString: String) throws -> T? {
        guard let coreDataObject = fetchObject(for: typeName, identifier: identifierString) else { return nil }
        return try makeCodable(from: coreDataObject)
    }
    
    /// Returns an instance of the specified object type and identifier.
    /// Must be called from within context.performAndWait.
    internal func retrieveDecodable<T: Decodable>(_ objectType: T.Type, identifier: LosslessStringConvertible) throws -> T? {
        let identifier = String(identifier)
        let typeName = String(describing: T.self)
        return try retrieveDecodable(typeName: typeName, identifier: identifier)
    }
    
    /// Retrieves an object of the specified type conforming to `Decodable` with the specified identifier from the Garage.
    ///
    /// - parameter objectType: The type of the object to retrieve. This type must conform to `Codable`.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier previously specified by either that object's `Identifiable` `id` or `Hashable` `hashValue`.
    ///
    /// - returns: An object conforming to the specified type, or nil if it was not found.
    public func retrieve<T: Decodable>(_ objectType: T.Type, identifier: LosslessStringConvertible) throws -> T? {
        let typeName = String(describing: T.self)
        let identifierString = String(identifier)
        return try context.performAndWait {
            return try retrieveDecodable(typeName: typeName, identifier: identifierString)
        }
    }
    
    /// Returns an array of `Decodable` objects corresponding to the specified Core Data objects.
    /// Must be called from within context.performAndWait.
    private func makeCodableObjects<T: Decodable>(from coreDataObjects: [CoreDataObject]) throws -> [T] {
        return try coreDataObjects.map { try makeCodable(from: $0) }
    }
    
    /// Retrieves all objects of the specified type conforming to `Codable` from the Garage.
    ///
    /// - parameter objectType: The type of the objects to retrieve.
    ///
    /// - returns: An array of objects of the same type `T`. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable>(_ objectType: T.Type) throws -> [T] {
        let typeName = String(describing: T.self)
        return try context.performAndWait {
            let coreDataObjects = fetchObjects(for: typeName, identifier: nil)
            return try makeCodableObjects(from: coreDataObjects)
        }
    }
    
    // MARK: Deleting
    
    /// Deletes an object conforming to `Identifiable` from the Garage.
    ///
    /// - parameter object: An object conforming to `Identifiable`, where the `ID` is `LosslessStringConvertible`.
    public func delete<T: Identifiable>(_ object: T) throws where T.ID: LosslessStringConvertible {
        let identifier = String(object.id)
        let typeName = String(describing: T.self)
        try context.performAndWait {
            try deleteCoreDataObject(for: typeName, identifier: identifier)
        }
        
        autosave()
    }
 
    /// Deletes an object conforming to `Hashable` from the Garage.
    ///
    /// - parameter object: An object conforming to `Hashable`.
    public func delete<T: Hashable>(_ object: T) throws {
        let identifier = "\(object.hashValue)"
        let typeName = String(describing: T.self)
        try context.performAndWait {
            try deleteCoreDataObject(for: typeName, identifier: identifier)
        }
        
        autosave()
    }

    /// Deletes all objects of the specified type `T` from the Garage.
    ///
    /// - parameter objectType: A type.
    public func deleteAll<T>(_ objectType: T.Type) {
        let typeName = String(describing: T.self)
        context.performAndWait {
            let coreDataObjects = fetchObjects(for: typeName, identifier: nil)
            deleteAll(coreDataObjects)
        }
        
        autosave()
    }
}
