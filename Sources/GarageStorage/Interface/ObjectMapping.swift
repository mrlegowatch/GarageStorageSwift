//
//  ObjectMapping.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/8/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation


/// Provides mappings and optionally an identifying attribute for encoding and decoding an Objective-C MappableObject's properties.
@objc(GSObjectMapping)
public class ObjectMapping: NSObject {
    
    internal let classNameForMapping: String
    internal private(set) var mappings = [String:String]()
    
    private var _identifyingAttribute: String?
    
    /// Optionally, specify an identifying attribute that Garage Storage will use to maintain a unique reference to this instance. If left nil, the object will be stored as anonymous. If specified, the attribute must be included in the mappings.
    ///
    /// - note: If the *value* of the attribute is nil, the object will be stored as anonymous, and a warning will be logged if parked as a top-level object.
    @objc public var identifyingAttribute: String? {
        set {
            guard let value = newValue else { return }
            guard self.mappings[value] != nil else {
                print("identifyingAttribute is not in mappings. Check mappings, and ensure this is set after setting mappings.")
                return
            }
            _identifyingAttribute = newValue
        }
        get {
            return _identifyingAttribute
        }
    }
    
    /// Initializes a mapping with a given class.
    ///
    /// - parameter objectClass: A Mappable class
    ///
    /// - returns: An ObjectMapping
    @objc(mappingForClass:)
    static public func mapping(for objectClass: AnyClass) -> ObjectMapping {
        return ObjectMapping(for: objectClass)
    }
    
    /// Initializes a mapping with a given class.
    ///
    /// - parameter class: A mappable class
    ///
    /// - returns: An ObjectMapping
    ///
    public init(for objectClass: AnyClass) {
        self.classNameForMapping = NSStringFromClass(objectClass)
    }
    
    /// Adds mappings from an array. The mappings are the names of the properties to map on the object. When in doubt, map using this method.
    ///
    /// - parameter array: An array of strings.
    ///
    @objc(addMappingsFromArray:)
    public func addMappings(_ array: [String]) {
        let mappings = array.reduce(into: [String:String]()) { dictionary, element in
            dictionary[element] = element
        }
        addMappings(mappings)
    }
    
    /// Adds mappings from a dictionary. The keys in the dictionary are the names of the properties to map on the object. The values are the JSON keys in the underlying GSCoreDataObject they map to.
    ///
    /// - parameter dictionary: A dictionary of mappings
    ///
    @objc(addMappingsFromDictionary:)
    public func addMappings(_ dictionary: [String: String]) {
        self.mappings.merge(dictionary) { (_, new) in new }
    }
}
