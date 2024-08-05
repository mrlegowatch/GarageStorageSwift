# GarageStorage

## Overview
GarageStorage is designed to do two things:
- Simplify Core Data persistence, to store any kind of object
- Eliminate versioning Core Data data models, or the need to do xcdatamodel migrations

### What is a Garage?
The `Garage` is the main object that coordinates activity in Garage Storage. It's called a *Garage* because you can park pretty much anything in it, like, you know, a garage. The Garage handles the backing Core Data stack, as well as the saving and retrieving of data. You *park* objects in the Garage, and *retrieve* them later. 

Any object going into or coming out of the Garage must conform to the `Codable` protocol. You can add whatever type of object you like to the Garage, whenever you like. You don't have to migrate data models or anything, just park whatever you want!

## Installation

**Swift Package Manager** (Xcode 11 and above)

1. Select **File** > **Swift Packages** > **Add Package Dependency…** from the **File** menu.
2. Paste `https://github.com/mrlegowatch/GarageStorageSwift.git` in the dialog box.
3. Follow the Xcode's instruction to complete the installation.

## Getting Started

"Actually, it'll be super-easy, barely an inconvenience!" _- Screenwriter Guy, Pitch Meetings_

To get started, see: [Getting Started](Sources/GarageStorage/GarageStorage.docc/GettingStarted.md).

### Credits

This library is a direct descendent of the [Objective-C version of GarageStorage by Sam Voigt]( https://github.com/samvoigt/GarageStorage), and this library's Objective-C APIs are mostly compatible with that version.
