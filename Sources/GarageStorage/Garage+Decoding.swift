//
//  Garage+Decoding.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/14/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

// Function to pass into DateDecodingStrategy.custom(_) to enable parsing ISO Date.
internal func decodeISODate(_ decoder: Decoder) throws -> Date {
    let date: Date
    
    let container = try decoder.singleValueContainer()
    
    // Swift Codable encodes the date as a string directly
    if let string = try? container.decode(String.self) {
        date = Date.isoDate(for: string)!
    } else {
        throw decoder.makeDecodingError("Failed to decode into Date")
    }
    
    return date
}

// Extension that enables automatic decoding of Mappable references with identifyingAttributes,
// including in-place migration from MappableObject references.
internal extension KeyedDecodingContainer {

    func decodeReferenceIfPresent(forKey key: KeyedDecodingContainer<K>.Key) throws -> String? {
        let reference: String?
        
        // Swift Codable encodes the identifier directly
        if let identifier = try? decodeIfPresent(String.self, forKey: key) {
            reference = identifier
        } else {
            reference = nil
        }
        
        return reference
    }

    func decodeReference(forKey key: KeyedDecodingContainer<K>.Key) throws -> String {
        guard let reference = try decodeReferenceIfPresent(forKey: key) else {
            throw try superDecoder().makeDecodingError("Failed to decode Mappable reference")
        }
        
        return reference
    }
    
    func decodeReferencesIfPresent(forKey key: KeyedDecodingContainer<K>.Key) throws -> [String] {
        let references: [String]
        
        // Swift Codable encodes the array of identifiers directly
        if let identifiers = try? decodeIfPresent([String].self, forKey: key) {
            references = identifiers
        } else {
            references = []
        }
        
        return references
    }
}
