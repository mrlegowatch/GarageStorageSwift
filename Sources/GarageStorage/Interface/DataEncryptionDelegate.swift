//
//  DataEncryptionDelegate.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/11/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

/// If your application requires data encryption, this protocol provides the relevant hooks for converting from unencrypted JSON`Data` to an encrypted `String` and back again. Implement this protocol and set the ``Garage/dataEncryptionDelegate`` property on the ``Garage`` to enable data encryption for stored objects.
@objc(GSDataEncryptionDelegate)
public protocol DataEncryptionDelegate: NSObjectProtocol {
    
    /// This is called when the Core Data object's underlying data is about to be stored. Provide an implementation that encrypts the JSON data to a string.
    @objc func encrypt(_ data: Data) throws -> String
    
    /// This is called when the Core Data object's underlying data is about to be accessed. Provide an implementation that decrypts the string to JSON data.
    @objc func decrypt(_ string: String) throws -> Data
    
}
