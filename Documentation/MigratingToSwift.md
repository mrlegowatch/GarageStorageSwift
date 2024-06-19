#  Migrating from Objective-C to Swift

If you start using GarageStorage with Objective-C-compatible types, and subsequently want to fully migrate your code to Swift, follow the tips in here to make the migration as painless as possible. If your risk tolerance is low, consider starting with in-place migration. If your risk tolerance is higher, consider going straight to replacement migration.

It is recommended that you implement unit tests for your existing code, before engaging in a migration. This will help ensure that your new Swift code behaves as expected, and that your migration code is working correctly.

## For in-place migration

### Give the new Swift type the exact same properties initially

Initially use the exact same property names and types as from the Objective-C version. The name of the Swift type may be the same, or different, but the new type should retain the exact same Objective-C class name. If you were using a prefix, remove the prefix for the Swift name (prefixes are only valuable in languages that lack namespaces). Map the names using `NS_SWIFT_NAME(<swift-name>)` in Objective-C, or `@objc(<objective-c-name>)` in Swift.

If you use the exact same properties and Objective- C class name initially, and retain the dependency on MappableObject, the new type will be able to perform an automatic in-place migration from the old type to the new one, without any additional code.

If you adopt Codable or Mappable instead of MappableObject, or if the underlying types are MappableObjects that in turn require migration, you must add a manual migration to the new Swift type, by making a call to the Garage `migrateAll(from:to:)` method. The migration will map top-level instances of the old Objective-C class name to the new Swift type name, and autosave when finished. This will also remove some of the gunk associated with the Objective-C-compatible implementation of GarageStorage, shrinking storage requirements, and increasing *Swift-y* `Codable` compatibility down the road.

If you decide later to change the property names or types, you may subsequently introduce one or more sets of `CodingKeys`, along with `init(from:)` and `encode(to:)` methods, to handle conditionally mapping from old property names and types (and hierarchies, even) to new ones. You might find that it's easier to do this *after* migrating, though.

### Convert identifiable objects to Mappable or Codable

Once you have a MappableObject implementation in Swift, the next step is to convert it to a Codable implementation.

Change any `MappableObject` that assigns an `identifyingAttribute` to `Mappable`. Keep it as a `class`. If it's being used and stored as a *reference*, it probably ought to remain a *reference type*. Move the `identifyingAttribute` to the `id` property of the class, or map it to the `id` property. Note: if it does not assign an `identifyingAttribute`, change the class to conform to `Codable`, instead of to Mappable (see next section).

Change any `MappableObject` that lacks an `identifyingAttribute` to a `struct` conforming to `Codable`. It is already being stored anonymously, as if it were a *value type*, so it might as well be a `struct`. Conform to `Hashable` if it's used as both an anonymous object and a root object.

When converting such a type to Codable, any properties of other `MappableObjects` that reference that type should add the `@Migratable` property wrapper, to aid with in-place migration from `MappableObject` to `Codable`. By adding the property wrapper, you ensure that the in-line serialized data will migrate correctly to the new Swift type. You do not need to use this property wrapper for *identifiable* (e.g., `Mappable`) types, as they were previously stored as references, and reference migration is automatic.

## For replacement migration

For some, it may be more desirable to just cut to the chase, and create a more idiomatic Swift-only type to replace an existing type from the get-go. In this case, you'll need to implement your own migrate function. Here are some tips to help things go more smoothly.

### Map from the old type to a new type

If you used an Objective-C prefix for the old type (for example `MCOldType`), implement just the required data properties in Swift, each with `@objc` annotation, and declare the type `@objc(MCOldType) class LegacyObjCOldType: MappableObject`. In the new type, name it however you like. Then implement a function or Garage extension method to create the new type from the old type. 

Let's walk through an example of an existing type that has an identifying property which is not used for park or retrieve (for example, uniquely identifying it in a database). In this example, an array of items is stored in Garage Storage using `parkAllObjects` and accessed using `retrieveAllObjects`.

An Objective-C declaration might look like this:

```objective-c
NS_SWIFT_NAME(Item)
@interface WFItem : NSObject <MappableObject>

@property (nonatomic, assign) NSInteger itemID;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSDate *dateCreated;

@end
```

The implementation might look like this:

```objective-c
@implementation(WFItem)

- (ObjectMapping *)objectMapping {
    ObjectMapping *mapping = [ObjectMapping mappingForClass:[self class]];
    [mapping addMappings:@[@"itemID", @"label", @"dateCreated"]];
    return mapping;
}
    
@end
```

For Swift, you might implement a slightly more idiomatic Swift version like this:

```swift
public class Item: Codable, Identifiable {
    public private(set) var id: Int
    public private(set) var label: String
    public private(set) var dateCreated: Date
    
    init(id: Int, label: String, dateCreated: Date) {
        self.id = id
        self.label = label
        self.dateCreated = dateCreated
    }
}
```

To support migration to the new type, you might prefer to provide an in-place converted version of the old type, instead of leaving the old type around, like this:

```swift
@objc(WFItem)
class LegacyObjCItem: NSObject, MappableObject {
    @objc var itemID: Int = 0
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

Notes:
 * The old type is named `LegacyObjCItem` so that the new Swift class can use the same Swift class name as the old class (e.g., `Item`, if desired, as this example shows), and is declared as `@objc(WFItem)` so that its Objective-C class name matches the old class name that will be found in storage.
 * An override of `init()` may be required to ensure that the Garage can create instances of this class.
 * All properties must have the `@objc` prefix to ensure that the Garage can access them using Key-Value Coding.

You can then implement a migration function that converts the old type to the new type, like this:

```swift
extension Garage {
    
    func migrateAllItems() throws {
        let oldItems = try retrieveAllObjects(LegacyObjCItem.self)
        guard !oldItems.isEmpty else { return }
     
        let newItems = oldItems.map { oldItem in
            Item(id: oldItem.ItemID, title: oldItem.title, dateCreated: oldItem.dateCreated)
        }
        try parkAll(newItems)
        deleteAllObjects(LegacyObjCItem.self)
    }
}
```

Notes:
 * The `retrieveAllObjects` is passed in `LegacyObjCItem.self`, but because Garage Storage is actually using the Objective-C class name `WFItem` under the hood, the existing stored data will be retrieved into instances of the `LegacyObjCItem` type.
 * The init method supplied in the new Item type is used to create new instances of the Item type.

### Migrating SyncableObject may require skipping its syncStatus property

If you are migrating a type that was previously conforming to the `SyncableObject` protocol, chances are good that its `syncStatus` property was not being included in `ObjectMapping`'s `mappings`. If that's the case, the migrated Swift type must also skip this property (if you are converting in-place), by adding CodingKeys that only include the former `ObjectMapping`'s `mappings`, at least during the time of migration.

### Keep migration code in place only for a specified period of time

Each time you migrate your code and add a call to `migrateAll(from:to:)` (or your own version) before creating or retrieving any of your new Swift types, your users will need bake time with that change, to ensure that their core data stores have been migrated. After the migration code has been deployed for a period of time, and you are confident that migration is no longer necessary, you may remove this call, along with any `@Migratable` property wrappers, and any CodingKeys that were previously skipping syncStatus.
