//
//  Mappable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/9/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation

/// A protocol requiring `Codable` conformance that also requires a string `id`, for when you need to uniquely identify a top-level instance in storage.
///
/// This protocol is compatible with `Identifiable` where `ID == String`.
public protocol Mappable: Codable /*, Identifiable where ID == String */ {

    /// A unique identifier.
    var id: String { get }
}
