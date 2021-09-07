//
//  GarageModel.swift
//  GarageStorage
//
//  Created by Brian Arnold on 10/18/19.
//  Copyright © 2015-2020 Wellframe. All rights reserved.
//

import CoreData

struct GarageModel {
    
    private func makeEntity(_ name: String) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = name
        return entity
    }

    private func makeAttribute(_ name: String, type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = true
        return attribute
    }

    func makeModel() -> NSManagedObjectModel {
        // Create the attributes
        let properties: [NSAttributeDescription] = [
            makeAttribute(CoreDataObject.Attribute.type, type: .stringAttributeType),
            makeAttribute(CoreDataObject.Attribute.identifier, type: .stringAttributeType),
            makeAttribute(CoreDataObject.Attribute.version, type: .integer16AttributeType),
            makeAttribute(CoreDataObject.Attribute.data, type: .stringAttributeType),
            makeAttribute(CoreDataObject.Attribute.creationDate, type: .dateAttributeType),
            makeAttribute(CoreDataObject.Attribute.modifiedDate, type: .dateAttributeType),
            makeAttribute(CoreDataObject.Attribute.syncStatus, type: .integer16AttributeType)
        ]
        
        // Create the entity
        let entity = makeEntity(CoreDataObject.entityName)
        entity.properties = properties
        
        let garageModel = NSManagedObjectModel()
        garageModel.entities = [entity]
        return garageModel
    }
    
}
