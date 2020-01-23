# GarageStorage

GarageStorage is designed to do two things:
- Simplify Core Data persistence, to store any kind of object
- Eliminate versioning Core Data data models, or the need to do xcdatamodel migrations

It does this at the expense of speed and robustness. In GarageStorage, there is only one type of Core Data Entity, and each referenced object is mapped to an instance of this object. References between objects are maintained, so you do get *some* of the graph features of Core Data. This library has been used in production apps, and has substantial unit tests, so although it is not especially robust, it is *robust-ish*.

#### What is a Garage?
The `Garage` is the main object that coordinates activity in Garage Storage. It's called a *Garage* because you can park pretty much anything in it, like, you know, your garage. The Garage handles the backing Core Data stack, as well as the saving and retrieving of data. You *park* objects in the Garage, and *retrieve* them later. Any object going into or coming out of the Garage must conform to the `Codable` protocol, and either the `Hashable` or  `Mappable` protocol. For Objective-C compatibility, the `MappableObject` protocol may be used instead. We'll get into the details on that later. For now, it's important to draw a distinction between how Garage Storage operates and how Core Data operates: Garage Storage stores a JSON representation of your objects in Core Data, as opposed to storing the objects themselves, as Core Data does. There are some implications to this (explained below), but the best part is that you can add whatever type of object you like to the Garage, whenever you like. You don't have to migrate data models or anything, just park whatever you want!

#### Getting Started
First, create a Garage:

```swift
let garage = Garage()
```
If you wish to specify the name of the store, have multiple Garage stores, or add configuration options to your persistent store, you may alternatively create a garage with a `PersistentStoreDescription`. A convenience class method `makePeristentStoreDescription(_)` with a store name can be used to keep this step as simple as possible. 

**Note**: When this library requires iOS 10 or later, this will be replaced with `NSPersistentStoreDescription`.

#### Objects in Swift
Any Swift type that is involved in being parked in a Garage must conform to `Codable`. The Swift compiler will take care of synthesizing of `CodingKeys`, `init(from:)` and `encode(to:)` methods, or alternatively, you can specify them manually, as you might for any `Codable` type.

For example, given a simple struct:
```swift
struct Address {
    var street: String
    var city: String
    var zip: String
}
```
In order to store this as a property of another object in GarageStorage, have it conform to Codable:
```swift
extension Address: Codable { }
```
In order to *park* this as a root type, have it conform to either the `Hashable`, or  `Mappable` protocol. Since this is a simple type,  `Hashable` is the way to go:
```swift
extension Address: Hashable { }
```
Reference types, such as classes, that have a unique *identity*, should conform to `Mappable`, and are usually root objects. This protocol conforms to `Codable` and is compatible with conforming to `Identifiable` where `ID == String`. For example:

```swift
class Person: Mappable {
    // Map the identifier to a preferred property, if desired.
    var id: String { name }
    
    var name: String = ""
    var address: Address?
    var age: Int = 0
    var birthdate: Date = Date()
    var importantDates: [Date] = []
    var siblings: [Person] = []
    var brother: Person?
}
```

#### Objects requiring Objective-C compatibility
Any Objective-C-compatible object that is involved in being parked in a Garage must conform to `MappableObject`, instead of `Mappable` or `Codable`. And, as such compatible objects go, it must include the `@objc` keyword in all the right places, and subclass from `NSObject`. A `MappableObject` must implement the property getter  `@objc static var objectMapping: ObjectMapping { get }`. The `@objc` keyword plays a special role for the properties, in that Objective-C *Key-Value Coding* will be used to encode and decode them.

