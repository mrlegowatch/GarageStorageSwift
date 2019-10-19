//
//  BootstrapTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/12/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import XCTest

import Foundation

// We are testing Core Data, which creates files in the Documents directory.
// Fresh simulator builds may not have this directory?
class BootstrapTests: XCTestCase {
 
    // Ensure that the Documents directory exists (first time in Simulator)
    override class func setUp() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last!
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try! fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func testABootstrap() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last!
        XCTAssertTrue(fileManager.fileExists(atPath: documentsDirectory.path))
    }
}
