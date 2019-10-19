//
//  Garage+Codable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/3/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation

extension Garage {
    
    // MARK: - Core Data
    
    private func coreDataIdentifier<T: Codable>(for object: T) throws -> String {
        let identifier: String
        if let mappable = object as? Mappable {
            identifier = mappable.id
        } else if let hashable = object as? AnyHashable {
            identifier = "\(hashable.hashValue)"
        } else {
            throw Garage.makeError("Could not park object of type \(type(of: object)), must conform to either Mappable or Hashable")
        }
        return identifier
    }
    
    private func makeCoreDataObject<T: Codable>(for object: T) throws -> CoreDataObject {
        let className = String(describing: type(of: object))
        let identifier = try coreDataIdentifier(for: object)
        
        let coreDataObject = fetchObject(for: className, identifier: identifier)
        
        return coreDataObject ?? makeCoreDataObject(className, identifier: identifier, version: 0)
    }
    
    private func fetchCoreDataObject<T: Codable>(for object: T) throws -> CoreDataObject {
        let className = String(describing: type(of: object))
        let identifier = try coreDataIdentifier(for: object)
        
        guard let coreDataObject = fetchObject(for: className, identifier: identifier) else {
            throw Garage.makeError("Failed to retrieve core data object for \(object), has it been parked yet?")
        }
        
        return coreDataObject
    }

    static let userInfoKey = CodingUserInfoKey(rawValue: "Garage")!
    
    internal func decodeData<T: Decodable>(_ string: String) throws -> T {
        let data: Data = try decrypt(string)

        let decoder = JSONDecoder()
        decoder.userInfo[Garage.userInfoKey] = self
        decoder.dateDecodingStrategy = .custom(decodeTransformableDate)
        
        return try decoder.decode(T.self, from: data)
    }
    
    private func makeCodable<T: Codable>(from coreDataObject: CoreDataObject) throws -> T {
        var codable: T = try decodeData(coreDataObject.data)

        // Use a var, and set it back after changing its (mutable) syncStatus
        if var syncable = codable as? Syncable {
            syncable.syncStatus = coreDataObject.syncStatus
            codable = syncable as! T
        }
        
        return codable
    }

    internal func encodeData<T: Encodable>(_ object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[Garage.userInfoKey] = self
        encoder.dateEncodingStrategy = .formatted(Date.isoFormatter)
        let data = try encoder.encode(object)
        
        return try encrypt(data)
    }

    // MARK: - Parking
    
    internal func makeCoreDataObject<T: Codable>(from object: T) throws {
        let coreDataObject = try makeCoreDataObject(for: object)
        coreDataObject.data = try encodeData(object)
        
        if let syncableObject = object as? Syncable {
            coreDataObject.syncStatus = syncableObject.syncStatus
        }
    }
    
    /// Add an object to the Garage.
    ///
    /// - parameter object: An object of type T that conforms to Codable.
    public func park<T: Codable>(_ object: T) throws {
        try makeCoreDataObject(from: object)
        
        autosave()
    }
    
    /// Adds an array of objects to the garage.
    ///
    /// - parameter objects: An array of objects of the same type T, that conform to Codable.
    public func parkAll<T: Codable>(_ objects: [T]) throws {
        for object in objects {
            try makeCoreDataObject(from: object)
        }
        
        autosave()
    }
    
    // MARK: - Retrieving
    
    /// Fetches an object of a given class with a given identifier from the Garage.
    ///
    /// - parameter objectClass: The type of the object to retrieve. This class must conform to Codable.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier specified by that object's mapping.
    ///
    /// - returns: An object conforming to the specified class, or nil if it was not found.
    public func retrieve<T: Codable>(_ objectClass: T.Type, identifier: String) throws -> T? {
        let className = String(describing: T.self)
        guard let coreDataObject = fetchObject(for: className, identifier: identifier) else {
            throw Garage.makeError("failed to retrieve object of class: \(T.self) identifier: \(identifier)")
        }
        
        return try makeCodable(from: coreDataObject)
    }
    
    private func makeCodableObjects<T: Codable>(from coreDataObjects: [CoreDataObject]) throws -> [T] {
        var objects = [T]()
        
        for coreDataObject in coreDataObjects {
            let codable: T = try makeCodable(from: coreDataObject)
            objects.append(codable)
        }
        
        return objects
    }
    
    /// Fetches all objects of a given class from the Garage.
    ///
    /// - parameter objectClass: The class of the objects to retrieve
    ///
    /// - returns: An array of objects, all of which conform to the specified class. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Codable>(_ objectClass: T.Type) throws -> [T] {
        let className = String(describing: T.self)
        let coreDataObjects = fetchObjects(for: className, identifier: nil)
        return try makeCodableObjects(from: coreDataObjects)
    }
    
    // MARK: - Sync Status
    
    private func updateCoreDataSyncStatus<T: Codable>(_ syncStatus: SyncStatus, for object: T) throws {
        let coreDataObject = try fetchCoreDataObject(for: object)
        coreDataObject.syncStatus = syncStatus
    }
    
    /// Sets the sync status for a given object of type T that conforms to Codable.
    ///
    /// - parameter syncStatus: The SyncStatus of the object
    /// - parameter object: An object of type T that conforms to Codable
    ///
    /// - throws: if not successful
    public func setSyncStatus<T: Codable>(_ syncStatus: SyncStatus, for object: T) throws {
        try updateCoreDataSyncStatus(syncStatus, for: object)
        
        autosave()
    }
    
    /// Sets the sync status for an array of objects of the same type T conforming to Codable.
    ///
    /// - parameter syncStatus: The SyncStatus of the objects
    /// - parameter objects: An array of objects of the same type T conforming to Codable.
    ///
    /// - throws: if there was a problem setting the sync status for an object. Note: Even if this throws, there still could be objects with their syncStatus was set successfully. A false repsonse simply indicates at least one failure.
    public func setSyncStatus<T: Codable>(_ syncStatus: SyncStatus, for objects: [T]) throws {
        for object in objects {
            try updateCoreDataSyncStatus(syncStatus, for: object)
        }
        
        autosave()
    }
    
    /// Returns the sync status for an object.
    ///
    /// - parameter object: An object conforming to Codable
    ///
    /// - returns: The Sync Status
    public func syncStatus<T: Codable>(for object: T) throws -> SyncStatus {
        let coreDataObject = try fetchCoreDataObject(for: object)
        return coreDataObject.syncStatus
    }
    
    /// Returns all the objects of type T conforming to Codable that have a given sync status
    ///
    /// - parameter syncStatus: The Sync Status
    ///
    /// - returns: An array of objects of type T conforming to Codable. If no objects are found, an empty array is returned.
    public func retrieveAll<T: Codable>(withStatus syncStatus: SyncStatus) throws -> [T] {
        let coreDataObjects = try fetchObjects(with: syncStatus, type: nil)
        
        return try makeCodableObjects(from: coreDataObjects)
    }
    
    // MARK: - Deleting
    
    /// Deletes an object of a given type from the Garage
    ///
    /// - parameter object: A type conforming to Codable
    public func delete<T: Codable>(_ object: T) throws {
        let coreDataObject = try fetchCoreDataObject(for: object)
        try delete(coreDataObject)
    }
    
    /// Deletes all objects of a given type from the Garage
    ///
    /// - parameter objectClass: A type conforming to Codable
    public func deleteAll<T: Codable>(_ objectClass: T.Type) {
        let className = String(describing: T.self)
        let coreDataObjects = fetchObjects(for: className, identifier: nil)
        deleteAll(coreDataObjects)
    }
}