An object mapping specifies the properties on the object you wish to have parked (similar to `CodingKeys`). For example, I may have a Person object that looks like this:
```swift 
@objc class Person : NSObject, MappableObject {

    @objc var name: String = ""
    @objc var ssn: String = ""
}
```
You can get a base mapping for a class with: `ObjectMapping(for: self)` The mapping for the Person object might look like this:
```swift 
static var objectMapping: ObjectMapping {
    let mapping = ObjectMapping(for: self)
    mapping.addMappings(["name", "ssn"])
    return mapping
}
```
Once you have set the properties to map, you should set the identifying attribute, if it is a top-level object (See note about *Identifying Attributes* below). This property represents a unique identifier for your object, and it must be a String. For example, in the `objectMapping` method, add this before the return statement:

```swift 
    mapping.identifyingAttribute = "ssn"
```
Under the hood, the object's properties gets serialized to JSON, and the types of properties supported in Objective-C are limited, so don't try to park any tricky properties. The types supported include:
* Strings (`NSString`)
* Numbers (both `NSNumber` and primitives such as `Int`)
* Dates (`NSDate`)
* Objects conforming to `MappableObject`
* Dictionaries (`NSDictionary`) where keys are Strings, and values are among the supported types
* Arrays (`NSArray`) of the supported types

#### Parking Objects
Parking an object puts a snapshot of that object into the Garage. As mentioned, this is different from pure Core Data, where changes to your `NSManagedObjects` are directly reflected in the managed object context. With GarageStorage, since you're parking a snapshot, *you will need to park that object any time you want changes you've made to it to be reflected/persisted.* You can park the same object multiple times, which will update the existing object of that same type and identifier. To park a `Mappable` object in the garage, call:
```swift
    try garage.park(myPerson)
```
You may also park an array of objects in the garage (assuming all are `Mappable` and of the same type):
```swift
    try garage.parkAll([myBrother, mySister, myMom, myDad])
```
**For Objective-C**: The `MappableObject` equivalent method names are `parkObject(_)` and `parkAllObjects(_)`.

#### Retrieving Objects
To retrieve a specific object from the garage, you must specify its `type` and its `identifier`.
```swift
    let person = try garage.retrieve(Person.self, identifier: "123-45-6789")
```
You can also retrieve all objects for a given type:
```swift
    let allPeople = try garage.retrieveAll(Person.self)
```

**For Objective-C**: The `MappableObject` equivalent method names are `retrieveObject(_:identifier:)` and `retrieveAllObjects(_)`.

#### Deleting Objects
To delete an object from the Garage, you must specify the mappable object that was originally parked:
```swift
    try garage.delete(myPerson)
```
To delete all objects of a given type, use:
```swift
    garage.deleteAll(Person.self)
```
You can also delete all the objects from the Garage:
```swift
    garage.deleteAllObjects()
```

**For Objective-C**: the `MappableObject` equivalent method names are `deleteObject(_)` and `deleteAllObjects(_)`.

#### Sync Status
If you want to track the sync status of an object (with respect to say, a web service), you can implement the `Syncable` protocol, which requires that your object has a sync status property:
```swift
    var syncStatus: SyncStatus = .undetermined
```
Garage Storage provides the following sync status options:
```swift
    .undetermined
    .notSynced
    .syncing
    .synced 
```
Objects conforming to `Syncable` will have their sync status automatically set when they are parked in the Garage. However, you can also manually set the sync status:

```swift
    try garage.setSyncStatus(.syncing, for: myPerson)
    try garage.setSyncStatus(.synced, for: [myBrother, mySister, myMom, myDad])
```

You can also query the sync status of an object in the garage:
```swift
    let status = try garage.syncStatus(for: myPerson)
```

And most importantly, you can retrieve objects from the garage based on sync status:
```swift
    let notSynced: [Person] = try garage.retrieveAll(withStatus: .notSynced)
```

**For Objective-C**: the `MappableObject` method name is `retrieveObjects(withStatus:)`.

#### Saving The Store
Parking, deleting, or modifying the sync status of objects may not, in and of themselves, persist their changes to disk. However, `isAutosaveEnabled` is set to `true` by default in a `Garage`. This means that any operation that modifies the garage will also trigger a save of the garage. If you don't want this enabled, then set `isAutosaveEnabled` to `false`, and then explicitly save the Garage by calling:
```swift
    garage.save()
```

