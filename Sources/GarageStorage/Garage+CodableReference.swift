//
//  Garage+CodableReference.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/7/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

// This file contains extensions for encoding and decoding nested
// Mappable objects by reference.
//
// The Swift runtime needs to provide a nudge for whether about-to-be-saved
// reference is an explicitly-parked object (a `Mappable` with an `id`),
// so the Garage is stored and accessed via the super encoder or decoder to
// ensure that they are parked appropriately. Without this, the references
// would fail to be retrieved.

extension Encoder {
    
    var garage: Garage? { self.userInfo[Garage.userInfoKey] as? Garage }
}


/// These encoding extensions are exposed to the Swift runtime, to ensure that references to any embedded `Mappable` objects are correctly parked at the top level of the Garage.
public extension KeyedEncodingContainer {
    
    /// Wraps the default `encode` implementation so that we can call it from our Mappable version.
    private mutating func encodeDefault<T: Encodable>(_ codable: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        try encode(codable, forKey: key)
    }
    
    /// Encodes a nested `Mappable` object as a reference.
    mutating func encode<T: Mappable>(_ mappable: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        // If this encoder does not have a garage, encode as Codable does.
        let encoder = superEncoder()
        guard let garage = encoder.garage else {
            try encodeDefault(mappable, forKey: key)
            return
        }
        
        // Park the object and encode it as a reference
        try garage.park(mappable)
        let reference = mappable.id
        try encode(reference, forKey: key)
    }

    /// Encodes a nested `Mappable` object as a reference, if present.
    mutating func encodeIfPresent<T: Mappable>(_ mappable: T?, forKey key: KeyedEncodingContainer<K>.Key) throws {
        guard let mappable = mappable else { return }
        try encode(mappable, forKey: key)
    }
    
    /// Encodes a nested array of `Mappable` objects as references.
    mutating func encode<T: Mappable>(_ mappables: [T], forKey key: KeyedEncodingContainer<K>.Key) throws {
        guard mappables.count > 0 else { return }
        // If this encoder does not have a garage, encode as Codable does.
        let encoder = superEncoder()
        guard let garage = encoder.garage else {
            try encodeDefault(mappables, forKey: key)
            return
        }
        
        // Park the objects and encode them as references
        try garage.parkAll(mappables)
        let references = mappables.map { $0.id }
        try encode(references, forKey: key)
    }
}

extension Decoder {
    
    /// The underlying Garage used by this Decoder, if specified.
    var garage: Garage? { self.userInfo[Garage.userInfoKey] as? Garage }

    /// Returns a `DecodingError` of type `dataCorrupted`.
    func makeDecodingError(_ description: String) -> DecodingError {
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: description)
        return DecodingError.dataCorrupted(context)
    }
}

/// These decoding extensions are exposed to the Swift runtime, to ensure that references to any embedded `Mappable` objects are correctly retrieved from the top level of the Garage.
public extension KeyedDecodingContainer {
    
    /// Wraps the default `decode` implementation so that we can call it from our Mappable version.
    private func decodeDefault<T: Decodable>(_ codable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        return try decode(T.self, forKey: key)
    }

    /// Decodes a reference to a nested Mappable object.
    func decode<T: Mappable>(_ mappable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        // If this decoder does not have a garage, decode as Codable does.
        let decoder = try superDecoder()
        guard let garage = decoder.garage else {
            return try decodeDefault(T.self, forKey: key)
        }
        
        let reference = try decodeReference(forKey: key)
        guard let object = try garage.retrieve(T.self, identifier: reference) else {
            throw decoder.makeDecodingError("Missing reference: \(reference) of type: \(T.self)")
        }
        return object
    }
    
    /// Wraps the default `decodeIfPresent` implementation so that we can call it from our Mappable version.
    private func decodeIfPresentDefault<T: Decodable>(_ codable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
        return try decodeIfPresent(T.self, forKey: key)
    }
    
    /// Decodes a reference to a nested `Mappable` object, if present.
    func decodeIfPresent<T: Mappable>(_ mappable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
        // If this decoder does not have a garage, decode as Codable does.
        let decoder = try superDecoder()
        guard let garage = decoder.garage else {
            return try decodeIfPresentDefault(T.self, forKey: key)
        }
        
        guard let reference = try decodeReferenceIfPresent(forKey: key) else {
            return nil
        }
        return try garage.retrieve(T.self, identifier: reference)
    }
    
    /// Decodes an array of references to nested `Mappable` objects.
    func decode<T: Mappable>(_ mappable: [T].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [T] {
        // If this decoder does not have a garage, decode as Codable does.
        let decoder = try superDecoder()
        guard let garage = decoder.garage else {
            return try decodeIfPresentDefault([T].self, forKey: key) ?? []
        }
        
        let references = try decodeReferencesIfPresent(forKey: key)
        
        var objects: [T] = []
        for reference in references {
            guard let object = try garage.retrieve(T.self, identifier: reference) else {
                throw Garage.makeError("Missing reference: \(reference) of type: \(T.self)")
            }
            objects.append(object)
        }
        return objects
    }
}
