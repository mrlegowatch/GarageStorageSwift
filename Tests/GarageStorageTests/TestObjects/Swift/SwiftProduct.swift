//
//  SwiftProduct.swift
//  GarageStorage
//
//  Created by Brian Arnold on 11/17/25.
//

import Foundation

/// A product with UUID as identifier - demonstrates Identifiable with UUID ID type
struct SwiftProduct: Codable, Identifiable {
    let id: UUID
    var name: String
    var price: Double
    
    init(name: String, price: Double) {
        self.id = UUID()
        self.name = name
        self.price = price
    }
}
