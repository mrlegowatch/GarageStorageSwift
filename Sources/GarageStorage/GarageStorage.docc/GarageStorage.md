# ``GarageStorage``

Store any kind of object in Core Data, without a data model.

@Metadata {
    @PageColor(blue)
}

## Overview

GarageStorage is designed to do two things:
- Simplify Core Data persistence, to store any kind of object, and
- Eliminate versioning Core Data data models, or the need to do xcdatamodel migrations.

### What is a Garage?

The ``Garage`` is the main object that coordinates activity in GarageStorage. It's called a *garage* because you can park pretty much anything in it, like, you know, a garage. The `Garage` handles the backing Core Data stack, as well as the saving and retrieving of data. You *park* objects in the `Garage`, and *retrieve* them later. 

Any object going into or coming out of the `Garage` must conform to the `Codable` protocol. If it's a top-level object, it must also conform to either the `Hashable` protocol, or GarageStorage's ``Mappable`` protocol. You can add whatever type of conforming object you like to the `Garage`, whenever you like. You don't have to migrate data models or anything, just park whatever you want!

## Topics

### Essentials

- <doc:GettingStarted>
- ``Garage``
- ``Mappable``

### Syncing objects

- ``Syncable``
- ``SyncStatus``

### Customizing Core Data

Some applications require customization of the Core Data persistent store. The `Garage` provides an optional initializer and separate loading function to allow for this.

- ``Garage/init(with:)``
- ``Garage/loadPersistentStores(completionHandler:)``

### Supporting encryption

- ``DataEncryptionDelegate``

### Working with references

- ``Swift/KeyedEncodingContainer``
- ``Swift/KeyedDecodingContainer``
