# Working with Objective-C

This document covers the historical context of how Garage Storage works with Objective-C, from before Swift compatibility was added. It is primarily intended for code that originated in Objective-C, such as a data class declared in a header and source file, or working with a Garage and its stored objects directly from Objective-C code.

It is not recommended that you start with Objective-C types in Garage Storage. If you are using Garage Storage primarily in Swift, and only require limited Objective-C compatibility with the data classes outside of how they are stored, you can skip this document.

### Objects requiring Objective-C compatibility
Any Objective-C-compatible object that is involved in being parked in a Garage from Objective-C code must conform to `MappableObject`, instead of `Mappable` or `Codable`. The object class may be declared in Swift. It must additionally subclass from `NSObject` and implement the property getter `@objc static var objectMapping: ObjectMapping { get }`. 

The `@objc` keyword plays a special role for the properties, in that Objective-C *Key-Value Coding* will be used to encode and decode them.

An object mapping specifies the properties on the object you wish to have parked (similar to `CodingKeys`). For example, I may have a Person object that looks like this:
```swift
class Person : NSObject, MappableObject {
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
Under the hood, the object's properties gets serialized to JSON, and the types of properties supported in Objective-C are limited, so don't try to park any tricky properties, without first wrapping them in MappableObject. The types supported include:
* Strings (`NSString`)
* Numbers (both `NSNumber` and primitives such as `Int`)
* Dates (`NSDate`)
* Dictionaries (`NSDictionary`) where keys are Strings, and values are among the supported types
* Arrays (`NSArray`) of the supported types
* Objects conforming to `MappableObject`

### Parking, Retrieving, and Deleting Objects

The Garage methods for parking, retrieving and deleting MappableObject objects are the same as for Swift Codable, with the suffix `Object` added:

* The `MappableObject` equivalent to `park<T>(_)` and `parkAll<T>(_)` are `parkObject(_)` and `parkAllObjects(_)`.
* The `MappableObject` equivalent to `retrieve<T>(_)` and `retrieveAll<T>(_)` are `retrieveObject(_:identifier:)` and `retrieveAllObjects(_)`.
* The `MappableObject` equivalent to `delete<T>(_)` and `deleteAll<T>(_)` are `deleteObject(_)` and `deleteAllObjects(_)`.
* The `MappableObject` equivalent to `retrieve<T>(withStatus:)` is `retrieveObjects(withStatus:)`.

### Working with an identifier for top-level unique objects

To specify the identifier, conform to `MappableObject` and assign the `ObjectMapping identifyingAttribute`.

In the case of Objective-C, the MappableObject's JSON representation of the object) is used as its identifier, when an identifier is specified. A `MappableObject` without an `identifyingAttribute` will otherwise be anonymous (a dependent object of a root reference object, or an object in an array).

### Handling errors

If an error is thrown, then return values, if any, will be `NULL` or `NO` (false) if the caller is in Objective-C. For example, retrieveObject will return NULL if the object is not found, along with an error indicating such.

## Migrating from Objective-C to Swift

Over time you may find yourself converting Objective-C-compatible types entirely to Swift. To make these new types more idiomatic in Swift, and to handle migration, please see [Migrating to Swift](MigratingToSwift.md).
