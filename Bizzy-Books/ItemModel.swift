//
//  ItemModel.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/1/24.
//

import Foundation
import FirebaseDatabase

enum CustomerDocument: String, CaseIterable, Identifiable {
    case contract = "Contract"
    case invoice = "Invoice"
    case receipt = "Receipt"
    case warranty = "Warranty"
    
    var id: String { self.rawValue }
    
    // Optional: Add any additional properties or methods that might be useful for handling document-specific logic
    var displayName: String {
        switch self {
        case .contract:
            return "Contract Document"
        case .invoice:
            return "Invoice Document"
        case .receipt:
            return "Receipt Document"
        case .warranty:
            return "Warranty Document"
        }
    }
}

enum UniversalType {
    case item(Item)
    case entity(Entity)
    case vehicle(Vehicle)
    case project(Project)
}

struct Universal: Identifiable {
    var type: UniversalType
    var id: String {
        switch type {
        case .item(let item): return item.id
        case .entity(let entity): return entity.id
        case .vehicle(let vehicle): return vehicle.id
        case .project(let project): return project.id
        }
    }
    var timestamp: TimeInterval {
        switch type {
        case .item(let item): return item.timeStamp
        case .entity(let entity): return entity.timeStamp
        case .vehicle(let vehicle): return vehicle.timeStamp
        case .project(let project): return project.timeStamp
        }
    }
    
    // Computed properties for Item
    var itemLatitude: Double {
        if case .item(let item) = type {
            return item.latitude
        }
        return 0.0
    }
    
    var itemLongitude: Double {
        if case .item(let item) = type {
            return item.longitude
        }
        return 0.0
    }
    
    var itemItemType: ItemType {
        if case .item(let item) = type {
            return item.itemType
        }
        return .business // Default value
    }
    
    var itemNotes: String {
        if case .item(let item) = type {
            return item.notes
        }
        return ""
    }
    
    var itemWho: String {
        if case .item(let item) = type {
            return item.who
        }
        return ""
    }
    
    var itemWhoID: String {
        if case .item(let item) = type {
            return item.whoID
        }
        return ""
    }
    
    var itemWhat: Int {
        if case .item(let item) = type {
            return item.what
        }
        return 0
    }
    
    var itemWhom: String {
        if case .item(let item) = type {
            return item.whom
        }
        return ""
    }
    
    var itemWhomID: String {
        if case .item(let item) = type {
            return item.whomID
        }
        return ""
    }
    
    var itemPersonalReasonInt: Int {
        if case .item(let item) = type {
            return item.personalReasonInt
        }
        return 0 // Default value for Int
    }
    
    var itemTaxReasonInt: Int {
        if case .item(let item) = type {
            return item.taxReasonInt
        }
        return 0 // Default value for Int
    }
    
    var itemVehicleName: String {
        if case .item(let item) = type {
            return item.vehicleName
        }
        return "" // Default value for String
    }
    
    var itemVehicleID: String {
        if case .item(let item) = type {
            return item.vehicleID
        }
        return "" // Default value for String
    }
    
    var itemWorkersComp: Bool {
        if case .item(let item) = type {
            return item.workersComp
        }
        return false
    }
    
    var itemProjectName: String {
        if case .item(let item) = type {
            return item.projectName
        }
        return ""
    }
    
    var itemProjectID: String {
        if case .item(let item) = type {
            return item.projectID
        }
        return ""
    }
    
    var itemHowMany: Int {
        if case .item(let item) = type {
            return item.howMany
        }
        return 0
    }
    
    var itemOdometer: Int {
        if case .item(let item) = type {
            return item.odometer
        }
        return 0
    }
    
    // Computed properties for Entity
    var entityName: String {
        if case .entity(let entity) = type {
            return entity.name
        }
        return "" // Default value if it's not an entity
    }
    
    var entityBusinessName: String {
        if case .entity(let entity) = type {
            return entity.businessName
        }
        return ""
    }
    
    var entityStreet: String {
        if case .entity(let entity) = type {
            return entity.street
        }
        return ""
    }
    
    var entityCity: String {
        if case .entity(let entity) = type {
            return entity.city
        }
        return ""
    }
    
    var entityState: String {
        if case .entity(let entity) = type {
            return entity.state
        }
        return ""
    }
    
    var entityZip: String {
        if case .entity(let entity) = type {
            return entity.zip
        }
        return ""
    }
    
    var entityPhone: String {
        if case .entity(let entity) = type {
            return entity.phone
        }
        return ""
    }
    
    var entityEmail: String {
        if case .entity(let entity) = type {
            return entity.email
        }
        return ""
    }
    
    var entityEIN: String {
        if case .entity(let entity) = type {
            return entity.ein
        }
        return ""
    }
    
