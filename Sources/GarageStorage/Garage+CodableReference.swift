//
//  Garage+CodableReference.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/7/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

// This file contains extensions for encoding and decoding nested
// Identifiable objects by reference.
//
// The Swift runtime needs to provide a nudge for whether about-to-be-saved
// reference is an explicitly-parked object (an `Identifiable` with an `id`
// conforming to `LosslessStringConvertible`), so the Garage is stored and
// accessed via the super encoder or decoder to ensure that they are parked
// appropriately. Without this, the references would fail to be retrieved.

extension Encoder {
    
    var garage: Garage? { self.userInfo[Garage.userInfoKey] as? Garage }
}


/// These encoding extensions are exposed to the Swift runtime, to ensure that references to any embedded `Identifiable` objects (where `ID` is `LosslessStringConvertible`) are correctly parked at the top level of the Garage.
public extension KeyedEncodingContainer {
    
    /// Wraps the default `encode` implementation so that we can call it from our Identifiable version.
    private mutating func encodeDefault<T: Encodable>(_ codable: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        try encode(codable, forKey: key)
    }
    
    /// Encodes a nested `Identifiable` object (where `ID` is `LosslessStringConvertible`) as a reference.
    mutating func encode<T: Encodable & Identifiable>(_ identifiable: T, forKey key: KeyedEncodingContainer<K>.Key) throws where T.ID: LosslessStringConvertible {
        // If this encoder does not have a garage, encode as Codable does.
        let encoder = superEncoder()
        guard let garage = encoder.garage else {
            try encodeDefault(identifiable, forKey: key)
            return
        }
        
        // Park the object and encode it as a reference
        try garage.park(identifiable)
        let reference = String(identifiable.id)
        try encode(reference, forKey: key)
    }

    /// Encodes a nested `Identifiable` object (where `ID` is `LosslessStringConvertible`) as a reference, if present.
    mutating func encodeIfPresent<T: Encodable & Identifiable>(_ identifiable: T?, forKey key: KeyedEncodingContainer<K>.Key) throws where T.ID: LosslessStringConvertible {
        guard let identifiable = identifiable else { return }
        try encode(identifiable, forKey: key)
    }
    
    /// Encodes a nested array of `Identifiable` objects (where `ID` is `LosslessStringConvertible`) as references.
    mutating func encode<T: Encodable & Identifiable>(_ identifiables: [T], forKey key: KeyedEncodingContainer<K>.Key) throws where T.ID: LosslessStringConvertible {
        guard identifiables.count > 0 else { return }
        // If this encoder does not have a garage, encode as Codable does.
        let encoder = superEncoder()
        guard let garage = encoder.garage else {
            try encodeDefault(identifiables, forKey: key)
            return
        }
        
        // Park the objects and encode them as references
        try garage.parkAll(identifiables)
        let references = identifiables.map { String($0.id) }
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

/// These decoding extensions are exposed to the Swift runtime, to ensure that references to any embedded `Identifiable` objects (where `ID` is `LosslessStringConvertible`) are correctly retrieved from the top level of the Garage.
public extension KeyedDecodingContainer {
    
    /// Wraps the default `decode` implementation so that we can call it from our Identifiable version.
    private func decodeDefault<T: Decodable>(_ codable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        return try decode(T.self, forKey: key)
    }

    /// Decodes a reference to a nested Identifiable object (where `ID` is `LosslessStringConvertible`).
    func decode<T: Decodable & Identifiable>(_ identifiable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T where T.ID: LosslessStringConvertible {
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
    
    /// Wraps the default `decodeIfPresent` implementation so that we can call it from our Identifiable version.
    private func decodeIfPresentDefault<T: Decodable>(_ codable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
        return try decodeIfPresent(T.self, forKey: key)
    }
    
    /// Decodes a reference to a nested `Identifiable` object (where `ID` is `LosslessStringConvertible`), if present.
    func decodeIfPresent<T: Decodable & Identifiable>(_ identifiable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? where T.ID: LosslessStringConvertible {
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
    
    /// Decodes an array of references to nested `Identifiable` objects (where `ID` is `LosslessStringConvertible`).
    func decode<T: Decodable & Identifiable>(_ identifiable: [T].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [T] where T.ID: LosslessStringConvertible {
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
