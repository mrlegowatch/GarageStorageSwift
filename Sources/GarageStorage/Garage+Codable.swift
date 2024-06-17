//
//  Garage+Codable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/3/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
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
        let className = String(describing: type(of: object))
        let coreDataObject = retrieveCoreDataObject(for: className, identifier: identifier)
        coreDataObject.data = try encodeData(object)
        return coreDataObject
    }
    
    @discardableResult
    internal func makeSyncingCoreDataObject<T: Encodable & Syncable>(from object: T, identifier: String) throws -> CoreDataObject {
        let coreDataObject = try makeCoreDataObject(from: object, identifier: identifier)
        coreDataObject.syncStatus = object.syncStatus
        return coreDataObject
    }
    
    /// Add an object to the Garage.
    ///
    /// - parameter object: An object of type T that conforms to Mappable.
    public func park<T: Mappable>(_ object: T) throws {
        try makeCoreDataObject(from: object, identifier: object.id)
        
        autosave()
    }
    
    /// Add an object to the Garage.
    ///
    /// - parameter object: An object of type T that conforms to Mappable and Syncable.
    public func park<T: Mappable & Syncable>(_ object: T) throws {
        try makeSyncingCoreDataObject(from: object, identifier: object.id)
        
        autosave()
    }
    
    /// Add an object to the Garage.
    ///
    /// - parameter object: An object of type T that conforms to Encodable and Hashable.
    public func park<T: Encodable & Hashable>(_ object: T) throws {
        try makeCoreDataObject(from: object, identifier: "\(object.hashValue)")
        
        autosave()
    }
    
    /// Add an object to the Garage.
    ///
    /// - parameter object: An object of type T that conforms to Encodable, Hashable and Syncable.
    public func park<T: Encodable & Hashable & Syncable>(_ object: T) throws {
        try makeSyncingCoreDataObject(from: object, identifier: "\(object.hashValue)")
        
        autosave()
    }
    
    /// Adds an array of objects to the garage.
    ///
    /// - parameter objects: An array of objects of the same type T, that conform to Mappable.
    public func parkAll<T: Mappable>(_ objects: [T]) throws {
        for object in objects {
            try makeCoreDataObject(from: object, identifier: object.id)
        }
        
        autosave()
    }
    
    /// Adds an array of objects to the garage.
    ///
    /// - parameter objects: An array of objects of the same type T, that conform to Mappable and Syncable.
    public func parkAll<T: Mappable & Syncable>(_ objects: [T]) throws {
        for object in objects {
            try makeSyncingCoreDataObject(from: object, identifier: object.id)
        }
        
        autosave()
    }
    
    /// Adds an array of objects to the garage.
    ///
    /// - parameter objects: An array of objects of the same type T, that conform to Encodable and Hashable.
    public func parkAll<T: Encodable & Hashable>(_ objects: [T]) throws {
        for object in objects {
            try makeCoreDataObject(from: object, identifier: "\(object.hashValue)")
        }
        
        autosave()
    }
    
    /// Adds an array of objects to the garage.
    ///
    /// - parameter objects: An array of objects of the same type T, that conform to Encodable, Hashable and Syncable.
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
    
    /// Fetches an object of a given class with a given identifier from the Garage.
    ///
    /// - parameter objectClass: The type of the object to retrieve. This class must conform to Decodable.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier specified by that object's mapping.
    ///
    /// - returns: An object conforming to the specified class, or nil if it was not found.
    public func retrieve<T: Decodable>(_ objectClass: T.Type, identifier: String) throws -> T? {
        let className = String(describing: T.self)
        guard let coreDataObject = fetchObject(for: className, identifier: identifier) else { return nil }
        return try makeCodable(from: coreDataObject)
    }
    
    /// Fetches an object of a given class with a given identifier from the Garage.
    ///
    /// - parameter objectClass: The type of the object to retrieve. This class must conform to Decodable.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier specified by that object's mapping.
    ///
    /// - returns: An object conforming to the specified class, or nil if it was not found.
    public func retrieve<T: Decodable & Syncable>(_ objectClass: T.Type, identifier: String) throws -> T? {
        let className = String(describing: T.self)
        guard let coreDataObject = fetchObject(for: className, identifier: identifier) else { return nil }
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
    
    /// Fetches all objects of a given class from the Garage.
    ///
    /// - parameter objectClass: The class of the objects to retrieve
    ///
    /// - returns: An array of objects, all of which conform to the specified class. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable>(_ objectClass: T.Type) throws -> [T] {
        let className = String(describing: T.self)
        let coreDataObjects = fetchObjects(for: className, identifier: nil)
        return try makeCodableObjects(from: coreDataObjects)
    }
    
    /// Fetches all objects of a given class from the Garage.
    ///
    /// - parameter objectClass: The class of the objects to retrieve
    ///
    /// - returns: An array of objects, all of which conform to the specified class. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(_ objectClass: T.Type) throws -> [T] {
        let className = String(describing: T.self)
        let coreDataObjects = fetchObjects(for: className, identifier: nil)
        return try makeSyncableObjects(from: coreDataObjects)
    }
    
    // MARK: - Sync Status
    
    private func updateCoreDataSyncStatus(_ syncStatus: SyncStatus, for className: String, identifier: String) throws {
        let coreDataObject = try fetchCoreDataObject(for: className, identifier: identifier)
        coreDataObject.syncStatus = syncStatus
    }
    
    /// Sets the sync status for a given object of type T that conforms to Mappable and Syncable.
    ///
    /// - parameter syncStatus: The SyncStatus of the object
    /// - parameter object: An object of type T that conforms to Mappable and Syncable
    ///
    /// - throws: if not successful
    public func setSyncStatus<T: Mappable & Syncable>(_ syncStatus: SyncStatus, for object: T) throws {
        let className = String(describing: T.self)
        let identifier = object.id
        try updateCoreDataSyncStatus(syncStatus, for: className, identifier: identifier)
        
        autosave()
    }
    
    /// Sets the sync status for a given object of type T that conforms to Hashable and Syncable.
    ///
    /// - parameter syncStatus: The SyncStatus of the object
    /// - parameter object: An object of type T that conforms to Hashable and Syncable
    ///
    /// - throws: if not successful
    public func setSyncStatus<T: Hashable & Syncable>(_ syncStatus: SyncStatus, for object: T) throws {
        let className = String(describing: T.self)
        let identifier = "\(object.hashValue)"
        try updateCoreDataSyncStatus(syncStatus, for: className, identifier: identifier)
        
        autosave()
    }
    
    /// Sets the sync status for an array of objects of the same type T conforming to Mappable and Syncable.
    ///
    /// - parameter syncStatus: The SyncStatus of the objects
    /// - parameter objects: An array of objects of the same type T conforming to Mappable and Syncable.
    ///
    /// - throws: if there was a problem setting the sync status for an object. Note: Even if this throws, there still could be objects with their syncStatus was set successfully. A false repsonse simply indicates at least one failure.
    public func setSyncStatus<T: Mappable & Syncable>(_ syncStatus: SyncStatus, for objects: [T]) throws {
        let className = String(describing: T.self)
        for object in objects {
            let identifier = object.id
            try updateCoreDataSyncStatus(syncStatus, for: className, identifier: identifier)
        }
        
        autosave()
    }
 
    /// Sets the sync status for an array of objects of the same type T conforming to Hashable and Syncable.
    ///
    /// - parameter syncStatus: The SyncStatus of the objects
    /// - parameter objects: An array of objects of the same type T conforming to Hashable and Syncable.
    ///
    /// - throws: if there was a problem setting the sync status for an object. Note: Even if this throws, there still could be objects with their syncStatus was set successfully. A false repsonse simply indicates at least one failure.
    public func setSyncStatus<T: Hashable & Syncable>(_ syncStatus: SyncStatus, for objects: [T]) throws {
        let className = String(describing: T.self)
        for object in objects {
            let identifier = "\(object.hashValue)"
            try updateCoreDataSyncStatus(syncStatus, for: className, identifier: identifier)
        }

        autosave()
    }

    private func syncStatus<T>(for object: T, identifier: String) throws -> SyncStatus {
        let className = String(describing: T.self)
        let coreDataObject = try fetchCoreDataObject(for: className, identifier: identifier)
        return coreDataObject.syncStatus
    }
    
    /// Returns the sync status for an object.
    ///
    /// - parameter object: An object conforming to Mappable and Syncable
    ///
    /// - returns: The Sync Status
    public func syncStatus<T: Mappable & Syncable>(for object: T) throws -> SyncStatus {
        let identifier = object.id
        return try syncStatus(for: object, identifier: identifier)
    }

    /// Returns the sync status for an object.
    ///
    /// - parameter object: An object conforming to Hashable and Syncable
    ///
    /// - returns: The Sync Status
    public func syncStatus<T: Hashable & Syncable>(for object: T) throws -> SyncStatus {
        let identifier = "\(object.hashValue)"
        return try syncStatus(for: object, identifier: identifier)
    }

    /// Returns all the objects of type T conforming to Codable that have a given sync status
    ///
    /// - parameter syncStatus: The Sync Status
    ///
    /// - returns: An array of objects of type T conforming to Codable. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(withStatus syncStatus: SyncStatus) throws -> [T] {
        let coreDataObjects = try fetchObjects(with: syncStatus, type: nil)
        return try makeSyncableObjects(from: coreDataObjects)
    }
    
    /// Returns all the objects of type T conforming to Codable that have a given sync status
    ///
    /// - parameter objectClass: The class of the objects to retrieve
    /// - parameter syncStatus: The Sync Status
    ///
    /// - returns: An array of objects of type T conforming to Codable. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Decodable & Syncable>(_ objectClass: T.Type, withStatus syncStatus: SyncStatus) throws -> [T] {
        let className = String(describing: T.self)
        let coreDataObjects = try fetchObjects(with: syncStatus, type: className)
        return try makeSyncableObjects(from: coreDataObjects)
    }

    // MARK: - Deleting
    
    private func deleteCoreDataObject<T>(_ object: T, identifier: String) throws {
        let className = String(describing: T.self)
        let coreDataObject = try fetchCoreDataObject(for: className, identifier: identifier)
        try delete(coreDataObject)
    }
    
    /// Deletes an object of a given type from the Garage
    ///
    /// - parameter object: A type conforming to Codable
    public func delete<T: Mappable>(_ object: T) throws {
        let identifier = object.id
        try deleteCoreDataObject(object, identifier: identifier)
    }
 
    /// Deletes an object of a given type from the Garage
    ///
    /// - parameter object: A type conforming to Codable
    public func delete<T: Hashable>(_ object: T) throws {
        let identifier = "\(object.hashValue)"
        try deleteCoreDataObject(object, identifier: identifier)
    }

    /// Deletes all objects of a given type from the Garage
    ///
    /// - parameter objectClass: A type conforming to Codable
    public func deleteAll<T>(_ objectClass: T.Type) {
        let className = String(describing: T.self)
        let coreDataObjects = fetchObjects(for: className, identifier: nil)
        deleteAll(coreDataObjects)
    }
}
