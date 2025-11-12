//
//  Mappable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/9/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation

/// An optional, convenience protocol that conforms to `Codable` and `Identifiable` where `ID` conforms to `LosslessStringConvertible`.
/// These two protocol conformances are required for uniquely identified objects in a Garage.
/// Most clients can simply conform to `Codable` and `Identifiable` directly, to meet these requirements.
/// This protocol is only required for backward compatibility with existing code already using Mappable.
public protocol Mappable: Codable, Identifiable where ID: LosslessStringConvertible { }
