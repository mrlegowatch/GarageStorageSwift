//
//  Garage+Reference.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/7/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation

extension Encoder {
    
    var garage: Garage? { self.userInfo[Garage.userInfoKey] as? Garage }
}

// Explicit methods for encoding and decoding nested Mappable objects by reference.
//
// Mappable doesn't know whether an about-to-be-saved reference is for a
// not-explicitly-parked object, so the garage is accessed via the super decoder
// to ensure that they are parked. Without this, references would fail to be retrieved.
public extension KeyedEncodingContainer {
    
    // Wrap the default implementation so we can call it from our Mappable version.
    mutating func encodeDefault<T: Encodable>(_ codable: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        try encode(codable, forKey: key)
    }
    
    mutating func encode<T: Mappable>(_ mappable: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        // If this encoder does not have a garage, encode as Codable does.
        let encoder = superEncoder()
        guard let garage = encoder.garage else {
            try encodeDefault(mappable, forKey: key)
            return
        }
        
        try garage.park(mappable)
        let reference = mappable.id
        try encode(reference, forKey: key)
    }
    
    // Wrap the default implementation so we can call it from our Mappable version.
    mutating func encodeIfPresentDefault<T: Encodable>(_ codable: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        try encodeIfPresent(codable, forKey: key)
    }

    mutating func encodeIfPresent<T: Mappable>(_ mappable: T?, forKey key: KeyedEncodingContainer<K>.Key) throws {
        guard let mappable = mappable else { return }
        try encode(mappable, forKey: key)
    }
    
    mutating func encode<T: Mappable>(_ mappables: [T], forKey key: KeyedEncodingContainer<K>.Key) throws {
        guard mappables.count > 0 else { return }
        // If this encoder does not have a garage, encode as Codable does.
        let encoder = superEncoder()
        guard let garage = encoder.garage else {
            try encodeDefault(mappables, forKey: key)
            return
        }
        
        // Encode references
        try garage.parkAll(mappables)
        let references = mappables.map { $0.id }
        try encode(references, forKey: key)
    }
}

extension Decoder {
    
    var garage: Garage? { self.userInfo[Garage.userInfoKey] as? Garage }

    func makeDecodingError(_ description: String) -> DecodingError {
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: description)
        return DecodingError.dataCorrupted(context)
    }
}

public extension KeyedDecodingContainer {
    
    // Wrap the default implementation so we can call it from our Mappable version.
    private func decodeDefault<T: Codable>(_ codable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        return try decode(T.self, forKey: key)
    }

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
    
    // Wrap the default implementation so we can call it from our Mappable version.
    private func decodeIfPresentDefault<T: Codable>(_ codable: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
        return try decodeIfPresent(T.self, forKey: key)
    }
    
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
