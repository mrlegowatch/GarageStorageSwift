//
//  Garage+Codable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/3/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

extension Garage {
    
    // MARK: - Core Data
    
    static let userInfoKey = CodingUserInfoKey(rawValue: "Garage")!
    
    internal func decodeData<T: Decodable>(_ string: String) throws -> T {
        let data: Data = try decrypt(string)
        
        let decoder = JSONDecoder()
        decoder.userInfo[Garage.userInfoKey] = self
        decoder.dateDecodingStrategy = .custom(decodeTransformableDate)
        
        return try decoder.decode(T.self, from: data)
    }
    
    internal func encodeData<T: Encodable>(_ object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[Garage.userInfoKey] = self
        encoder.dateEncodingStrategy = .formatted(Date.isoFormatter)
        let data = try encoder.encode(object)
        
        return try encrypt(data)
    }
    
    // MARK: - Parking
    
    @discardableResult
    internal func makeCoreDataObject<T: Encodable>(from object: T, identifier: String) throws -> CoreDataObject {
        let typeName = String(describing: type(of: object))
        let coreDataObject = retrieveCoreDataObject(for: typeName, identifier: identifier)
        coreDataObject.data = try encodeData(object)
        return coreDataObject
    }
    
    @discardableResult
    internal func makeSyncingCoreDataObject<T: Encodable & Syncable>(from object: T, identifier: String) throws -> CoreDataObject {
        let coreDataObject = try makeCoreDataObject(from: object, identifier: identifier)
        coreDataObject.syncStatus = object.syncStatus
        return coreDataObject
    }
    
    /// Adds an object that conforms to ``Mappable`` to the Garage.
    ///
    /// - parameter object: An object of type `T` that conforms to ``Mappable``.
    public func park<T: Mappable>(_ object: T) throws {
        try makeCoreDataObject(from: object, identifier: object.id)
        
        autosave()
    }
    
    /// Adds an object that conforms to ``Mappable`` and ``Syncable`` to the Garage.
    ///
    /// - parameter object: An object of type `T` that conforms to ``Mappable`` and ``Syncable``.
    public func park<T: Mappable & Syncable>(_ object: T) throws {
        try makeSyncingCoreDataObject(from: object, identifier: object.id)
        
        autosave()
    }
    
    /// Adds an object that conforms to `Codable` and `Hashable` to the Garage.
    ///
    /// - parameter object: An object of type `T` that conforms to `Codable` and `Hashable`.
    public func park<T: Encodable & Hashable>(_ object: T) throws {
        try makeCoreDataObject(from: object, identifier: "\(object.hashValue)")
        
        autosave()
    }
    
    /// Adds an object that conforms to `Codable`, `Hashable`, and ``Syncable`` to the Garage.
    ///
    /// - parameter object: An object of type `T` that conforms to `Codable`, `Hashable` and ``Syncable``.
    public func park<T: Encodable & Hashable & Syncable>(_ object: T) throws {
        try makeSyncingCoreDataObject(from: object, identifier: "\(object.hashValue)")
        
        autosave()
    }
    
    /// Adds an array of objects that conform to ``Mappable`` to the Garage.
    ///
    /// - parameter objects: An array of objects of the same type `T`.
    public func parkAll<T: Mappable>(_ objects: [T]) throws {
        for object in objects {
            try makeCoreDataObject(from: object, identifier: object.id)
        }
        
        autosave()
    }
    
