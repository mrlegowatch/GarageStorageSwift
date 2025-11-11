//
//  Mappable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/9/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation

/// A convenience protocol that conforms to `Codable` and `Identifiable` where `ID` conforms to `LosslessStringConvertible`.
public protocol Mappable: Codable, Identifiable where ID: LosslessStringConvertible { }
