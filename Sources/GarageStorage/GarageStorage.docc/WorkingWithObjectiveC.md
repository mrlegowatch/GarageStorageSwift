# Working with Objective-C

GarageStorage provides optional support for working with a `Garage` from Objective-C, and parking and retrieving Objective-C data classes.

@Metadata {
    @PageColor(blue)
}

It is not recommended that you start with Objective-C types in Garage Storage. If you are using Garage Storage primarily in Swift, and only require limited Objective-C compatibility with your data classes, separate from how they are stored, then you can skip this article.

### Objects requiring Objective-C compatibility
Any Objective-C-compatible object that is involved in being parked in a Garage from Objective-C code must conform to `MappableObject`, instead of `Mappable`, `Hashable`, or `Codable`. It must additionally subclass from `NSObject` and implement the `ObjectMapping` property getter. Garage Storage types in Objective-C are prefixed with "GS".

For example, in Objective-C:

```objective-c
NS_SWIFT_NAME(Item)
@interface MCItem : NSObject <GSMappableObject>

@property (nonatomic, assign) NSString *itemID;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSDate *dateCreated;

@end
```

The implementation might look like this:

```objective-c
@implementation(MCItem)

- (GSObjectMapping *)objectMapping {
    GSObjectMapping *mapping = [GSObjectMapping mappingForClass:[self class]];
    [mapping addMappings:@[@"itemID", @"label", @"dateCreated"]];
    return mapping;
}
    
@end
```

It's also possible to declare the same class in Swift with Objective-C compatibility, like this:

```swift
@objc(MCItem)
class Item: NSObject, MappableObject {
    @objc var itemID: String = ""
    @objc var label: String = ""
    @objc var dateCreated: Date = Date()
    
    public override init() { super.init() }

    public class var objectMapping: ObjectMapping {
        let mapping = ObjectMapping.mapping(for: self)
        mapping.addMappings(["itemID", "label", "dateCreated"])
        return mapping
    }
}
```
The `@objc` keyword plays a special role for the properties, in that Objective-C *Key-Value Coding* will be used to encode and decode them. The `ObjectMapping` specifies the properties on the object you wish to have parked (similar to `CodingKeys`). The `init` override ensures that it can be found and instantiated by Garage Storage at runtime.

Once you have set the properties to map, if it is a top-level object, you should set the `identifyingAttribute` (See note about *Identifying Attributes* in <doc:GettingStarted>). This property represents a unique identifier for your object, and it must be a String. It must also be specified in the mappings.

```swift
    public class var objectMapping: ObjectMapping {
        let mapping = ObjectMapping.mapping(for: self)
        mapping.addMappings(["itemID", "label", "dateCreated"])
        mapping.identifyingAttribute = "itemID"
        return mapping
    }
```

Under the hood, the object's properties gets serialized to JSON, and the types of properties supported in Objective-C are limited, so don't try to park any tricky properties, without first wrapping them in a `MappableObject`. The types supported include:
* Strings (`NSString`)
* Numbers (both `NSNumber` and associated primitives such as `int`, `double`, and `bool`)
* Dates (`NSDate`)
* Dictionaries (`NSDictionary`) where keys are NSStrings, and values are among the supported types
* Arrays (`NSArray`) of the supported types
* Objects conforming to `GSMappableObject`

### Parking, Retrieving, and Deleting Objects

The Garage methods for parking, retrieving and deleting MappableObject objects are the same as for Swift Codable, with the suffix `Object` added:

* `parkObject(_)` and `parkAllObjects(_)`
* `retrieveObject(_:identifier:)` and `retrieveAllObjects(_)`
* `deleteObject(_)` and `deleteAllObjects(_)`
* `retrieveObjects(withStatus:)`

### Working with an identifier for top-level unique objects

To specify the identifier, conform to `MappableObject` and assign the `ObjectMapping identifyingAttribute`. A `MappableObject` without an `identifyingAttribute` will otherwise be anonymous (an embedded object in a top-level object, or an object in an array). For more details, see *Identifying Attributes* in <doc:GettingStarted>.

### Handling errors

If an error is thrown, then return values, if any, will be `NULL` or `NO` (false) if the caller is in Objective-C. For example, retrieveObject will return NULL if the object is not found, along with an error indicating such.

## Migrating from Objective-C to Swift

Over time you may desire to migrate all of your remaining Objective-C-compatible types entirely to Swift. To make these new types more idiomatic in Swift, and handle migration, please see <doc:MigratingToSwift>).
