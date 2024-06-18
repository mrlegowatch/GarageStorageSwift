//
//  Garage+MappableObject.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/3/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

// Property keys used in dictionaries.
struct Property {
    static let transformableType = "gs_transformableType"
    static let transformableData = "gs_transformableData"
    static let transformableDate = "gs_transformableDate"
    
    static let anonymousObject = "kGSAnonymousObject"
    static let anonymousData = "kGSAnonymousDataKey"
}

// MARK: - Utilities

extension Dictionary where Key == String, Value == Any {
    
    /// Returns whether this dictionary is tagged as an anonymous object
    var isAnonymous: Bool {
        let identifier = self[CoreDataObject.Attribute.identifier] as! String
        return identifier == Property.anonymousObject
    }
    
    var isTransformable: Bool {
        return self[CoreDataObject.Attribute.type] as? String == Property.transformableType
    }
}

extension Date {
    
    /// Returns this transformable type as a JSON dictionary.
    func jsonDictionary() -> [String:Any] {
        return [CoreDataObject.Attribute.type: Property.transformableType,
                Property.transformableType: Property.transformableDate,
                Property.transformableData: self.isoString]
    }
    
    /// Creates a date from a JSON dictionary tagged as transformable type.
    init?(from dictionary: [String:Any]) {
        guard let transformableType = dictionary[Property.transformableType] as? String,
            transformableType == Property.transformableDate else { return nil }
        let string = dictionary[Property.transformableData] as! String
        self = Date.isoDate(for: string)!
    }
}

extension Garage {

    // MARK: - To Core Data
    
    private func makeCoreDataObject(from object: MappableObject) throws {
        let coreDataObject = try makeCoreDataObject(for: object)
        coreDataObject.data = try encodeData(from: object)
        
        if let syncableObject = object as? SyncableObject {
            coreDataObject.syncStatus = syncableObject.syncStatus
        }
    }
    
