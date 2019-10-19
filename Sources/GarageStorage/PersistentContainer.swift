//
//  PersistentContainer.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/6/19.
//  Copyright © 2019 Wellframe. All rights reserved.
//

import Foundation
import CoreData

// TODO: This should be replaced with NSPersistentStoreDescription, once we require iOS 10 or later.
@objc(GSPersistentStoreDescription)
public class PersistentStoreDescription: NSObject {
    
    internal let url: URL
    internal var configuration: String?
    @objc public var type: String = NSSQLiteStoreType

    internal private(set) var options: [String : NSObject] = [:]
        
    @objc public func setOption(_ option: NSObject?, forKey key: String) {
        options[key] = option
    }

    @objc public init(url: URL) {
        self.url = url
    }
    
}

// TODO: This should be replaced with NSPersistentContainer, once we require iOS 10 or later.
internal class PersistentContainer {

    internal private(set) var viewContext: NSManagedObjectContext
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    var persistentStoreDescriptions: [PersistentStoreDescription] = []
    
    internal init(name: String, managedObjectModel: NSManagedObjectModel) {
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        self.viewContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
    }
    
    func loadPersistentStores(completionHandler block: (PersistentStoreDescription, Error?) -> Void) {
        var errors: [PersistentStoreDescription: Error] = [:]
        
        for description in persistentStoreDescriptions {
            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: description.type, configurationName: description.configuration, at: description.url, options: description.options)
            }
            catch {
                errors[description] = error
            }
        }
        
        for description in persistentStoreDescriptions {
            block(description, errors[description] ?? nil)
        }
    }
}