    /// Adds an array of objects that conform to ``Mappable`` and ``Syncable`` to the Garage.
    ///
    /// - parameter objects: An array of objects of the same type `T`.
    public func parkAll<T: Mappable & Syncable>(_ objects: [T]) throws {
        for object in objects {
            try makeSyncingCoreDataObject(from: object, identifier: object.id)
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
    
    /// Adds an array of objects that conform to `Codable`, `Hashable`, and ``Syncable`` to the Garage.
    ///
    /// - parameter objects: An array of objects of the same type `T`.
    public func parkAll<T: Encodable & Hashable & Syncable>(_ objects: [T]) throws {
        for object in objects {
            try makeSyncingCoreDataObject(from: object, identifier: "\(object.hashValue)")
        }
        
        autosave()
    }
    
    // MARK: - Retrieving
    
    private func makeCodable<T: Decodable>(from coreDataObject: CoreDataObject) throws -> T {
        guard let data = coreDataObject.gs_data else {
            throw Garage.makeError("failed to retrieve gs_data from store of type \(T.self)")
        }
        let codable: T = try decodeData(data)
        return codable
    }
    
    private func makeSyncable<T: Decodable & Syncable>(from coreDataObject: CoreDataObject) throws -> T {
        var syncable: T = try makeCodable(from: coreDataObject)
        syncable.syncStatus = coreDataObject.syncStatus
        return syncable
    }
    
    /// Retrieves an object of the specified type conforming to `Codable` with the specified identifier from the Garage.
    ///
    /// - parameter objectType: The type of the object to retrieve. This type must conform to `Codable`.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier previously specified by either that object's ``Mappable`` `id` or `Hashable` `hashValue`.
    ///
    /// - returns: An object conforming to the specified type, or nil if it was not found.
    public func retrieve<T: Decodable>(_ objectType: T.Type, identifier: String) throws -> T? {
        let typeName = String(describing: T.self)
        guard let coreDataObject = fetchObject(for: typeName, identifier: identifier) else { return nil }
        return try makeCodable(from: coreDataObject)
    }
    
    /// Retrieves an object of the specified type conforming to `Codable` and ``Syncable`` with the specified identifier from the Garage.
    ///
    /// - parameter objectType: The type of the object to retrieve. This type must conform to `Codable` and ``Syncable``.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier previously specified by either that object's ``Mappable`` `id` or `Hashable` `hashValue`.
    ///
    /// - returns: An object conforming to the specified type, or nil if it was not found.
    public func retrieve<T: Decodable & Syncable>(_ objectType: T.Type, identifier: String) throws -> T? {
        let typeName = String(describing: T.self)
        guard let coreDataObject = fetchObject(for: typeName, identifier: identifier) else { return nil }
        return try makeSyncable(from: coreDataObject)
    }
    
    private func makeCodableObjects<T: Decodable>(from coreDataObjects: [CoreDataObject]) throws -> [T] {
        var objects = [T]()
        
        for coreDataObject in coreDataObjects {
            let codable: T = try makeCodable(from: coreDataObject)
            objects.append(codable)
        }
        
        return objects
    }
    
    private func makeSyncableObjects<T: Decodable & Syncable>(from coreDataObjects: [CoreDataObject]) throws -> [T] {
        var objects = [T]()
        
        for coreDataObject in coreDataObjects {
            let codable: T = try makeSyncable(from: coreDataObject)
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
    
    /// Retrieves all objects of the specified type conforming to `Codable` and ``Syncable`` from the Garage.
    ///
    /// - parameter objectType: The type of the objects to retrieve.
    ///
    /// - returns: An array of objects of the same type `T`. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(_ objectType: T.Type) throws -> [T] {
        let typeName = String(describing: T.self)
        let coreDataObjects = fetchObjects(for: typeName, identifier: nil)
        return try makeSyncableObjects(from: coreDataObjects)
    }
    
    // MARK: - Sync Status
    
    private func updateCoreDataSyncStatus(_ syncStatus: SyncStatus, for typeName: String, identifier: String) throws {
        let coreDataObject = try fetchCoreDataObject(for: typeName, identifier: identifier)
        coreDataObject.syncStatus = syncStatus
    }
    
    /// Sets the sync status for the specified object conforming to ``Mappable`` and ``Syncable``.
    ///
    /// - parameter syncStatus: The ``SyncStatus`` of the object.
    /// - parameter object: An object of type `T` that conforms to ``Mappable`` and ``Syncable``.
    ///
    /// - throws: if not successful
    public func setSyncStatus<T: Mappable & Syncable>(_ syncStatus: SyncStatus, for object: T) throws {
        let typeName = String(describing: T.self)
        let identifier = object.id
        try updateCoreDataSyncStatus(syncStatus, for: typeName, identifier: identifier)
        
        autosave()
    }
    
    /// Sets the sync status for the specified object conforming to `Hashable` and ``Syncable``.
    ///
    /// - parameter syncStatus: The ``SyncStatus`` of the object.
    /// - parameter object: An object of type T that conforms to `Hashable` and ``Syncable``.
    ///
    /// - throws: if not successful
    public func setSyncStatus<T: Hashable & Syncable>(_ syncStatus: SyncStatus, for object: T) throws {
        let typeName = String(describing: T.self)
        let identifier = "\(object.hashValue)"
        try updateCoreDataSyncStatus(syncStatus, for: typeName, identifier: identifier)
        
        autosave()
    }
    
    /// Sets the sync status for an array of objects of the same type `T` conforming to ``Mappable`` and ``Syncable``.
    ///
    /// - parameter syncStatus: The ``SyncStatus`` of the objects
    /// - parameter objects: An array of objects of the same type `T` conforming to ``Mappable`` and ``Syncable``.
    ///
    /// - throws: if there was a problem setting the sync status for an object. Note: Even if this throws, there still could be objects with their ``Syncable/syncStatus`` was set successfully. A false response simply indicates at least one failure.
    public func setSyncStatus<T: Mappable & Syncable>(_ syncStatus: SyncStatus, for objects: [T]) throws {
        let typeName = String(describing: T.self)
        for object in objects {
            let identifier = object.id
            try updateCoreDataSyncStatus(syncStatus, for: typeName, identifier: identifier)
        }
        
        autosave()
    }
 
    /// Sets the sync status for an array of objects of the same type `T` conforming to `Hashable` and ``Syncable``.
    ///
    /// - parameter syncStatus: The ``SyncStatus`` of the objects
    /// - parameter objects: An array of objects of the same type `T` conforming to `Hashable` and ``Syncable``.
    ///
    /// - throws: if there was a problem setting the sync status for an object. Note: Even if this throws, there still could be objects with their ``Syncable/syncStatus`` was set successfully. A false response simply indicates at least one failure.
    public func setSyncStatus<T: Hashable & Syncable>(_ syncStatus: SyncStatus, for objects: [T]) throws {
        let typeName = String(describing: T.self)
        for object in objects {
            let identifier = "\(object.hashValue)"
            try updateCoreDataSyncStatus(syncStatus, for: typeName, identifier: identifier)
        }

        autosave()
    }

    private func syncStatus<T>(for object: T, identifier: String) throws -> SyncStatus {
        let typeName = String(describing: T.self)
        let coreDataObject = try fetchCoreDataObject(for: typeName, identifier: identifier)
        return coreDataObject.syncStatus
    }
    
    /// Returns the sync status for an object conforming to ``Mappable`` and ``Syncable``.
    ///
    /// - parameter object: An object conforming to ``Mappable`` and ``Syncable``.
    ///
    /// - returns: The ``SyncStatus``.
    public func syncStatus<T: Mappable & Syncable>(for object: T) throws -> SyncStatus {
        let identifier = object.id
        return try syncStatus(for: object, identifier: identifier)
    }

    /// Returns the sync status for an object conforming to `Hashable` and ``Syncable``.
    ///
    /// - parameter object: An object conforming to `Hashable` and ``Syncable``
    ///
    /// - returns: The ``SyncStatus``.
    public func syncStatus<T: Hashable & Syncable>(for object: T) throws -> SyncStatus {
        let identifier = "\(object.hashValue)"
        return try syncStatus(for: object, identifier: identifier)
    }

    /// Returns all the objects of type `T` conforming to `Codable` and ``Syncable`` that have the specified sync status.
    ///
    /// - parameter syncStatus: The ``SyncStatus``.
    ///
    /// - returns: An array of objects of type `T`. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(withStatus syncStatus: SyncStatus) throws -> [T] {
        let coreDataObjects = try fetchObjects(with: syncStatus, type: nil)
        return try makeSyncableObjects(from: coreDataObjects)
    }
    
    /// Returns all the objects of type `T` conforming to `Codable` and ``Syncable`` that have the specified sync status.
    ///
    /// - parameter objectType: The type of the objects to retrieve.
    /// - parameter syncStatus: The ``SyncStatus``.
    ///
    /// - returns: An array of objects of type `T`. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(_ objectType: T.Type, withStatus syncStatus: SyncStatus) throws -> [T] {
        let typeName = String(describing: T.self)
        let coreDataObjects = try fetchObjects(with: syncStatus, type: typeName)
        return try makeSyncableObjects(from: coreDataObjects)
    }

    // MARK: - Deleting
    
    private func deleteCoreDataObject<T>(_ object: T, identifier: String) throws {
        let typeName = String(describing: T.self)
        let coreDataObject = try fetchCoreDataObject(for: typeName, identifier: identifier)
        try delete(coreDataObject)
    }
    
    /// Deletes an object conforming to ``Mappable`` from the Garage.
    ///
    /// - parameter object: An object conforming to ``Mappable``.
    public func delete<T: Mappable>(_ object: T) throws {
        let identifier = object.id
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
