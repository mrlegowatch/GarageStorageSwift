# GarageStorage

## Overview
GarageStorage is designed to do two things:
- Simplify Core Data persistence, to store any kind of object
- Eliminate versioning Core Data data models, or the need to do xcdatamodel migrations

It does this at the expense of speed and robustness. In GarageStorage, there is only one type of Core Data Entity, and each referenced object is mapped to an instance of this object. References between objects are maintained, so you do get *some* of the graph features of Core Data. This library has been used in production apps, and has substantial unit tests, so although it is not especially robust, it is *robust-ish*.

### What is a Garage?
The `Garage` is the main object that coordinates activity in Garage Storage. It's called a *Garage* because you can park pretty much anything in it, like, you know, your garage. The Garage handles the backing Core Data stack, as well as the saving and retrieving of data. You *park* objects in the Garage, and *retrieve* them later. Any object going into or coming out of the Garage must conform to the `Codable` protocol, and either the `Hashable` or  `Mappable` protocol.

It's important to draw a distinction between how Garage Storage operates and how Core Data operates: Garage Storage stores a JSON representation of your objects in Core Data, as opposed to storing the objects themselves, as Core Data does. There are some implications to this (explained below), but the best part is that you can add whatever type of object you like to the Garage, whenever you like. You don't have to migrate data models or anything, just park whatever you want!

## Installation

**Swift Package Manager** (Xcode 11 and above)

1. Select **File** > **Swift Packages** > **Add Package Dependency…** from the **File** menu.
2. Paste `https://github.com/mrlegowatch/GarageStorageSwift.git` in the dialog box.
3. Follow the Xcode's instruction to complete the installation.

## Getting Started

"Super-easy, barely an inconvenience!" _(Screenwriter Guy, Pitch Meetings)_

To get started, see: [Getting Started](Documentation/GettingStarted.md).

### Credits

This library is a direct descendent of the [Objective-C version of GarageStorage by Sam Voigt]( https://github.com/samvoigt/GarageStorage), and this library's Objective-C APIs are mostly compatible with that version.
