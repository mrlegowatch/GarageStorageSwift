//
//  Garage+Codable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/3/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation


// MARK: - Codable Hooks for Identifiable references

// The Swift runtime needs a nudge for whether an about-to-be-saved reference
// is an explicitly-parked object (an `Identifiable`), so the Garage is stored
// and accessed via the encoder or decoder to ensure that they are parked
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
    
    // MARK: - Identifiable ID extraction helpers
    
    /// Extracts an identifier string representation from an Identifiable ID.
    /// Only supports String, UUID, and LosslessStringConvertible ID types.
    /// - Throws: `GarageError.missingConformance` if the ID type is not supported.
    internal func extractIdentifierString(from identifiable: any Identifiable) throws -> String {
        let id = identifiable.id
        
        // Supported conversions for ID.
        if let stringId = id as? String { return stringId }
        if let uuidId = id as? UUID { return uuidId.uuidString }
        if let convertibleId = id as? any LosslessStringConvertible { return String(convertibleId) }
        
        // Unsupported ID type - throw error
        throw GarageError.unsupportedIDConformance(String(describing: type(of: id)))
    }
 
    /// Converts an identifier to a string representation.
    /// Only supports String, UUID, and LosslessStringConvertible identifier types.
    /// - Throws: `GarageError.missingConformance` if the identifier type is not supported.
    private func convertIdentifierToString<ID>(_ identifier: ID) throws -> String {
        // Supported conversions for identifiers.
        if let stringId = identifier as? String { return stringId }
        if let uuidId = identifier as? UUID { return uuidId.uuidString }
        if let convertibleId = identifier as? any LosslessStringConvertible { return String(convertibleId) }
        
        // Unsupported identifier type - throw error
        throw GarageError.unsupportedIDConformance(String(describing: ID.self))
    }
    

    // MARK: Core Data
    
    /// Decodes string data to the specified object type, decrypting the data if a ``dataEncodingDelegate`` is specified.
    /// Uses the date decoding strategy for any dates, and resolves any `Identifiable` references.
    /// Must be called from within context.performAndWait.
    internal func decodeData<T: Decodable>(_ string: String) throws -> T {
        let data: Data = try decrypt(string)
        
        let decoder = JSONDecoder()
        decoder.userInfo[.garage] = self
        decoder.dateDecodingStrategy = self.dateDecodingStrategy
        
        return try decoder.decode(T.self, from: data)
    }
    
    /// Encodes the specified object, encrypting its data if ``dataEncodingDelegate`` is specified.
    /// Uses the date encoding strategy for any dates, and encodes any `Identifiable` references.
    internal func encodeData<T: Encodable>(_ object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[.garage] = self
        encoder.dateEncodingStrategy = self.dateEncodingStrategy
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
        if let syncable = object as? any Syncable {
            coreDataObject.syncStatus = syncable.syncStatus
        }
    }
    
    /// Resolves an identifier from either an `Identifiable` or a `Hashable`.
    /// Throws if the type conforms to neither, or if Identifiable has an unsupported ID type.
    private func resolveIdentifier<T>(for object: T) throws -> String {
        // Prefer Identifiable
        if let identifiable = object as? any Identifiable {
            return try extractIdentifierString(from: identifiable)
        }
        // Fallback to Hashable
        if let hashable = object as? any Hashable {
            return "\(hashable.hashValue)"
        }
        
        throw GarageError.missingConformance("\(T.self)")
    }
    
    /// Adds an object conforming to `Encodable` and either `Identifiable` or  `Hashable` to the Garage.
    ///
    /// - parameter object: An object conforming to `Encodable` and either `Identifiable` or `Hashable`.
    ///
    /// - throws: `GarageError.missingConformance` if the type does not conform to either `Identifiable` or `Hashable`, or `GarageError.unsupportedIDConformance` if `Identifiable.ID` is not `String`, `UUID`, or `LosslessStringConvertible`.
    public func park<T: Encodable>(_ object: T) throws {
        try context.performAndWait {
            let identifier = try resolveIdentifier(for: object)
            try parkEncodable(from: object, identifier: identifier)
        }
        
        autosave()
    }
    
    /// Adds an array of objects conforming to `Encodable` to the Garage.
    /// Must be called from within context.performAndWait.
    internal func parkAllEncodables<T: Encodable>(_ objects: [T]) throws {
        for object in objects {
            let identifier = try resolveIdentifier(for: object)
            try parkEncodable(from: object, identifier: identifier)
        }
    }
    
    /// Adds an array of objects conforming to `Encodable` and either `Identifiable` or `Hashable` to the Garage.
    ///
    ///  - parameter objects: An array of objects conforming to `Encodable` and either `Identifiable` or `Hashable`.
    ///
    /// - throws: `GarageError.missingConformance` if the type does not conform to either `Identifiable` or `Hashable`, or `GarageError.unsupportedIDConformance` if `Identifiable.ID` is not `String`, `UUID`, or `LosslessStringConvertible`.
    public func parkAll<T: Encodable>(_ objects: [T]) throws {
        try context.performAndWait {
            try parkAllEncodables(objects)
        }
        
        autosave()
    }
    
    // MARK: Retrieving
    
    /// Returns a decoded instance from the specified Core Data object. Throws an error if unable to decode.
    /// Must be called from within context.performAndWait.
    private func makeCodable<T: Decodable>(from coreDataObject: CoreDataObject) throws -> T {
        guard let data = coreDataObject.gs_data else {
            throw GarageError.storageDataIsNil("\(T.self)")
        }
        return try decodeData(data)
    }
    
    /// Returns a decoded instance from the specified Core Data object. Throws an error if unable to decode.
    /// Must be called from within context.performAndWait. 
    private func makeSyncable<T: Decodable & Syncable>(from coreDataObject: CoreDataObject) throws -> T {
        var syncable: T = try makeCodable(from: coreDataObject)
        syncable.syncStatus = coreDataObject.syncStatus
        return syncable
    }
    
    /// Returns an instance of the specified type string and identifier string.
    /// Must be called from within context.performAndWait.
    private func retrieveDecodable<T: Decodable>(typeName: String, identifier: String) throws -> T? {
        guard let coreDataObject = fetchObject(for: typeName, identifier: identifier) else { return nil }
        return try makeCodable(from: coreDataObject)
    }
    
    /// Returns an instance of the specified object type and identifier.
    /// Must be called from within context.performAndWait.
    internal func retrieveDecodable<T: Decodable>(_ objectType: T.Type, identifier: String) throws -> T? {
        let typeName = String(describing: T.self)
        return try retrieveDecodable(typeName: typeName, identifier: identifier)
    }
    
    /// Retrieves an object of the specified type conforming to `Decodable` with the specified identifier from the Garage.
    ///
    /// - parameter objectType: The type of the object to retrieve. This type must conform to `Codable`.
    /// - parameter identifier: The identifier of the object to retrieve. This must match the identifier used when parking the object (from `Identifiable.id` or `Hashable.hashValue`).
    ///
    /// - returns: An object conforming to the specified type, or nil if it was not found.
    /// - throws: `GarageError.missingConformance` if the identifier type is not supported.
    public func retrieve<T: Decodable, ID>(_ objectType: T.Type, identifier: ID) throws -> T? {
        let typeName = String(describing: T.self)
        let identifierString = try convertIdentifierToString(identifier)
        return try context.performAndWait {
            return try retrieveDecodable(typeName: typeName, identifier: identifierString)
        }
    }
    
    /// Retrieves an object of the specified type conforming to `Decodable` and ``Syncable`` with the specified identifier from the Garage.
    ///
    /// - parameter objectType: The type of the object to retrieve. This type must conform to `Codable` and ``Syncable``.
    /// - parameter identifier: The identifier of the object to retrieve. This must match the identifier used when parking the object (from `Identifiable.id` or `Hashable.hashValue`).
    ///
    /// - returns: An object conforming to the specified type, or nil if it was not found.
    /// - throws: `GarageError.missingConformance` if the identifier type is not supported.
    public func retrieve<T: Decodable & Syncable, ID>(_ objectType: T.Type, identifier: ID) throws -> T? {
        let typeName = String(describing: T.self)
        let identifierString = try convertIdentifierToString(identifier)
        return try context.performAndWait {
            guard let coreDataObject = fetchObject(for: typeName, identifier: identifierString) else { return nil }
            return try makeSyncable(from: coreDataObject)
        }
    }
    
    /// Returns an array of `Decodable` objects corresponding to the specified Core Data objects.
    /// Must be called from within context.performAndWait.
    private func makeCodableObjects<T: Decodable>(from coreDataObjects: [CoreDataObject]) throws -> [T] {
        return try coreDataObjects.map { try makeCodable(from: $0) }
    }
    
    /// Returns an array of `Decodable` objects corresponding to the specified Core Data objects.
    /// Must be called from within context.performAndWait.
    private func makeSyncableObjects<T: Decodable & Syncable>(from coreDataObjects: [CoreDataObject]) throws -> [T] {
        return try coreDataObjects.map { try makeSyncable(from: $0) }
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
    
    /// Retrieves all objects of the specified type conforming to `Codable` and ``Syncable`` from the Garage.
    ///
    /// - parameter objectType: The type of the objects to retrieve.
    ///
    /// - returns: An array of objects of the same type `T`. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(_ objectType: T.Type) throws -> [T] {
        let typeName = String(describing: T.self)
        return try context.performAndWait {
		    let coreDataObjects = fetchObjects(for: typeName, identifier: nil)
		    return try makeSyncableObjects(from: coreDataObjects)
        }
    }
    
    // MARK: - Sync Status
    
    private func updateCoreDataSyncStatus(_ syncStatus: SyncStatus, for typeName: String, identifier: String) throws {
        let coreDataObject = try fetchCoreDataObject(for: typeName, identifier: identifier)
        coreDataObject.syncStatus = syncStatus
    }
    
    /// Sets the sync status for the specified object conforming to ``Syncable``.
    ///
    /// - parameter syncStatus: The ``SyncStatus`` of the object.
    /// - parameter object: An object of type `T` that conforms to ``Syncable``.
    ///
    /// - throws: `GarageError.missingConformance` if the type does not conform to either `Identifiable` or `Hashable`, or `GarageError.unsupportedIDConformance` if `Identifiable.ID` is not `String`, `UUID`, or `LosslessStringConvertible`.
    public func setSyncStatus<T: Syncable>(_ syncStatus: SyncStatus, for object: T) throws {
        let typeName = String(describing: T.self)
        let identifier = try resolveIdentifier(for: object)
        try context.performAndWait {
            try updateCoreDataSyncStatus(syncStatus, for: typeName, identifier: identifier)
        }
        
        autosave()
    }
    
    /// Sets the sync status for an array of objects of the same type `T` conforming to `Identifiable` or `Hashable`, and ``Syncable``.
    ///
    /// - parameter syncStatus: The ``SyncStatus`` of the objects
    /// - parameter objects: An array of objects of the same type `T` conforming to `Identifiable` or `Hashable`, and ``Syncable``.
    ///
    /// - throws: `GarageError.missingConformance` if the type does not conform to either `Identifiable` or `Hashable`, or `GarageError.unsupportedIDConformance` if `Identifiable.ID` is not `String`, `UUID`, or `LosslessStringConvertible`.
    /// - note: Even if this throws, there still could be objects with their ``Syncable/syncStatus`` set successfully. A false response simply indicates at least one failure.
    public func setSyncStatus<T: Syncable>(_ syncStatus: SyncStatus, for objects: [T]) throws {
        let typeName = String(describing: T.self)
        try context.performAndWait {
            for object in objects {
                let identifier = try resolveIdentifier(for: object)
                try updateCoreDataSyncStatus(syncStatus, for: typeName, identifier: identifier)
            }
        }
        
        autosave()
    }
    
    /// Returns the sync status for an object's underlying Core Data Object.
    private func syncStatus<T>(for object: T, identifier: String) throws -> SyncStatus {
        let typeName = String(describing: T.self)
        let coreDataObject = try fetchCoreDataObject(for: typeName, identifier: identifier)
        return coreDataObject.syncStatus
    }
    
    /// Returns the sync status for an object conforming to `Identifiable` or `Hashable`, and ``Syncable``.
    ///
    /// - parameter object: An object conforming to `Identifiable` or `Hashable`, and ``Syncable``.
    ///
    /// - returns: The ``SyncStatus``.
    /// - throws: `GarageError.missingConformance` if the type does not conform to either `Identifiable` or `Hashable`, or `GarageError.unsupportedIDConformance` if `Identifiable.ID` is not `String`, `UUID`, or `LosslessStringConvertible`.
    public func syncStatus<T: Syncable>(for object: T) throws -> SyncStatus {
        let identifier = try resolveIdentifier(for: object)
        return try context.performAndWait {
            return try syncStatus(for: object, identifier: identifier)
        }
    }

    /// Returns all the objects of type `T` conforming to `Codable` and ``Syncable`` that have the specified sync status.
    ///
    /// - parameter syncStatus: The ``SyncStatus``.
    ///
    /// - returns: An array of objects of type `T`. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(withStatus syncStatus: SyncStatus) throws -> [T] {
        return try context.performAndWait {
            let coreDataObjects = try fetchObjects(with: syncStatus, type: nil)
            return try makeSyncableObjects(from: coreDataObjects)
        }
    }
    
    /// Returns all the objects of type `T` conforming to `Codable` and ``Syncable`` that have the specified sync status.
    ///
    /// - parameter objectType: The type of the objects to retrieve.
    /// - parameter syncStatus: The ``SyncStatus``.
    ///
    /// - returns: An array of objects of type `T`. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(_ objectType: T.Type, withStatus syncStatus: SyncStatus) throws -> [T] {
        let typeName = String(describing: T.self)
        return try context.performAndWait {
            let coreDataObjects = try fetchObjects(with: syncStatus, type: typeName)
            return try makeSyncableObjects(from: coreDataObjects)
        }
    }

    // MARK: Deleting
    
    /// Deletes an object conforming to `Decodable` and either `Identifiable` or `Hashable` from the Garage.
    ///
    /// - parameter object: An object conforming to `Decodable` and either `Identifiable` or `Hashable`.
    ///
    /// - throws: `GarageError.missingConformance` if the type does not conform to either `Identifiable` or `Hashable`, or `GarageError.unsupportedIDConformance` if `Identifiable.ID` is not `String`, `UUID`, or `LosslessStringConvertible`.
    public func delete<T: Decodable>(_ object: T) throws {
        let typeName = String(describing: T.self)
        let identifier = try resolveIdentifier(for: object)
        
        try context.performAndWait {
            try deleteCoreDataObject(for: typeName, identifier: identifier)
        }
        
        autosave()
    }
 
    /// Deletes all objects of the specified type `T` from the Garage.
    ///
    /// - parameter objectType: A type.
    public func deleteAll<T: Decodable>(_ objectType: T.Type) {
        let typeName = String(describing: T.self)
        context.performAndWait {
            let coreDataObjects = fetchObjects(for: typeName, identifier: nil)
            deleteAll(coreDataObjects)
        }
        
        autosave()
    }
}