    var entitySSN: String {
        if case .entity(let entity) = type {
            return entity.ssn
        }
        return ""
    }
    
    // Computed properties for Vehicle
    var vehicleName: String {
        if case .vehicle(let vehicle) = type {
            return vehicle.name
        }
        return "" // Default value if it's not a vehicle
    }
    
    var vehicleModel: String {
        if case .vehicle(let vehicle) = type {
            return vehicle.model
        }
        return ""
    }
    
    var vehicleLicensePlate: String {
        if case .vehicle(let vehicle) = type {
            return vehicle.licPlateNo
        }
        return ""
    }
    
    var vehicleVIN: String {
        if case .vehicle(let vehicle) = type {
            return vehicle.vin
        }
        return ""
    }
    
    var vehicleYear: String {
        if case .vehicle(let vehicle) = type {
            return vehicle.year
        }
        return ""
    }
    
    var vehicleMake: String {
        if case .vehicle(let vehicle) = type {
            return vehicle.make
        }
        return ""
    }
    
    var vehicleColor: String {
        if case .vehicle(let vehicle) = type {
            return vehicle.color
        }
        return ""
    }
    
    var vehiclePicd: String {
        if case .vehicle(let vehicle) = type {
            return vehicle.picd
        }
        return ""
    }
    
    // Computed properties for Project
    var projectName: String {
        if case .project(let project) = type {
            return project.name
        }
        return "" // Default value if it's not a project
    }
    
    var projectNotes: String {
        if case .project(let project) = type {
            return project.notes
        }
        return ""
    }
    
    var projectCustomerName: String {
        if case .project(let project) = type {
            return project.customerName
        }
        return ""
    }
    
    var projectCustomerUID: String {
        if case .project(let project) = type {
            return project.customerUID
        }
        return ""
    }
    
    var projectJobsiteStreet: String {
        if case .project(let project) = type {
            return project.jobsiteStreet
        }
        return ""
    }
    
    var projectJobsiteCity: String {
        if case .project(let project) = type {
            return project.jobsiteCity
        }
        return ""
    }
    
    var projectJobsiteState: String {
        if case .project(let project) = type {
            return project.jobsiteState
        }
        return ""
    }
    
    var projectJobsiteZip: String {
        if case .project(let project) = type {
            return project.jobsiteZip
        }
        return ""
    }
    
    var projectCustomerSSN: String {
        if case .project(let project) = type {
            return project.customerSSN
        }
        return ""
    }
    
    var projectCustomerEIN: String {
        if case .project(let project) = type {
            return project.customerEIN
        }
        return ""
    }
}

struct Item: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var latitude: Double //0.0 if off
    var longitude: Double //0.0 if off
    var itemType: ItemType //.business, .personal, .fuel
    var notes: String
    var who: String
    var whoID: String
    var what: Int
    var whom: String
    var whomID: String
    var personalReasonInt: Int
    var taxReasonInt: Int
    var vehicleName: String
    var vehicleID: String
    var workersComp: Bool
    var projectName: String //nil for overhead
    var projectID: String //nil for overhead
    var howMany: Int //thousandths of gallons of fuel
    var odometer: Int //miles
    let key: String
    
    init(snapshot: DataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        id = snapshotValue["id"] as? String ?? ""
        timeStamp = snapshotValue["timeStamp"] as? TimeInterval ?? 0.0
        latitude = snapshotValue["latitude"] as? Double ?? 0.0
        longitude = snapshotValue["longitude"] as? Double ?? 0.0
        if let itemTypeString = snapshotValue["itemType"] as? String, let itemType = ItemType(rawValue: itemTypeString) {
            self.itemType = itemType
        } else {
            self.itemType = .business
        }
        notes = snapshotValue["notes"] as? String ?? ""
        who = snapshotValue["who"] as? String ?? ""
        whoID = snapshotValue["whoID"] as? String ?? ""
        what = snapshotValue["what"] as? Int ?? 0
        whom = snapshotValue["whom"] as? String ?? ""
        whomID = snapshotValue["whomID"] as? String ?? ""
        personalReasonInt = snapshotValue["personalReasonInt"] as? Int ?? 0
        taxReasonInt = snapshotValue["taxReasonInt"] as? Int ?? 0
        vehicleName = snapshotValue["vehicleName"] as? String ?? ""
        vehicleID = snapshotValue["vehicleID"] as? String ?? ""
        workersComp = snapshotValue["workersComp"] as? Bool ?? false
        projectName = snapshotValue["projectName"] as? String ?? ""
        projectID = snapshotValue["projectID"] as? String ?? ""
        howMany = snapshotValue["howMany"] as? Int ?? 0
        odometer = snapshotValue["odometer"] as? Int ?? 0
    }
    
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["latitude"] = latitude
        dictionary["longitude"] = longitude
        dictionary["itemType"] = itemType.rawValue
        dictionary["notes"] = notes
        dictionary["who"] = who
        dictionary["whoID"] = whoID
        dictionary["what"] = what
        dictionary["whom"] = whom
        dictionary["whomID"] = whomID
        dictionary["personalReasonInt"] = personalReasonInt
        dictionary["taxReasonInt"] = taxReasonInt
        dictionary["vehicleName"] = vehicleName
        dictionary["vehicleID"] = vehicleID
        dictionary["workersComp"] = workersComp
        dictionary["projectName"] = projectName
        dictionary["projectID"] = projectID
        dictionary["howMany"] = howMany
        dictionary["odometer"] = odometer
        return dictionary
    }
    
    
    // Initializer that matches the parameter list
    init(latitude: Double, longitude: Double, itemType: ItemType, notes: String, who: String, whoID: String, what: Int, whom: String, whomID: String, personalReasonInt: Int, taxReasonInt: Int, vehicleName: String, vehicleID: String, workersComp: Bool, projectName: String, projectID: String, howMany: Int, odometer: Int, key: String = "") {
        self.key = key
        self.latitude = latitude
        self.longitude = longitude
        self.itemType = itemType
        self.notes = notes
        self.who = who
        self.whoID = whoID
        self.what = what
        self.whom = whom
        self.whomID = whomID
        self.personalReasonInt = personalReasonInt
        self.taxReasonInt = taxReasonInt
        self.vehicleName = vehicleName
        self.vehicleID = vehicleID
        self.workersComp = workersComp
        self.projectName = projectName
        self.projectID = projectID
        self.howMany = howMany
        self.odometer = odometer
    }
}

