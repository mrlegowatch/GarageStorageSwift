//
//  SwiftSquirrel.swift
//  GarageStorage
//
//  Created by Brian Arnold on 11/17/25.
//

struct SwiftSquirrel {
    var id: String { name }
    
    var name: String = ""
    var acornCount: Int = 0
}

// Conform to all the representations to validate priority of conformances.
extension SwiftSquirrel: Codable, Identifiable, Hashable { }
