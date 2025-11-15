//
//  BootstrapTests.swift
//  GarageStorageTests
//
//  Created by Brian Arnold on 9/12/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Testing
import Foundation

// We are testing Core Data, which creates files in the Documents directory.
// Fresh simulator builds may not have this directory?
@Suite("Bootstrap Tests")
struct BootstrapTests {
 
    // Ensure that the Documents directory exists (first time in Simulator)
    init() {
        TestSetup.classSetUp()
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last!
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try! fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    @Test("Documents directory exists")
    func bootstrap() async throws {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last!
        #expect(fileManager.fileExists(atPath: documentsDirectory.path))
    }
}
