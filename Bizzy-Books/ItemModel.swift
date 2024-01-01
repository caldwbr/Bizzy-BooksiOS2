//
//  ItemModel.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/1/24.
//

import Foundation

struct Item: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var latitude: Double? //nil if off
    var longitude: Double? //nil if off
    var itemType: ItemType //.business, .personal, .fuel
    var notes: String
    var who: String
    var whoID: String
    var what: Int
    var whom: String
    var whomID: String
    var personalReason: PersonalReason?
    var taxReason: TaxReason?
    var vehicleName: String?
    var vehicleID: String?
    var workersComp: WorkersComp?
    var projectName: String? //nil for overhead
    var projectID: String? //nil for overhead
    var howMany: Int? //thousandths of gallons of fuel
    var odometer: Int? //miles
}

struct Vehicle: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var year, make, model: String
    var color, picd, vin, licPlateNo: String?
}

struct Entity: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var name: String
    var address, phone, email, ein, ssn: String?
}

enum PersonalReason: String, Codable, CaseIterable {
    case food = "Food"
    case fun = "Fun"
    case pet = "Pet"
    case utilities = "Utilities"
    case phone = "Phone"
    case internet = "Internet"
    case office = "Office"
    case insurance = "Insurance"
    case house = "House"
    case yard = "Yard"
    case medical = "Medical"
    case travel = "Travel"
    case clothes = "Clothes"
    case other = "Other" // 15 Reasons Why
}

enum TaxReason: String, Codable, CaseIterable {
    case income = "Income"
    case supplies = "Supplies"
    case labor = "Labor"
    case vehicle = "Vehicle"
    case proHelp = "Pro Help"
    case insWCGL = "Ins (WC+GL)"
    case taxLic = "Tax+License"
    case travel = "Travel"
    case meals = "Meals"
    case office = "Office"
    case advertising = "Advertising"
    case machineRent = "Machine Rent"
    case propRent = "Property Rent"
    case empBen = "Employee Benefit"
    case depr = "Depreciation"
    case depl = "Depletion"
    case utilities = "Utilities"
    case commissions = "Commissions"
    case wages = "Wages"
    case mortgInt = "Mortgage Int"
    case otherInt = "Other Interest"
    case repairs = "Repairs"
    case pension = "Pension" //23 Reasons Why
}

enum WorkersComp: String, Codable, CaseIterable {
    case wcNA = "WC N/A"
    case wcIncurred = "WC Incurred"
    case subHasWC = "Sub Has WC"
}