struct Entity: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var name = ""
    var businessName = ""
    var street = ""
    var city = ""
    var state = ""
    var zip = ""
    var phone = ""
    var email = ""
    var ein = ""
    var ssn = ""
    let key: String
    
    init(snapshot: DataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        id = snapshotValue["id"] as? String ?? ""
        timeStamp = snapshotValue["timeStamp"] as? TimeInterval ?? 0.0
        name = snapshotValue["name"] as? String ?? ""
        businessName = snapshotValue["businessName"] as? String ?? ""
        street = snapshotValue["street"] as? String ?? ""
        city = snapshotValue["city"] as? String ?? ""
        state = snapshotValue["state"] as? String ?? ""
        zip = snapshotValue["zip"] as? String ?? ""
        phone = snapshotValue["phone"] as? String ?? ""
        email = snapshotValue["email"] as? String ?? ""
        ein = snapshotValue["ein"] as? String ?? ""
        ssn = snapshotValue["ssn"] as? String ?? ""
    }
    
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["name"] = name
        dictionary["businessName"] = businessName
        dictionary["street"] = street
        dictionary["city"] = city
        dictionary["state"] = state
        dictionary["zip"] = zip
        dictionary["phone"] = phone
        dictionary["email"] = email
        dictionary["ein"] = ein
        dictionary["ssn"] = ssn
        return dictionary
    }
    
    
    
    // Initializer that matches the parameter list
    init(name: String, businessName: String, street: String, city: String, state: String, zip: String, phone: String, email: String, ein: String, ssn: String, key: String = "") {
        self.key = key
        self.name = name
        self.businessName = businessName
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
        self.phone = phone
        self.email = email
        self.ein = ein
        self.ssn = ssn
    }
    
    init(name: String, key: String = "") {
        self.key = key
        self.name = name
    }
}

struct YouEntity: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var name: String = "You" // Default name
    var uid: String
    
    init(uid: String) {
        self.uid = uid
    }
    
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["name"] = name
        dictionary["uid"] = uid
        return dictionary
    }
    
    init(fromDictionary dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        timeStamp = dictionary["timeStamp"] as? TimeInterval ?? 0.0
        name = dictionary["name"] as? String ?? "You"
        uid = dictionary["uid"] as? String ?? ""
    }
}

