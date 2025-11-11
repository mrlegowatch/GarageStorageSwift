# Getting Started

To start working with GarageStorage, you create a `Garage`, then start parking and retrieving `Codable` data objects with it. It's that easy.

@Metadata {
    @PageColor(blue)
}

### How does a Garage work?

Anything going into or coming out of the Garage must conform to the `Codable` protocol. Top-level objects—that is, anything stored or retrieved directly— must also conform to either the `Hashable` protocol, or `Identifiable` protocol for uniquely identified top-level objects. A top-level object can be stored or retrieved using its unique `id`, or as part of an array of the same type.

It's important to draw a distinction between how Garage Storage operates and how Core Data operates: Garage Storage stores a JSON representation of your objects in Core Data, as opposed to storing the objects themselves, as Core Data does. There are some implications to this (explained below), but the best part is that you can add whatever type of object you like to the Garage, whenever you like. You don't have to migrate data models or anything, just park whatever you want!

### Creating a Garage

First, create a Garage:

```swift
let garage = Garage(named: "MyGarage")
```
If you need to customize the Core Data persistent store description, or handle errors loading the persistent store, you may alternatively create a garage with a `NSPersistentStoreDescription`, and manually load the persistent stores with a completion handler. A convenience class method `makePersistentStoreDescription(_)` with a store name can be used to keep this step as simple as possible. 

```swift
let description = Garage.makePersistentStoreDescription("MyGarage.sqlite")
// ... customize the store description
let garage = Garage(with: [description])
garage.loadPersistentStores { (_, error) in
    // ... handle the error
}
```

### Creating an object that can be stored in a Garage

Any Swift type that is involved in being parked in a Garage must conform to `Codable`. The Swift compiler will take care of synthesizing of `CodingKeys`, `init(from:)` and `encode(to:)` methods; alternatively, you can specify them manually, as you might for any `Codable` type.

For example, let's work with the following data object declaration:
```swift
struct Address {
    var street: String
    var city: String
    var zip: String
}
```
In order to store this in GarageStorage, conform it to Codable:
```swift
extension Address: Codable { }
```
If this type is only embedded in another object, then no additional work is required. However, in order to *park* this object as a top-level object (that is, directly using `park(_:)` or `parkAll(_:)`), it must additionally conform to the either the `Hashable` protocol or the `Identifiable` protocol (see next section). 

### What making an object Hashable does

In the above case, an Address is going to be stored as an embedded object. However, if we wanted to also store Address at the top level, for example as part of an array of "known" or "recent" addresses to choose from, we might conform this type to `Hashable`.  In this example, since the properties are all `Hashable`, the type may simply be declared to also have `Hashable` conformance:
```
extension Address: Hashable { }
```

If many references of this type with the same value are being embedded (e.g., multiple objects embedding the exact same `Address`), then specifying `Hashable` conformance will also help reduce the overall storage footprint, by storing the value only once.

### Creating a top-level object

As indicated in the previous section, a top-level object or elements of a top-level array need only conform to `Hashable`. They may be either value or reference types.

Standalone top-level objects—that is, root objects that are parked directly using `park()`—often require being uniquely identified in the Garage, and are often reference types, such as classes. This is supported through the `Identifiable` protocol. The only requirement for `Identifiable` is that its ID conform to `LosslessStringConvertible`. For example:

```swift
class Person: Codable, Identifiable {
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

Note that in the above example, another property, `name`, is mapped to the `id` property, and the `id` property itself is synthesized (i.e., not stored directly with the object). In general, this is how you might map an existing unique identifier of any type (such as from a server or remote storage), to the one required for the Garage.

Note: Many Swift types support the `LosslessStringConvertible` protocol requirement for `Identifiable`'s `ID`, including `String` (of course), `Int`, `Double`, etc. However, `UUID` does not support this directly. To add conformance for `UUID`, implement the following in your project:

```swift
import Foundation

extension UUID: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(uuidString: description)
    }

    public var description: String { self.uuidString }
}
```

### Parking Objects
Parking an object puts a snapshot of that object into the Garage. As mentioned earlier, this is different from pure Core Data, where changes to your `NSManagedObjects` are directly reflected in the managed object context. With GarageStorage, since you're parking a snapshot, *you will need to park that object any time you want changes you've made to it to be reflected/persisted.* You can park the same object multiple times, which will update the existing object of that same type and identifier. To park an `Identifiable` object in the garage, call:
```swift
    try garage.park(myPerson)
