//
//  ItemModel.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/1/24.
//

import Foundation
import FirebaseDatabase

struct Item: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var latitude: Double? //nil if off
    var longitude: Double? //nil if off
    var itemType: ItemType //.business, .personal, .fuel
    var notes: String?
    var who: String
    var whoID: String
    var what: Int
    var whom: String
    var whomID: String
    var personalReasonInt: Int
    var taxReasonInt: Int
    var vehicleName: String?
    var vehicleID: String?
    var workersComp: Bool
    var projectName: String? //nil for overhead
    var projectID: String? //nil for overhead
    var howMany: Int? //thousandths of gallons of fuel
    var odometer: Int? //miles
    
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
    
    init(fromDictionary dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        timeStamp = dictionary["timeStamp"] as? TimeInterval ?? 0.0
        latitude = dictionary["latitude"] as? Double ?? 0.0
        longitude = dictionary["longitude"] as? Double ?? 0.0
        if let itemTypeString = dictionary["itemType"] as? String, let itemType = ItemType(rawValue: itemTypeString) {
            self.itemType = itemType
        } else {
            self.itemType = .business
        }
        notes = dictionary["notes"] as? String ?? ""
        who = dictionary["who"] as? String ?? ""
        whoID = dictionary["whoID"] as? String ?? ""
        what = dictionary["what"] as? Int ?? 0
        whom = dictionary["whom"] as? String ?? ""
        whomID = dictionary["whomID"] as? String ?? ""
        personalReasonInt = dictionary["personalReasonInt"] as? Int ?? 0
        taxReasonInt = dictionary["taxReasonInt"] as? Int ?? 0
        vehicleName = dictionary["vehicleName"] as? String
        vehicleID = dictionary["vehicleID"] as? String
        workersComp = dictionary["workersComp"] as? Bool ?? false
        projectName = dictionary["projectName"] as? String
        projectID = dictionary["projectID"] as? String
        howMany = dictionary["howMany"] as? Int
        odometer = dictionary["odometer"] as? Int
    }
    
    // Initializer that matches the parameter list
    init(latitude: Double?, longitude: Double?, itemType: ItemType, notes: String?, who: String, whoID: String, what: Int, whom: String, whomID: String, personalReasonInt: Int, taxReasonInt: Int, vehicleName: String?, vehicleID: String?, workersComp: Bool, projectName: String?, projectID: String?, howMany: Int?, odometer: Int?) {
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
    var name: String
    var businessName, street, city, state, zip, phone, email, ein, ssn: String?
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
    init(name: String, businessName: String?, street: String?, city: String?, state: String?, zip: String?, phone: String?, email: String?, ein: String?, ssn: String?, key: String = "") {
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
    var email, phone, street, city, state, zip, ein, ssn: String?
    
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
        email = dictionary["email"] as? String
        phone = dictionary["phone"] as? String
        street = dictionary["street"] as? String
        city = dictionary["city"] as? String
        state = dictionary["state"] as? String
        zip = dictionary["zip"] as? String
        ein = dictionary["ein"] as? String
        ssn = dictionary["ssn"] as? String
    }
    
    init(name: String, email: String?, phone: String?, street: String?, city: String?, state: String?, zip: String?, ein: String?, ssn: String?) {
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
    var name: String
    var notes: String?
    var customerName: String
    var customerUID: String
    var jobsiteStreet, jobsiteCity, jobsiteState, jobsiteZip: String?
    
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
        return dictionary
    }
    
    init(fromDictionary dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        timeStamp = dictionary["timeStamp"] as? TimeInterval ?? 0.0
        name = dictionary["name"] as? String ?? ""
        notes = dictionary["notes"] as? String
        customerName = dictionary["customerName"] as? String ?? ""
        customerUID = dictionary["customerUID"] as? String ?? ""
        jobsiteStreet = dictionary["jobsiteStreet"] as? String ?? ""
        jobsiteCity = dictionary["jobsiteCity"] as? String ?? ""
        jobsiteState = dictionary["jobsiteState"] as? String ?? ""
        jobsiteZip = dictionary["jobsiteZip"] as? String ?? ""
    }
    
    init(name: String, notes: String?, customerName: String, customerUID: String, jobsiteStreet: String?, jobsiteCity: String?, jobsiteState: String?, jobsiteZip: String?) {
        self.name = name
        self.notes = notes
        self.customerName = customerName
        self.customerUID = customerUID
        self.jobsiteStreet = jobsiteStreet
        self.jobsiteCity = jobsiteCity
        self.jobsiteState = jobsiteState
        self.jobsiteZip = jobsiteZip
    }
    
    init(name: String) {
        self.name = name
        self.customerName = ""
        self.customerUID = ""
    }
}


struct Vehicle: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var year, make, model: String
    var color, picd, vin, licPlateNo: String?
    
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
    
    init(fromDictionary dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        timeStamp = dictionary["timeStamp"] as? TimeInterval ?? 0.0
        year = dictionary["year"] as? String ?? ""
        make = dictionary["make"] as? String ?? ""
        model = dictionary["model"] as? String ?? ""
        color = dictionary["color"] as? String
        picd = dictionary["picd"] as? String
        vin = dictionary["vin"] as? String
        licPlateNo = dictionary["licPlateNo"] as? String
    }
    
    // Initializer that matches the parameter list
    init(year: String, make: String, model: String, color: String?, picd: String?, vin: String?, licPlateNo: String?) {
        self.year = year
        self.make = make
        self.model = model
        self.color = color
        self.picd = picd
        self.vin = vin
        self.licPlateNo = licPlateNo
    }
}


