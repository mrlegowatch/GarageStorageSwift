//
//  MappableObject.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/9/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation


/// A protocol for providing Objective-C Key-Value Coding mappings of properties for garage storage, with optional support is provided to uniquely identify top-level objects.
///
/// Properties must include the `@objc` keyword if declared in Swift. If the object must be uniquely identified in storage, the ``ObjectMapping/identifyingAttribute`` can be assigned.
///
/// Supported property types include:
///  - Core types: `Int`, `Double`, `Bool`, `String`, `Date`
///  - Container types: `Array`, `Dictionary`
///  - Other ``MappableObject`` classes
///  - note: This protocol is only required for Objective-C compatibility. For Swift projects, use `Codable`, and for top-level objects use `Hashable` or `Identifiable`.
@objc(GSMappableObject)
public protocol MappableObject : NSObjectProtocol {
    
    @objc static var objectMapping: ObjectMapping { get }
}