struct YouBusinessEntity: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var name: String = "" // Default business name
    var email = ""
    var phone = ""
    var street = ""
    var city = ""
    var state = ""
    var zip = ""
    var ein = ""
    var ssn = ""
    
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["name"] = name
        dictionary["email"] = email
        dictionary["phone"] = phone
        dictionary["street"] = street
        dictionary["city"] = city
        dictionary["state"] = state
        dictionary["zip"] = zip
        dictionary["ein"] = ein
        dictionary["ssn"] = ssn
        return dictionary
    }
    
    init(fromDictionary dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        timeStamp = dictionary["timeStamp"] as? TimeInterval ?? 0.0
        name = dictionary["name"] as? String ?? ""
        email = dictionary["email"] as? String ?? ""
        phone = dictionary["phone"] as? String ?? ""
        street = dictionary["street"] as? String ?? ""
        city = dictionary["city"] as? String ?? ""
        state = dictionary["state"] as? String ?? ""
        zip = dictionary["zip"] as? String ?? ""
        ein = dictionary["ein"] as? String ?? ""
        ssn = dictionary["ssn"] as? String ?? ""
    }
    
    init(name: String, email: String, phone: String, street: String, city: String, state: String, zip: String, ein: String, ssn: String) {
        self.name = name
        self.email = email
        self.phone = phone
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
        self.ein = ein
        self.ssn = ssn
    }
    
    init() {
        
    }
}


struct Project: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var name = ""
    var notes = ""
    var customerName = ""
    var customerUID = ""
    var jobsiteStreet = ""
    var jobsiteCity = ""
    var jobsiteState = ""
    var jobsiteZip = ""
    var customerSSN = ""
    var customerEIN = ""
    let key: String
    
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["name"] = name
        dictionary["notes"] = notes
        dictionary["customerName"] = customerName
        dictionary["customerUID"] = customerUID
        dictionary["jobsiteStreet"] = jobsiteStreet
        dictionary["jobsiteCity"] = jobsiteCity
        dictionary["jobsiteState"] = jobsiteState
        dictionary["jobsiteZip"] = jobsiteZip
        dictionary["customerSSN"] = customerSSN
        dictionary["customerEIN"] = customerEIN
        return dictionary
    }
    
    init(snapshot: DataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        id = snapshotValue["id"] as? String ?? ""
        timeStamp = snapshotValue["timeStamp"] as? TimeInterval ?? 0.0
        name = snapshotValue["name"] as? String ?? ""
        notes = snapshotValue["notes"] as? String ?? ""
        customerName = snapshotValue["customerName"] as? String ?? ""
        customerUID = snapshotValue["customerUID"] as? String ?? ""
        jobsiteStreet = snapshotValue["jobsiteStreet"] as? String ?? ""
        jobsiteCity = snapshotValue["jobsiteCity"] as? String ?? ""
        jobsiteState = snapshotValue["jobsiteState"] as? String ?? ""
        jobsiteZip = snapshotValue["jobsiteZip"] as? String ?? ""
        customerSSN = snapshotValue["customerSSN"] as? String ?? ""
        customerEIN = snapshotValue["customerEIN"] as? String ?? ""
    }
    
    init(name: String, notes: String, customerName: String, customerUID: String, jobsiteStreet: String, jobsiteCity: String, jobsiteState: String, jobsiteZip: String, customerSSN: String, customerEIN: String, key: String = "") {
        self.key = key
        self.name = name
        self.notes = notes
        self.customerName = customerName
        self.customerUID = customerUID
        self.jobsiteStreet = jobsiteStreet
        self.jobsiteCity = jobsiteCity
        self.jobsiteState = jobsiteState
        self.jobsiteZip = jobsiteZip
        self.customerSSN = customerSSN
        self.customerEIN = customerEIN
    }
    
    init(name: String, key: String = "") {
        self.key = key
        self.name = name
        self.customerName = ""
        self.customerUID = ""
    }
}

struct Vehicle: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var year, make, model: String
    var color, picd, vin, licPlateNo: String
    let key: String
    
    var name: String {
        [year, make, model].joined(separator: " ")
    }
    
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["year"] = year
        dictionary["make"] = make
        dictionary["model"] = model
        dictionary["color"] = color
        dictionary["picd"] = picd
        dictionary["vin"] = vin
        dictionary["licPlateNo"] = licPlateNo
        return dictionary
    }
    
    init(snapshot: DataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        id = snapshotValue["id"] as? String ?? ""
        timeStamp = snapshotValue["timeStamp"] as? TimeInterval ?? 0.0
        year = snapshotValue["year"] as? String ?? ""
        make = snapshotValue["make"] as? String ?? ""
        model = snapshotValue["model"] as? String ?? ""
        color = snapshotValue["color"] as? String ?? ""
        picd = snapshotValue["picd"] as? String ?? ""
        vin = snapshotValue["vin"] as? String ?? ""
        licPlateNo = snapshotValue["licPlateNo"] as? String ?? ""
    }
    
    // Initializer that matches the parameter list
    init(year: String, make: String, model: String, color: String, picd: String, vin: String, licPlateNo: String, key: String = "") {
        self.key = key
        self.year = year
        self.make = make
        self.model = model
        self.color = color
        self.picd = picd
        self.vin = vin
        self.licPlateNo = licPlateNo
    }
}


