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
    
    // MARK: - Identifiable ID extraction helpers (no reflection)
    private func extractStringID<I: Identifiable>(_ x: I) -> String? where I.ID == String { x.id }
    private func extractUUIDID<I: Identifiable>(_ x: I) -> String? where I.ID == UUID { x.id.uuidString }
    private func extractConvertibleID<I: Identifiable>(_ x: I) -> String? where I.ID: LosslessStringConvertible { String(x.id) }
    private func describeAnyID<I: Identifiable>(_ x: I) -> String? { String(describing: x.id) }

    // Helper to rebind an `any Identifiable` existential to a generic function when possible
    private func callGeneric<I: Identifiable>(_ value: any Identifiable, _ f: (I) -> String?) -> String? {
        (value as? I).flatMap(f)
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
    
    /// Resolves an identifier from either an Identifiable with ID = LosslessStringConvertible or UUID, or a Hashable.
    /// Throws if the type conforms to neither.
    private func resolveIdentifier<T>(for object: T) throws -> String {
        // Prefer Identifiable without reflection by opening the existential through constrained helpers.
        if let identifiable = object as? any Identifiable {
            if let s = callGeneric(identifiable, extractStringID) { return s }
            if let s = callGeneric(identifiable, extractUUIDID) { return s }
            if let s = callGeneric(identifiable, extractConvertibleID) { return s }
            if let s = callGeneric(identifiable, describeAnyID) { return s }
        }
        // Fallback to Hashable using hashValue
        if let hashable = object as? any Hashable {
            return "\(hashable.hashValue)"
        }
        throw GarageError.makeError("Type \(T.self) must conform to either Identifiable or Hashable to be parked")
    }
    
    /// Adds an object conforming to `Identifiable` or  `Hashable` to the Garage.
    public func park<T: Encodable>(_ object: T) throws {
        try context.performAndWait {
            let identifier = try resolveIdentifier(for: object)
            try parkEncodable(from: object, identifier: identifier)
        }
        
        autosave()
    }
    
    internal func parkAllEncodables<T: Encodable>(_ objects: [T]) throws {
        for object in objects {
            let identifier = try resolveIdentifier(for: object)
            try parkEncodable(from: object, identifier: identifier)
        }
    }
    
    /// Adds an array of objects to the Garage by preferring Identifiable identity over Hashable when both apply.
    /// The public API is unconstrained to avoid overload ambiguity; identity selection is resolved at runtime per element.
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
    
    /// Retrieves an object of the specified type conforming to `Decodable` and ``Syncable`` with the specified identifier from the Garage.
    ///
    /// - parameter objectType: The type of the object to retrieve. This type must conform to `Codable` and ``Syncable``.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier previously specified by either that object's ``Mappable`` `id` or `Hashable` `hashValue`.
    ///
    /// - returns: An object conforming to the specified type, or nil if it was not found.
    public func retrieve<T: Decodable & Syncable>(_ objectType: T.Type, identifier: String) throws -> T? {
        let typeName = String(describing: T.self)
        let identifierString = String(identifier)
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
    /// - throws: if not successful
    public func setSyncStatus<T: Syncable>(_ syncStatus: SyncStatus, for object: T) throws {
        let typeName = String(describing: T.self)
        let identifier = try resolveIdentifier(for: object)
        try context.performAndWait {
            try updateCoreDataSyncStatus(syncStatus, for: typeName, identifier: identifier)
        }
        
        autosave()
    }
    
    /// Sets the sync status for an array of objects of the same type `T` conforming to ``Mappable`` and ``Syncable``.
    ///
    /// - parameter syncStatus: The ``SyncStatus`` of the objects
    /// - parameter objects: An array of objects of the same type `T` conforming to ``Mappable`` and ``Syncable``.
    ///
    /// - throws: if there was a problem setting the sync status for an object. Note: Even if this throws, there still could be objects with their ``Syncable/syncStatus`` was set successfully. A false response simply indicates at least one failure.
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
    ///
    private func syncStatus<T>(for object: T, identifier: String) throws -> SyncStatus {
        let typeName = String(describing: T.self)
        let coreDataObject = try fetchCoreDataObject(for: typeName, identifier: identifier)
        return coreDataObject.syncStatus
    }
    
    /// Returns the sync status for an object conforming to `Codable`, `Identifiable`, and ``Syncable``.
    ///
    /// - parameter object: An object conforming to `Codable`, `Identifiable`, and ``Syncable``.
    ///
    /// - returns: The ``SyncStatus``.
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
    
    /// Deletes an object from the Garage by preferring Identifiable identity over Hashable when both apply.
    /// The public API is unconstrained to avoid overload ambiguity; identity selection is resolved at runtime.
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

