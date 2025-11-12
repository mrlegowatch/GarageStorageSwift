//
//  Garage+Codable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/3/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

// MARK: ISO Date decoding helper

/// Function to pass into Decoder DateDecodingStrategy.custom(_) to enable parsing ISO Date.
internal func decodeISODate(_ decoder: Decoder) throws -> Date {
    let date: Date
    
    let container = try decoder.singleValueContainer()
    
    // Swift Codable encodes the date as a string directly
    if let string = try? container.decode(String.self) {
        date = Date.isoDate(for: string)!
    } else {
        let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to decode into Date")
        throw DecodingError.dataCorrupted(context)
    }
    
    return date
}

// MARK: - Codable Hooks for Identifiable references

// The Swift runtime needs to provide a nudge for whether an about-to-be-saved
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
        
    internal func decodeData<T: Decodable>(_ string: String) throws -> T {
        let data: Data = try decrypt(string)
        
        let decoder = JSONDecoder()
        decoder.userInfo[.garage] = self
        decoder.dateDecodingStrategy = .custom(decodeISODate)
        
        return try decoder.decode(T.self, from: data)
    }
    
    internal func encodeData<T: Encodable>(_ object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[.garage] = self
        encoder.dateEncodingStrategy = .formatted(Date.isoFormatter)
        let data = try encoder.encode(object)
        
        return try encrypt(data)
    }
    
    // MARK: Parking
    
    @discardableResult
    internal func makeCoreDataObject<T: Encodable>(from object: T, identifier: String) throws -> CoreDataObject {
        let typeName = String(describing: type(of: object))
        let coreDataObject = retrieveCoreDataObject(for: typeName, identifier: identifier)
        coreDataObject.data = try encodeData(object)
        return coreDataObject
    }
    
    /// Adds an object that conforms to `Codable` and `Identifiable` to the Garage.
    ///
    /// - parameter object: An object of type `T` that conforms to `Codable` and `Identifiable`, where the `ID` is `LosslessStringConvertible`.
    public func park<T: Encodable & Identifiable>(_ object: T) throws where T.ID: LosslessStringConvertible {
        try makeCoreDataObject(from: object, identifier: String(object.id))
        
        autosave()
    }
    
    /// Adds an object that conforms to `Codable` and `Hashable` to the Garage.
    ///
    /// - parameter object: An object of type `T` that conforms to `Codable` and `Hashable`.
    public func park<T: Encodable & Hashable>(_ object: T) throws {
        try makeCoreDataObject(from: object, identifier: "\(object.hashValue)")
        
        autosave()
    }
    
    /// Adds an array of objects that conform to `Codable` and `Identifiable` to the Garage.
    ///
    /// - parameter objects: An array of objects of the same type `T`, where the `ID` is `LosslessStringConvertible`.
    public func parkAll<T: Encodable & Identifiable>(_ objects: [T]) throws where T.ID: LosslessStringConvertible {
        for object in objects {
            try makeCoreDataObject(from: object, identifier: String(object.id))
        }
        
        autosave()
    }
    
    /// Adds an array of objects that conform to `Codable` and `Hashable` to the Garage.
    ///
    /// - parameter objects: An array of objects of the same type `T`.
    public func parkAll<T: Encodable & Hashable>(_ objects: [T]) throws {
        for object in objects {
            try makeCoreDataObject(from: object, identifier: "\(object.hashValue)")
        }
        
        autosave()
    }
    
    // MARK: Retrieving
    
    private func makeCodable<T: Decodable>(from coreDataObject: CoreDataObject) throws -> T {
        guard let data = coreDataObject.gs_data else {
            throw Garage.makeError("failed to retrieve gs_data from store of type \(T.self)")
        }
        let codable: T = try decodeData(data)
        return codable
    }
    
    /// Retrieves an object of the specified type conforming to `Codable` with the specified identifier from the Garage.
    ///
    /// - parameter objectType: The type of the object to retrieve. This type must conform to `Codable`.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier previously specified by either that object's `Identifiable` `id` or `Hashable` `hashValue`.
    ///
    /// - returns: An object conforming to the specified type, or nil if it was not found.
    public func retrieve<T: Decodable>(_ objectType: T.Type, identifier: LosslessStringConvertible) throws -> T? {
        let identifier = String(identifier)
        let typeName = String(describing: T.self)
        guard let coreDataObject = fetchObject(for: typeName, identifier: identifier) else { return nil }
        return try makeCodable(from: coreDataObject)
    }
    
    private func makeCodableObjects<T: Decodable>(from coreDataObjects: [CoreDataObject]) throws -> [T] {
        var objects = [T]()
        
        for coreDataObject in coreDataObjects {
            let codable: T = try makeCodable(from: coreDataObject)
            objects.append(codable)
        }
        
        return objects
    }
    
    /// Retrieves all objects of the specified type conforming to `Codable` from the Garage.
    ///
    /// - parameter objectType: The type of the objects to retrieve.
    ///
    /// - returns: An array of objects of the same type `T`. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable>(_ objectType: T.Type) throws -> [T] {
        let typeName = String(describing: T.self)
        let coreDataObjects = fetchObjects(for: typeName, identifier: nil)
        return try makeCodableObjects(from: coreDataObjects)
    }
    
    // MARK: Deleting
    
    private func deleteCoreDataObject<T>(_ object: T, identifier: LosslessStringConvertible) throws {
        let identifier = String(identifier)
        let typeName = String(describing: T.self)
        let coreDataObject = try fetchCoreDataObject(for: typeName, identifier: identifier)
        try delete(coreDataObject)
    }
        
    /// Deletes an object conforming to `Identifiable` from the Garage.
    ///
    /// - parameter object: An object conforming to `Identifiable`, where the `ID` is `LosslessStringConvertible`.
    public func delete<T: Identifiable>(_ object: T) throws where T.ID: LosslessStringConvertible {
        let identifier = String(object.id)
        try deleteCoreDataObject(object, identifier: identifier)
    }
 
    /// Deletes an object conforming to `Hashable` from the Garage.
    ///
    /// - parameter object: An object conforming to `Hashable`.
    public func delete<T: Hashable>(_ object: T) throws {
        let identifier = "\(object.hashValue)"
        try deleteCoreDataObject(object, identifier: identifier)
    }

    /// Deletes all objects of the specified type `T` from the Garage.
    ///
    /// - parameter objectType: A type.
    public func deleteAll<T>(_ objectType: T.Type) {
        let typeName = String(describing: T.self)
        let coreDataObjects = fetchObjects(for: typeName, identifier: nil)
        deleteAll(coreDataObjects)
    }
}
