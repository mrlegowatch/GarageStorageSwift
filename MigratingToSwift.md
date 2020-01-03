#  Migrating from Objective-C to Swift

If you start using GarageStorage with Objective-C-compatible types, and susbequently migrate all of your code to Swift, here are some tips you can follow to make the migration as painless as possible.

### Give the new Swift type the same properties initially

Initially use the same property names and types as from the Objective-C version. The name of the Swift type may be the same, or different. If you were using a prefix, remove the prefix (it's not *Swift-y*, prefixes are only valuable in languages that lack namespaces). You can optionally map the names using NS_SWIFT_NAME(<swift-name>) in Objective-C, or @objc(<objective-c-name>) in Swift.

If you use the same property names initially, you will be able to perform an in-place migration from the old type to the new one. Migration is not automatic, however, because Objective-C and Swift type names subtly differ, even when you keep the the same type name in your source code. To peform a migration, make a call to the Garage  `migrateAll(from:to:)` method. The migration will map top-level instances of the old Objective-C class name to the new Swift type name, and autosave when finished. It will also remove some of the gunk associated with the Objective-C-compatible implementation of GarageStorage, shrinking storage requirements, and increasing *Swift-y* `Codable` compatibility down the road.

If you decide later to change the property names or types, you may subsequently introduce one or more sets of `CodingKeys`, along with `init(from:)` and `encode(to:)` methods, to handle mapping from old property names and types (and hierarchies, even) to new ones. You might find that it's easier to do this *after* migrating, though.

### Convert identifiable objects to Mappable

Change any `MappableObjects` with a `identifyingAttribute` to `Mappable`. Keep it as a `class`. If it's being used and stored as a *reference*, it ought to remain a *reference type*. Move the `identifyingAttribute` to the `id` property of the class.

### Convert anonymous objects to structs conforming to Codable

Convert any `MappableObject` that lacks an `identifyingAttribute` to a `struct` conforming to `Codable`. It is already being stored anonymously, as if it were a *value type*, so it might as well be a `struct`. Conform to `Hashable` if it's both anonymous and a root object.

When converting such a type, any properties of other objects that reference that type should add the `@Migratable` property wrapper, to aid with in-place migration. By adding the property wrapper, you ensure that the in-line serialized data will migrate correctly to the new Swift type. You do not need to use this property wrapper for *identifiable* (e.g., `Mappable`) types, as they were previously stored as references, and reference migration is automatic.

### Migrating SyncableObject may require skipping its syncStatus property

If you are migrating a type that was previously conforming to the `SyncableObject` protocol, chances are good that its `syncStatus` property was not being included in `ObjectMapping`'s `mappings`. If that's the case, the migrated Swift type must also skip this property, by adding CodingKeys that only include the former `ObjectMapping`'s `mappings`, at least during the time of migration.

### Keep migration code in place only for a specified period of time

Each time you migrate your code and add a call to  `migrateAll(from:to:)` before creating or retrieving any of your new Swift types, your users will need bake time with that change, to ensure that their core data stores are migrated. After the migration code has been deployed for a period of time, and you are confident that migration is no longer necessary, you may remove this call, along with any `@Migratable` property wrappers, and any CodingKeys that were previously skipping syncStatus.
