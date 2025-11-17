//
//  SwiftPlainCodable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 11/17/25.
//

struct SwiftPlainCodable {
    var name: String = ""
    var age: Int = 0
}

// Only make this type conform to Codable
extension SwiftPlainCodable: Codable { }
