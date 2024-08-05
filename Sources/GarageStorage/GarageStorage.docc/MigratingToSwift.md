#  Migrating from Objective-C to Swift

When you're ready to migrate existing Objective-C-based GarageStorage code to Swift, follow the tips in here to make the migration as painless as possible. 

@Metadata {
    @PageColor(blue)
}

If your risk tolerance is low, consider starting with in-place migration. If your risk tolerance is higher, consider going straight to replacement migration.

It is strongly recommended that you implement unit tests for your existing code, before engaging in code conversion and data migration. This will help ensure that your new Swift code behaves as expected, and that your migration code is working correctly.

## For in-place migration

In-place migration is a good choice if you're risk-adverse, and you want to make small, incremental changes towards eventual full Swift conversion.

### Give the new Swift type the exact same properties initially

Initially use the exact same property names and types in Swift as from the Objective-C version. The name of the Swift type may be different, but the new type should retain the exact same Objective-C class name. If you were using a prefix, remove the prefix for the Swift name (prefixes are only valuable in languages that lack namespaces). Map the names using 
 - `NS_SWIFT_NAME(<swift-name>)` in Objective-C, or 
 - `@objc(<objective-c-name>)` in Swift.

If you use the exact same property names and value types, retain the same Objective- C class name, and retain the dependency on MappableObject, the new type will be able to perform an automatic in-place migration from the old type to the new one, without any additional code.

### Convert identifiable objects to Mappable or Codable

Once you have a `MappableObject` implementation in Swift, the next step is to convert it to a `Codable` implementation.

Change any `MappableObject` that assigns an `identifyingAttribute` to `Mappable`. If it's still being used as a *reference type*, it probably ought to remain as such, so keep it as a `class`. Move the `identifyingAttribute` to the `id` property of the class, or map the attribute to the `id` property.

Change any `MappableObject` that lacks an `identifyingAttribute` to a `struct` conforming to `Codable`. It is already being stored anonymously, as if it were a *value type*, so it might as well be a `struct`. Add conformance to `Hashable` if it's used as both an anonymous object and a root object, or if it has significant storage space requirements.

When converting a type to `Codable`, any properties of other `MappableObjects` that reference that type should add the `@Migratable` property wrapper, to aid with in-place migration from `MappableObject` to `Codable`. By adding the property wrapper, you ensure that the in-line serialized data will migrate correctly to the new Swift type. You do not need to use this property wrapper for *identifiable* (e.g., `Mappable`) types, as they were previously stored as references, and reference migration is automatic.

### Lightweight migration to the new type

Any new types that shed the old Objective-C compatible class name or that embrace Codable, may need perform a migration to the Swift type.

If your new type adopts `Codable` or `Mappable` instead of `MappableObject`, or if the underlying types were `MappableObject` that in turn require migration, you will need to perform migration to the new Swift type. The migration will map top-level instances of the old Objective-C class name to the new Swift type name, and autosave when finished. This will also remove some of the gunk associated with the Objective-C-compatible implementation of GarageStorage, shrinking storage requirements, and increasing *Swift-y* `Codable` compatibility down the road.

Two alternate methods are provided to perform lightweight conversion:
- ``Garage/migrateAll(from:to:)`` with the class type, if it is still implemented in the code base
- ``Garage/migrateAll(fromOldClassName:to:)`` with the old class name string, if it is not still implemented in the code base
 
For any types converted to `Codable`, if you decide later to change the property names or types, you may subsequently introduce one or more sets of `CodingKeys`, along with `init(from:)` and `encode(to:)` methods, to handle conditionally mapping from old property names and types (and hierarchies, even) to new ones. You might find that it's easier to do this *after* migrating, though.

## For replacement migration

At some point, you may want to make your Swift `MappableObject` implementation conform to more idiomatic ("natural") Swift, and migrate to a fully Swift-only implementation. Or, for those with higher risk tolerance, it might be more desirable to just cut to the chase, and convert directly to a more idiomatic Swift implementation from the get-go. In either case, you'll need to implement your own migrate function. Here are some tips to make things go more smoothly.

