//
//  SwiftOrder.swift
//  GarageStorage
//
//  Created by Brian Arnold on 11/17/25.
//

import Foundation

/// A custom ID type that is neither String, UUID, nor LosslessStringConvertible
struct OrderID: Codable, Hashable {
    let timestamp: Date
    let sequenceNumber: Int
    
    init(timestamp: Date = Date(), sequenceNumber: Int) {
        self.timestamp = timestamp
        self.sequenceNumber = sequenceNumber
    }
}

/// An order with a custom OrderID - demonstrates that unsupported ID types throw errors
struct SwiftOrder: Codable, Identifiable {
    let id: OrderID
    var orderNumber: String
    var totalAmount: Double
    var items: [String]
    
    init(orderNumber: String, totalAmount: Double, items: [String]) {
        // Create a deterministic OrderID based on order number for testing
        let sequenceNumber = Int(orderNumber.split(separator: "-").last.flatMap { Int($0) } ?? 0)
        self.id = OrderID(
            timestamp: Date(),
            sequenceNumber: sequenceNumber
        )
        self.orderNumber = orderNumber
        self.totalAmount = totalAmount
        self.items = items
    }
}

