//
//  MappableObject.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/9/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import Foundation


/// Protocol for providing Objective-C Key-Value Coding mappings of properties for garage storage.
@objc(GSMappableObject)
public protocol MappableObject : NSObjectProtocol {
    
    @objc static var objectMapping: ObjectMapping { get }
}
