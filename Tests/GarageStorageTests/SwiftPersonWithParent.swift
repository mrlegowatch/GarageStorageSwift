//
//  SwiftPersonWithParent.swift
//  GarageStorageTests
//
//  Created on 11/14/25.
//  Copyright © 2025 Wellframe. All rights reserved.
//

import Foundation

// This test model is used to test the decodeDefault code path in Garage+CodableReference.swift.
// It contains a non-optional Identifiable property, which triggers the custom decode method
// when decoding without a Garage.
class SwiftPersonWithParent: Codable, Identifiable {
    
    // Map the identifier to a preferred property, if desired.
    var id: String { name }
    
    var name: String = ""
    
    // Non-optional Identifiable property - this is key for testing decodeDefault
    var parent: SwiftPerson = SwiftPerson()
}
