//
//  Mappable.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/9/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation


/// Protocol for providing a string id, to uniquely identify an instance of a reference Codable type.
///
/// This protocol is compatible with Identifiable where ID == String.
public protocol Mappable: Codable /*, Identifiable where ID == String */ {

    var id: String { get }
}