##### A Note about Identifying Objects
It's worth going into a bit of detail about how *identifying* objects work so you can best leverage (read: account for the quirks of) Garage Storage. Any object with an identifying attribute will be stored as its own separate object in the Garage, and each *reference* will point back to that object. This is great if you have a bunch of objects that reference each other, as the graph is properly maintained in the garage, so a change to one object will be "seen" by the other objects pointing to it. This also enables you to *retrieve* any top-level object by its identifier.

Alternatively, you don't have to set an identifying attribute on your object. If you do this on a top level object (i.e. one that you call `park()` on directly), the `hashValue` (or in the case of Objective-C, the MappableObject's JSON representation of the object) is used as its identifier. If you park unidentified *Object A*, then change one of its properties, and park *Object A* again, you'll now have *two copies* of *Object A* in the Garage, as its JSON mapping, and hence identifier, would have changed. If *Object A* had had an identifier, then *Object A* would have just been updated when it was parked the second time. It's considered best practice for top-level objects to have an identifying attribute (so, use `Mappable` in Swift, which requires an identifier, or `MappableObject` with an `ObjectMapping identifyingAttribute` for Objective-C compatibiity).

However, if the object is a *property* of a top-level object, you may want to leave it unidentified (or *anonymous*), especially if it doesn't have an attribute that's logically its identifier. An anonymous object is serialized as in-line JSON, instead of having a separate underlying core data object, as an identified object would. This means you won't be able to retrieve anonymous sub-objects by type directly. To make an object anonymous, it only needs to conform to `Codable` (or in the case of Objective-C, a `MappableObject` without an `identifyingAttribute`). 

The primary advantages of unidentified objects are twofold: First, you don't have to arbitrarily pick an identifier if your object doesn't naturally have one. Second, there's an underlying difference in how deletion is handled. When you delete an object from the Garage, only the top level `Mappable` is deleted. If it points to other `Mappable` objects, those are not deleted. Garage Storage doesn't monitor retain counts on objects, so for safety, only the object specified is removed. However, since unidentified objects are part of the top level object's JSON, and are not separate underlying objects, they will be removed. It's considered best practice for sub objects to be unidentified unless there is a compelling reason otherwise.

### Handling errors

Most of the public APIs in GarageStorage may throw an error. The error may come from Core Data itself, or from GarageStorage detecting a problem. The error will always be of type `NSError`. If an error is thrown, then return values, if any, will be `NULL` or `NO` (false) if the caller is in Objective-C.

Since normal code flow should never rely on errors being thrown, the only kinds of errors GarageStorage throws are programmer errors (such as a missing identifying attribute for a `MappableObject`, or attempting to park a NULL Objective-C object), or problems associated with memory corruption (failure to decode JSON, for example).

Therefore, for normal operations, it is generally appropriate to use `try!`  for calls that are not expected to fail. Only use `try?` if you're sure that the failure can be overcome by checking the returned value for `nil` (or `NULL` in Objective-C). 
Or, if you use diagnostic logging for detecting catastrophic failures in your app, or have some other reason to look for or respond to specific kinds of errors, the usual do/catch is recommended:

```swift
do {
    try park(myPerson)
}
catch let error as NSError {
    print("Fatal error trying to park \(myPerson), error: \(error.localizedDescription)")
    // optionally call throw error, here, if you want to pass it on after logging it
}
```
If for some specific reason you need to distinguish errors thrown from GarageStorage instead of Core Data, you can check the error's domain for `Garage.errorDomain`.

### Migrating from Objective-C to Swift

See see details in [Migrating to Swift](MigratingToSwift.md).

### Conclusion

There's more that the Garage can do, including the ability to use your own `DataEncryptable` (which is useful for encryption purposes), so poke around for more info. Feature/Pull requests are always welcome. Have fun!