### Map from the old type to a new type

If you used an Objective-C prefix for the old type (for example `MCOldType`), implement just the required data properties in Swift, each with `@objc` annotation, and declare the type `@objc(MCOldType) class LegacyObjCOldType: MappableObject`. In the new type, name it however you like. Then implement a function or Garage extension method to create the new type from the old type. 

Let's walk through an example of an existing type that has an identifying property which is not used for park or retrieve (for example, uniquely identifying it in a database). In this example, an array of items is stored in Garage Storage using `parkAllObjects` and accessed using `retrieveAllObjects`.

An Objective-C declaration might look like this:

```objective-c
NS_SWIFT_NAME(Item)
@interface MCItem : NSObject <MappableObject>

@property (nonatomic, assign) NSString *itemID;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSDate *dateCreated;

@end
```

The implementation might look like this:

```objective-c
@implementation(MCItem)

- (ObjectMapping *)objectMapping {
    ObjectMapping *mapping = [ObjectMapping mappingForClass:[self class]];
    [mapping addMappings:@[@"itemID", @"label", @"dateCreated"]];
    return mapping;
}
    
@end
```

For Swift, you might implement a more idiomatic Swift version like this:

```swift
public class Item: Codable, Identifiable {
    public private(set) var id: String
    public private(set) var label: String
    public private(set) var dateCreated: Date
    
    init(id: String, label: String, dateCreated: Date) {
        self.id = id
        self.label = label
        self.dateCreated = dateCreated
    }
}
```

To support migration to the new type, you might prefer to provide an in-place converted version of the old type in Swift, instead of leaving the old type around, like this:

```swift
@objc(MCItem)
class LegacyObjCItem: NSObject, MappableObject {
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

Notes:
 * The old type is named `LegacyObjCItem` so that the new Swift class can use the same Swift class name as the old class (e.g., `Item`, as this example shows), and is declared as `@objc(MCItem)` so that its Objective-C class name still matches the old class name that will be found in storage.
 * An override of `init()` may be required to ensure that Garage Storage can create instances of this class.
 * All properties must have the `@objc` prefix to ensure that the Garage can access them using Key-Value Coding.

You can then implement a migration function that converts the old type to the new type, like this:

```swift
extension Garage {
    
    func migrateAllItems() throws {
        let oldItems = try retrieveAllObjects(LegacyObjCItem.self)
        guard !oldItems.isEmpty else { return }
     
        let newItems = oldItems.map { oldItem in
            Item(id: oldItem.itemID, title: oldItem.title, dateCreated: oldItem.dateCreated)
        }
        try parkAll(newItems)
        deleteAllObjects(LegacyObjCItem.self)
    }
}
```

Notes:
 * The `retrieveAllObjects` is passed in `LegacyObjCItem.self`, but because Garage Storage is actually using the Objective-C class name `MCItem` under the hood, the existing stored data will be retrieved into instances of the `LegacyObjCItem` type.
 * The `init()` method supplied in the new Item type is used to create new instances of the Item type.

### Migrating SyncableObject in-place may require skipping its syncStatus property

If you are migrating a type in-place that was previously conforming to the `SyncableObject` protocol, chances are good that its `syncStatus` property was not being included in `ObjectMapping`'s `mappings`. If that's the case, the migrated Swift type must skip this property, by adding `CodingKeys` that only include the previous `ObjectMapping`'s `mappings`, at least for the purpose of migration. Once migrated, it doesn't matter if the `syncStatus` is included or not in `CodingKeys`.

### Keep migration code in place only for a specified period of time

Each time you add a call to `migrateAll(from:to:)` (or your own custom version), your users will need bake time with that change, to ensure that their core data stores have been migrated. After time has passed, and you are confident that the migration is no longer necessary, you may remove this call, along with any `@Migratable` property wrappers, and so on.
