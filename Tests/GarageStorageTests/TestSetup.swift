//
//  TestSetup.swift
//  GarageStorageTests
//
//  Created by Bob Gilmore on 5/10/21.
//

import Foundation

@objc public class TestSetup: NSObject {
    
    static var timeZone = TimeZone(identifier: "UTC")!
    
    static func classSetUp() {
        // Set the test time zone to UTC so that tests can compare with hardcoded UTC dates
        NSTimeZone.default = TestSetup.timeZone
    }
    
}

/// Use this test store name for Garage Storage tests.
let testStoreName = "GarageStorageTests"