    internal func encodeData(from object: MappableObject) throws -> String {
        let dictionary = try jsonDictionary(from: object)
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: []) // try dictionary.jsonString()
        return try encrypt(data)
    }
    
    private func jsonDictionary(from object: MappableObject) throws -> [String:Any] {
        var json = [String:Any]()
        
        // Cast the protocol'd object to NSObject to access Objective-C Key-Value Coding
        let kvc = object as! NSObject
        let mapping = type(of: object).objectMapping
        for (keyPath, jsonKey) in mapping.mappings {
            // Note: if kvc.value(forKey:) is throwing an exception (crashing) and the MappableObject is in Swift,
            // it could be because the property lacks an '@objc' in front of it, or the property name doesn't match.
            let value = kvc.value(forKey: keyPath)
            
            if let mappableObject = value as? MappableObject {
                // Reference may fail for an identified object with nil identifyingAttribute
                if let reference = try? jsonReference(for: mappableObject) {
                    json[jsonKey] = reference
                }
            } else if let array = value as? [Any] {
                json[jsonKey] = try jsonArray(from: array)
            } else  if let date = value as? Date {
                json[jsonKey] = date.jsonDictionary()
            } else if let value = value {
                json[jsonKey] = value
            }
        }
        
        return json
    }
    
    private func jsonArray(from array: [Any]) throws -> [Any] {
        var json = [Any]()
        
        for object in array {
            if let mappableObject = object as? MappableObject {
                // Reference may fail for an identified object with nil identifyingAttribute
                if let reference = try? jsonReference(for: mappableObject) {
                    json.append(reference)
                }
            } else if let array = object as? [Any] {
                json.append(try jsonArray(from: array))
            } else if let date = object as? Date {
                json.append(date.jsonDictionary())
            } else {
                json.append(object)
            }
        }
        
        return json
    }
    
    private func jsonReference(for object: MappableObject) throws -> [String:Any] {
        let reference: [String: Any]

        let mapping = type(of: object).objectMapping
        if mapping.identifyingAttribute != nil {
            reference = try jsonReference(forIdentified: object)
        } else {
            reference = try jsonReference(forAnonymous: object)
        }
        
        return reference
    }
    
    private func jsonReference(forIdentified object: MappableObject) throws -> [String:Any] {
        try makeCoreDataObject(from: object)
        let referencedObject = try fetchCoreDataObject(for: object)
        
        return [CoreDataObject.Attribute.identifier: referencedObject.gs_identifier!,
                CoreDataObject.Attribute.type: referencedObject.gs_type!]
    }
    
    private func jsonReference(forAnonymous object: MappableObject) throws -> [String:Any] {
        let reference: [String: Any]
        let string = try encodeData(from: object)
        let className = NSStringFromClass(type(of: object))
        if let syncableObject = object as? SyncableObject {
            reference = [CoreDataObject.Attribute.identifier: Property.anonymousObject,
                    CoreDataObject.Attribute.type: className,
                    Property.anonymousData: string,
                    CoreDataObject.Attribute.syncStatus: syncableObject.syncStatus.rawValue]
        } else {
            reference = [CoreDataObject.Attribute.identifier: Property.anonymousObject,
                    CoreDataObject.Attribute.type: className,
                    Property.anonymousData: string]
        }
        return reference
    }
    
    // MARK: - From Core Data

    private func decodeData(_ string: String, className: String) throws -> MappableObject {
        let jsonData = try decrypt(string)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        guard let jsonDict = jsonObject as? [String:Any] else {
            throw Garage.makeError("json format was not a dictionary: \(self)")
        }
        
        return try makeMappableObject(className, jsonDictionary: jsonDict)
    }
    
    private func makeMappableObject(from coreDataObject: CoreDataObject) throws -> MappableObject {
        let className = coreDataObject.gs_type!
        guard let data = coreDataObject.gs_data else {
            throw Garage.makeError("failed to retrieve gs_data from store of type \(className)")
        }
        let mappedObject = try decodeData(data, className: className)
        
        if let syncableObject = mappedObject as? SyncableObject {
            syncableObject.syncStatus = coreDataObject.syncStatus
        }
        
        return mappedObject
    }
    
    private func makeMappableObject(fromAnonymous dictionary: [String:Any]) throws -> MappableObject {
        let className = dictionary[CoreDataObject.Attribute.type] as! String
        let anonymousData = dictionary[Property.anonymousData] as! String
        let mappedObject = try decodeData(anonymousData, className: className)
        
        if let syncableObject = mappedObject as? SyncableObject, let syncStatus = dictionary[CoreDataObject.Attribute.syncStatus] as? Int {
            syncableObject.syncStatus = SyncStatus(rawValue: syncStatus) ?? .undetermined
        }
        
        return mappedObject
    }
    
    private func makeMappableObject(fromIdentified dictionary: [String:Any]) throws -> MappableObject {
        let type = dictionary[CoreDataObject.Attribute.type] as! String
        let identifier = dictionary[CoreDataObject.Attribute.identifier] as! String
        
        guard let referencedObject = fetchObject(for: type, identifier: identifier) else {
            throw Garage.makeError("Failed to fetch referenced object for type: \(type) identifier: \(identifier)")
        }
        return try makeMappableObject(from: referencedObject)
    }
    
    private func makeMappableObject(_ className: String, jsonDictionary json:[String:Any]) throws -> MappableObject {
        // Cast the class as both NSObject and MappableObject to avoid an obscure linker error:
        // https://stackoverflow.com/questions/55831682/swift-thinks-im-subclassing-nsset-wrongly-but-im-not-subclassing-it-at-all
        let gsClass = NSClassFromString(className) as! (NSObject & MappableObject).Type
        let gsObject = gsClass.init() // A metatype is about the only thing one should call init() on directly.
        
        let mapping = type(of: gsObject).objectMapping
        let kvc = gsObject // "as! NSObject" cast not needed here, because it was casted in gsClass
        for (keyPath, jsonKey) in mapping.mappings {
            // Note: if kvc.setValue(forKey:) is throwing an exception (crashing) and the MappableObject is in Swift,
            // it could be because the property lacks an '@objc' in front of it, or the property name doesn't match.
            let value = json[jsonKey]
            if let dictionary = value as? [String:Any], dictionary[CoreDataObject.Attribute.identifier] != nil {
                if dictionary.isAnonymous {
                    kvc.setValue(try makeMappableObject(fromAnonymous: dictionary), forKey: keyPath)
                } else {
                    kvc.setValue(try makeMappableObject(fromIdentified: dictionary), forKey: keyPath)
                }
            } else if let array = value as? [Any] {
                kvc.setValue(try makeArray(from: array), forKey: keyPath)
            } else if let dictionary = value as? [String:Any], dictionary.isTransformable {
                kvc.setValue(Date(from: dictionary), forKey: keyPath)
            } else if let value = value {
                kvc.setValue(value, forKey: keyPath)
            }
        }
        
        return gsObject
    }
    
    private func makeArray(from jsonArray: [Any]) throws -> [Any] {
        var objectsArray = [Any]()
        
        for value in jsonArray {
            if let dictionary = value as? [String:Any], dictionary[CoreDataObject.Attribute.identifier] != nil {
                if dictionary.isAnonymous {
                    objectsArray.append(try makeMappableObject(fromAnonymous: dictionary))
                } else {
                    objectsArray.append(try makeMappableObject(fromIdentified: dictionary))
                }
            } else if let array = value as? [Any] {
                objectsArray.append(try makeArray(from: array))
            } else if let dictionary = value as? [String:Any], dictionary.isTransformable {
                objectsArray.append(Date(from: dictionary)!)
            } else {
                objectsArray.append(value)
            }
        }
        
        return objectsArray
    }
        
    private func coreDataIdentifier(for object: MappableObject, attribute: String?) throws -> String {
        let identifier: String
        
        if let identifyingAttribute = attribute {
            // Cast the protocol'd object to NSObject to access Objective-C Key-Value Coding
            let kvc = object as! NSObject
            
            // Note: if kvc.value(forKey:) is throwing an exception and the MappableObject is in Swift,
            // it could be because the identifying attribute lacks an '@objc' in front of it.
            guard let value = kvc.value(forKey: identifyingAttribute) else {
                throw Garage.makeError("Could not find identifying attribute `\(identifyingAttribute)` for object: \(object)")
            }
            identifier = value as! String
        } else {
            let string = try encodeData(from: object)
            // TODO: is not using homegrown MD5 hash here OK?
            identifier = "\(string.hashValue)"
        }
        
        return identifier
    }
        
    private func fetchCoreDataObject(for object: MappableObject) throws -> CoreDataObject {
        let mapping = type(of: object).objectMapping
        let type = mapping.classNameForMapping
        let identifier = try coreDataIdentifier(for: object, attribute: mapping.identifyingAttribute)
        
        guard let coreDataObject = fetchObject(for: type, identifier: identifier) else {
            throw Garage.makeError("Failed to retrieve core data object for \(object), has it been parked yet?")
        }
        
        return coreDataObject
    }

    // MARK: - Parking
    
    private func makeCoreDataObject(for object: MappableObject) throws -> CoreDataObject {
        let mapping = type(of: object).objectMapping
        let type = mapping.classNameForMapping
        let identifier = try coreDataIdentifier(for: object, attribute: mapping.identifyingAttribute)
        
        return retrieveCoreDataObject(for: type, identifier: identifier)
    }

    /// Add an object to the Garage. Parking an object without an identifier set will go into the Garage as unidentified.
    ///
    /// - parameter object: An object that conforms to MappableObject
    public func parkObject(_ object: MappableObject) throws {
        try makeCoreDataObject(from: object)

        autosave()
    }

    /// Adds an Objective-C-compatible object to the Garage.
    ///
    /// Parking an object without an identifier set will go into the Garage as unidentified.
    ///
    /// - parameter object: An object that conforms to MappableObject
    @objc(parkObjectInGarage:error:)
    public func __parkObjectObjC(_ object: MappableObject?) throws {
        guard let object = object else {
            throw Garage.makeError("nil passed to parkObject")
        }
        
        try parkObject(object)
    }

    /// Adds an array of Objective-C objects to the Garage.
    ///
    /// Parking an object without an identifier set will go into the Garage as unidentified.
    ///
    /// - parameter objects: An array of objects, all of which must conform to MappableObject.
    @objc(parkObjectsInGarage:error:)
    public func parkObjects(_ objects: [MappableObject]) throws {
        for object in objects {
            try makeCoreDataObject(from: object)
        }
        
        autosave()
    }

    // MARK: - Retrieving
    
    private func retrieveMappableObject(_ objectClass: AnyClass, identifier: String) throws -> MappableObject? {
        let className = NSStringFromClass(objectClass)
        
        guard let coreDataObject = fetchObject(for: className, identifier: identifier) else { return nil }
        
        return try makeMappableObject(from: coreDataObject)
    }

    /// Retrieves an object of a given class conforming to MappableObject with a given identifier from the Garage.
    ///
    /// - parameter objectClass: The class of the object to retrieve. This class must conform to MappableObject.
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier specified by that object's mapping.
    ///
    /// - returns: An object conforming to the specified class, or nil if it was not found.
    public func retrieveObject<T: MappableObject>(_ objectClass: T.Type, identifier: String) throws -> T? {
        return try retrieveMappableObject(objectClass.self, identifier: identifier) as? T
    }

    /// Retrieves an object of a given class with a given identifier from the Garage.
    ///
    /// - parameter objectClass: The class of the object to retrieve. This class must conform to GSMappableObject
    /// - parameter identifier: The identifier of the object to retrieve. This is the identifier specified by that object's mapping.
    ///
    /// - returns: An object conforming to GSMappableObject.
    @objc(retrieveObjectOfClass:identifier:error:)
    public func __retrieveObjectObjC(_ objectClass: AnyClass, identifier: String) throws -> Any {
        guard let object = try retrieveMappableObject(objectClass, identifier: identifier) else {
            // This "throws" an error in order for the return value to be nil in Objective-C.
            throw Garage.makeError("failed to retrieve object of class: \(className) identifier: \(identifier)")
        }
        return object
    }

    private func makeMappableObjects(from coreDataObjects: [CoreDataObject]) throws -> [MappableObject] {
        var objects = [MappableObject]()
        
        for coreDataObject in coreDataObjects {
            let mappableObject = try makeMappableObject(from: coreDataObject)
            objects.append(mappableObject)
        }
        
        return objects
    }

    private func retrieveAllMappableObjects(_ objectClass: AnyClass) throws -> [MappableObject] {
        let className = NSStringFromClass(objectClass)
        let coreDataObjects = fetchObjects(for: className, identifier: nil)
        return try makeMappableObjects(from: coreDataObjects)
    }

    /// Retrieves all objects of a given class from the Garage.
    ///
    /// - parameter objectClass: The class of the objects to retrieve
    ///
    /// - returns: An array of objects, all of which conform to the specified class. If no objects are found, an empty array is returned.
    public func retrieveAllObjects<T: MappableObject>(_ objectClass: T.Type) throws -> [T] {
        return try retrieveAllMappableObjects(objectClass.self) as!  [T]
    }

    /// Retrieves all objects of a given class from the Garage.
    ///
    /// - parameter objectClass: The class of the objects to retrieve
    ///
    /// - returns: An array of objects, all of which conform to MappableObject. If no objects are found, an empty array is returned.
    @objc(retrieveAllObjectsOfClass:error:)
    public func __retrieveAllObjectsObjC(_ objectClass: AnyClass) throws -> [Any] {
        return try retrieveAllMappableObjects(objectClass)
    }

    // MARK: - Sync Status
    
    private func updateCoreDataSyncStatus(_ syncStatus: SyncStatus, for object: MappableObject) throws {
        let coreDataObject = try fetchCoreDataObject(for: object)
        coreDataObject.syncStatus = syncStatus
    }

    /// Sets the sync status for a given MappableObject
    ///
    /// - parameter syncStatus: The SyncStatus of the object
    /// - parameter object: A MappableObject
    ///
    /// - throws: if not successful.
    @objc(setSyncStatus:forObject:error:)
    public func setSyncStatus(_ syncStatus: SyncStatus, for object: MappableObject) throws {
        try updateCoreDataSyncStatus(syncStatus, for: object)
        
        autosave()
    }

    /// Sets the sync status for an array of MappableObjects
    ///
    /// - parameter syncStatus: The SyncStatus of the objects
    /// - parameter objects: An array of MappableObjects
    ///
    /// - throws: true if successful (syncStatus was set on all), false if not. Note: Even if this returns false, there still could be objects with their syncStatus was set successfully. A false response simply indicates a minimum of 1 failure.
    @objc(setSyncStatus:forObjects:error:)
    public func setSyncStatus(_ syncStatus: SyncStatus, for objects: [MappableObject]) throws {
        for object in objects {
            try updateCoreDataSyncStatus(syncStatus, for: object)
        }
        
        autosave()
    }
    
    /// Returns the sync status for an object.
    ///
    /// - parameter object: A MappableObject
    ///
    /// - returns: The Sync Status
    public func syncStatus(for object: MappableObject) throws -> SyncStatus {
        let coreDataObject = try fetchCoreDataObject(for: object)
        return coreDataObject.syncStatus
    }

    /// Returns all the MappableObjects that have a given sync status.
    ///
    /// - parameter syncStatus: The Sync Status
    ///
    /// - returns: An array of MappableObjects. If no objects are found, an empty array is returned.
    @objc(retrieveObjectsWithSyncStatus:error:)
    public func retrieveObjects(withStatus syncStatus: SyncStatus) throws -> [MappableObject] {
        let coreDataObjects = try fetchObjects(with: syncStatus, type: nil)
        
        return try makeMappableObjects(from: coreDataObjects)
    }
    
    /// Returns all the MappableObjects of a given class that have a given sync status.
    ///
    /// - parameter syncStatus: The Sync Status
    /// - parameter objectClass: The Class of the MappableObjects
    ///
    /// - returns: An array of MappableObjects. If no objects are found, an empty array is returned.
    @objc(retrieveObjectsWithSyncStatus:ofClass:error:)
    public func retrieveObjects(withStatus syncStatus: SyncStatus, ofClass objectClass: AnyClass) throws -> [MappableObject] {
        let className = NSStringFromClass(objectClass)
        let coreDataObjects = try fetchObjects(with: syncStatus, type: className)
        
        return try makeMappableObjects(from: coreDataObjects)
    }

    // MARK: - Deleting
       
    /// Deletes an object from the Garage.
    ///
    /// Note that deleting an object will only delete that specific object, and not any of its member variables. While parking an object into the Garage is recursive, and member variables will be parked, deletion is not. Therefore, to remove an object's member variables from the Garage, make sure to remove them individually first.
    ///
    /// - parameter object:    An object conforming to MappableObject
    @objc(deleteObjectFromGarage:error:)
    public func deleteObject(_ object: MappableObject) throws {
        let coreDataObject = try fetchCoreDataObject(for: object)
        try delete(coreDataObject)
    }

    /// Deletes all objects of a given Objective-C class conforming to MappableObject from the Garage.
    ///
    /// - parameter objectClass: An object class conforming to MappableObject
    @objc(deleteAllObjectsFromGarageOfClass:)
    public func deleteAllObjects(_ objectClass: AnyClass) {
        let className = NSStringFromClass(objectClass)
        let coreDataObjects = fetchObjects(for: className, identifier: nil)
        deleteAll(coreDataObjects)
    }
}
