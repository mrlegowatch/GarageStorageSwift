//
//  CustomDataEncryptor.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 10/4/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import GarageStorage

// Sample custom string encryptor: just reverses the characters, tee hee.
final class CustomDataEncryptor: NSObject, DataEncryptionDelegate {
 
    func encrypt(_ data: Data) throws -> String {
        let string = data.base64EncodedString(options: [])
        return String(string.reversed())
    }
    
    func decrypt(_ string: String) throws -> Data {
        let reversed = String(string.reversed())
        return Data(base64Encoded: reversed)!
    }
}