```
You may also park an array of objects in the garage (assuming all are `Codable` and `Hashable` or `Identifiable` and of the same type):
```swift
    try garage.parkAll([myBrother, mySister, myMom, myDad])
```

### Retrieving Objects
To retrieve a specific object from the garage, you must specify its `type` and its `identifier`.
```swift
    let person = try garage.retrieve(Person.self, identifier: "Joan Smith")
```
You can also retrieve all objects for a given type:
```swift
    let allPeople = try garage.retrieveAll(Person.self)
```

### Deleting Objects
To delete an object from the Garage, you must specify the Identifiable object that was originally parked:
```swift
    try garage.delete(myPerson)
```
To delete all objects of a given type, use:
```swift
    garage.deleteAll(Person.self)
```
You can also delete all objects from the Garage:
```swift
    garage.deleteAllObjects()
```

### Saving The Store

Parking, deleting, or modifying objects will automatically persist their changes to disk by default, because `isAutosaveEnabled` is set to `true` by default in a `Garage`. This means that any operation that modifies the garage will also trigger a save of the garage. If you don't want this enabled, then set `isAutosaveEnabled` to `false`, and then explicitly save the Garage by calling:
```swift
    garage.save()
```

### A Note about Identifying Objects
It's worth going into a bit of detail about how *identified*, *unidentified*, and *anonymous* types work with respect to *top-level* vs. *embedded* objects, so you can best leverage (read: account for the quirks of) Garage Storage. 

Any Identifiable object with an *id* attribute will be stored as its own separate object in the Garage, and each *reference* will point back to that object. This is great if you have a bunch of objects that reference each other, as the graph is properly maintained in the garage, so a change to one object will be "seen" by the other objects pointing to it. This also enables you to *retrieve* any top-level object by its identifier.

If you instead conform the type to `Hashable` then there is still only one instance or value of its type in storage; however, it is now an *unidentified* object. If you park an unidentified *Object A*, then change one of its properties, and park *Object A* again, you'll now have *two different versions* of *Object A* in the Garage, as its hash value has changed. If *Object A* had had an identifier, then *Object A* would have just been updated when it was parked the second time. Therefore, it's considered a best practice for top-level reference types to conform to `Identifiable` so that they always have an id attribute, and are treated as the same instance in storage.

However, if the object is an embedded *property* of a top-level object, you may want to leave it *unidentified*, especially if it doesn't have an attribute that's logically its identifier, or if it is a value type. If the object object does not conform to `Hashable`, then it is completely *anonymous*: it is serialized as in-line JSON, instead of having a separate underlying core data object, as an `Identifiable` or `Hashable` object would. This means you won't be able to retrieve anonymous sub-objects by type directly. To make an object completely anonymous, it only needs to conform to `Codable`. 

The primary advantages of *anonymous* objects are twofold: First, you don't have to arbitrarily pick an identifier if your object doesn't naturally have one. Second, there's an underlying difference in how deletion is handled. When you delete an object from the Garage, only the top level `Identifiable` is deleted. If it references other `Identifiable` or `Hashable` objects, those are not deleted. Garage Storage doesn't monitor retain counts on objects, so for safety, only the object specified is removed. However, since *anonymous* objects are part of the top level object's JSON, and are not separate underlying objects, they will be removed. It's considered best practice for embedded objects to be *anonymous*, unless there is a compelling reason otherwise, such as to reduce overall storage footprint.

### Handling errors

Most of the public APIs in GarageStorage may throw an error. The error may come from Core Data itself, from encoding or decoding detecting a problem, or from GarageStorage detecting a problem.

Since normal code flow should never rely on errors being thrown, the only kinds of errors GarageStorage throws are programmer errors, or memory or data corruption (failure to decode JSON, for example).

Therefore, for normal operations, it is generally appropriate to use `try!` for calls that are not expected to fail. Only use `try?` if you're sure that the failure can be overcome by checking the returned value for `nil`. Or, if you use diagnostic logging for detecting catastrophic failures in your app, or have some other reason to look for or respond to specific kinds of errors, the usual do/catch is recommended:

```swift
do {
    try park(myPerson)
}
catch {
    // log or re-throw the error
}
```
If for some specific reason you need to distinguish errors thrown from GarageStorage instead of Core Data, you can check the error's domain for `Garage.errorDomain`.

## Conclusion

There's more that the Garage can do, including the ability to use your own `DataEncryptionDelegate` (which you can specify for encrypting your data), so poke around for more. Feature/Pull requests are always welcome. Have fun!
