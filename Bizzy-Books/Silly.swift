//
//  Silly.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 11/28/23.
//

import Foundation

protocol LocationInSchema {
    var uniqueIdentifier: String { get }
    // Add other common properties or methods
}

protocol FusingSchema {}

protocol RealWorldSchema: FusingSchema {}

protocol ImaginationSchema: FusingSchema {}

protocol BankSchema: FusingSchema {}

struct LocationInRealWorldSchema: RealWorldSchema, LocationInSchema {
    var uniqueIdentifier: String
    var whatViridicalContentMeaningSkewer: String //ID handle to access associations.
}

struct LocationInImaginationSchema: ImaginationSchema, LocationInSchema {
    var uniqueIdentifier: String
    var whatHypotheticalContentMeaningSkewer: String //ID handle to access associations.
}

struct LocationInBankSchema: BankSchema, LocationInSchema {
    var uniqueIdentifier: String
    var whatMemoryContentMeaningSkewer: String //ID handle to access associations.
}

struct PointOfInterest {
    var locations: [LocationInSchema]
}

// Example of an array of POIs representing a moment of consciousness
var momentOfConsciousness: [PointOfInterest] = [
    PointOfInterest(locations: [LocationInBankSchema(uniqueIdentifier: "B1", whatMemoryContentMeaningSkewer: "whatB1"), LocationInRealWorldSchema(uniqueIdentifier: "RW1", whatViridicalContentMeaningSkewer: "whatRW1"), LocationInImaginationSchema(uniqueIdentifier: "IS1", whatHypotheticalContentMeaningSkewer: "whatIS1")]),
    PointOfInterest(locations: [LocationInBankSchema(uniqueIdentifier: "B2", whatMemoryContentMeaningSkewer: "whatB2"), LocationInRealWorldSchema(uniqueIdentifier: "RW2", whatViridicalContentMeaningSkewer: "whatRW2"), LocationInImaginationSchema(uniqueIdentifier: "IS2", whatHypotheticalContentMeaningSkewer: "whatIS2")]),
    PointOfInterest(locations: [LocationInBankSchema(uniqueIdentifier: "B3", whatMemoryContentMeaningSkewer: "whatB3"), LocationInRealWorldSchema(uniqueIdentifier: "RW3", whatViridicalContentMeaningSkewer: "whatRW3"), LocationInImaginationSchema(uniqueIdentifier: "IS3", whatHypotheticalContentMeaningSkewer: "whatIS3")])
    // Add more POIs as needed
]
