//
//  InventoryModule.swift
//  Bizzy-Books
//
//  Retail-mode inventory tracking (periodic / COGS method).
//  See BizzyBooks_Inventory_Module_Spec.pdf.
//
//  Accounting model: purchases of goods for resale are recorded the day they
//  happen but post to an ASSET bucket — they never touch the Part II expense
//  totals. They become deductible via Cost of Goods Sold at year end:
//      COGS = beginning inventory + purchases - ending inventory
//  Ending inventory comes from a finalized year-end count (or a manual entry).
//
//  HARD RULE: salePriceCents is DISPLAY ONLY (margin insight). It must never
//  feed avgCost, count valuation, COGS, or anything on the tax document.
//

import Foundation
import SwiftUI
import UIKit
import Firebase
import FirebaseDatabase

// MARK: - Business type (mode flag)

enum BusinessType: String, CaseIterable, Identifiable, Codable {
    case contracting = "contracting"
    case retail = "retail"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .contracting: return "Contracting"
        case .retail: return "Retail"
        }
    }
}

// MARK: - Inventory data structures

struct ItemTypeRecord: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var name = ""
    var category = "Other"
    var lastCostCents = 0
    var salePriceCents = 0      // 0 = not set. DISPLAY ONLY — never used in tax math.
    var costIsEstimate = false  // true when cost was reconstructed (opening stock)
    var active = true
    let key: String

    init(name: String, category: String, lastCostCents: Int, salePriceCents: Int = 0, costIsEstimate: Bool = false, key: String = "") {
        self.name = name
        self.category = category
        self.lastCostCents = lastCostCents
        self.salePriceCents = salePriceCents
        self.costIsEstimate = costIsEstimate
        self.key = key
    }

    init(snapshot: DataSnapshot) {
        key = snapshot.key
        let value = snapshot.value as? [String: AnyObject] ?? [:]
        id = value["id"] as? String ?? snapshot.key
        timeStamp = value["timeStamp"] as? TimeInterval ?? 0.0
        name = value["name"] as? String ?? ""
        category = value["category"] as? String ?? "Other"
        lastCostCents = value["lastCostCents"] as? Int ?? 0
        salePriceCents = value["salePriceCents"] as? Int ?? 0
        costIsEstimate = value["costIsEstimate"] as? Bool ?? false
        active = value["active"] as? Bool ?? true
    }

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["name"] = name
        dictionary["category"] = category
        dictionary["lastCostCents"] = lastCostCents
        dictionary["salePriceCents"] = salePriceCents
        dictionary["costIsEstimate"] = costIsEstimate
        dictionary["active"] = active
        return dictionary
    }
}

/// One line of an inventory purchase ("shipment") — stored inside the Item.
struct InventoryPurchaseLine: Identifiable, Codable {
    var id: String = UUID().uuidString
    var itemTypeId = ""
    var itemTypeName = ""   // denormalized for display
    var qty = 0
    var unitCostCents = 0

    var extensionCents: Int { qty * unitCostCents }

    init(itemTypeId: String, itemTypeName: String, qty: Int, unitCostCents: Int) {
        self.itemTypeId = itemTypeId
        self.itemTypeName = itemTypeName
        self.qty = qty
        self.unitCostCents = unitCostCents
    }

    init(fromDictionary dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? UUID().uuidString
        itemTypeId = dictionary["itemTypeId"] as? String ?? ""
        itemTypeName = dictionary["itemTypeName"] as? String ?? ""
        qty = dictionary["qty"] as? Int ?? 0
        unitCostCents = dictionary["unitCostCents"] as? Int ?? 0
    }

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["itemTypeId"] = itemTypeId
        dictionary["itemTypeName"] = itemTypeName
        dictionary["qty"] = qty
        dictionary["unitCostCents"] = unitCostCents
        return dictionary
    }
}

/// Draft line used while entering a purchase in AddItemView.
struct InventoryLineDraft: Identifiable {
    var id: String = UUID().uuidString
    var itemTypeId = ""
    var itemTypeName = ""
    var qty = 0
    var qtyText = ""
    var unitCostCents = 0
    var costText = ""

    var extensionCents: Int { qty * unitCostCents }
}

struct InventoryLocation: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var name = ""
    var note = ""
    var active = true
    let key: String

    init(name: String, note: String = "", key: String = "") {
        self.name = name
        self.note = note
        self.key = key
    }

    init(snapshot: DataSnapshot) {
        key = snapshot.key
        let value = snapshot.value as? [String: AnyObject] ?? [:]
        id = value["id"] as? String ?? snapshot.key
        timeStamp = value["timeStamp"] as? TimeInterval ?? 0.0
        name = value["name"] as? String ?? ""
        note = value["note"] as? String ?? ""
        active = value["active"] as? Bool ?? true
    }

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["name"] = name
        dictionary["note"] = note
        dictionary["active"] = active
        return dictionary
    }
}

enum CountType: String, Codable {
    case opening = "opening"
    case yearEnd = "yearEnd"
}

enum CountStatus: String, Codable {
    case inProgress = "inProgress"
    case finalized = "finalized"
}

/// One counted line: a quantity of one item type at one location.
/// A line existing with qty 0 means "counted, none here" — distinct from no line
/// at all, which means "not counted" (blank ≠ zero).
struct CountLine: Identifiable, Codable {
    var itemTypeId = ""
    var locationId = ""
    var qty = 0
    /// Cost per unit in cents. While a count is in progress this holds an
    /// override (when costOverridden) — otherwise the live weighted average is
    /// used for display. At finalize the value actually used is frozen in here
    /// for every line so historical years stay reproducible.
    var unitCostUsedCents = 0
    var costOverridden = false

    var id: String { itemTypeId + "_" + locationId }

    init(itemTypeId: String, locationId: String, qty: Int, unitCostUsedCents: Int = 0, costOverridden: Bool = false) {
        self.itemTypeId = itemTypeId
        self.locationId = locationId
        self.qty = qty
        self.unitCostUsedCents = unitCostUsedCents
        self.costOverridden = costOverridden
    }

    init(fromDictionary dictionary: [String: Any]) {
        itemTypeId = dictionary["itemTypeId"] as? String ?? ""
        locationId = dictionary["locationId"] as? String ?? ""
        qty = dictionary["qty"] as? Int ?? 0
        unitCostUsedCents = dictionary["unitCostUsedCents"] as? Int ?? 0
        costOverridden = dictionary["costOverridden"] as? Bool ?? false
    }

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["itemTypeId"] = itemTypeId
        dictionary["locationId"] = locationId
        dictionary["qty"] = qty
        dictionary["unitCostUsedCents"] = unitCostUsedCents
        dictionary["costOverridden"] = costOverridden
        return dictionary
    }
}

/// A dated, saved, re-openable count session (opening or year-end).
struct InventoryCount: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timeStamp: TimeInterval = Date().timeIntervalSince1970
    var taxYear: Int = Calendar.current.component(.year, from: Date())
    var countDate: TimeInterval = Date().timeIntervalSince1970
    var type: CountType = .yearEnd
    var status: CountStatus = .inProgress
    var finalizedAt: TimeInterval = 0
    var reopenLog: [TimeInterval] = []
    var lines: [CountLine] = []
    var doneLocationIds: [String] = []
    var grandTotalCents = 0     // written at finalize
    var totalUnits = 0          // written at finalize
    let key: String

    /// The year boundary this count establishes stock for. A year-end count for
    /// 2026 and an opening count for 2027 describe the same moment.
    var boundaryYear: Int { type == .yearEnd ? taxYear : taxYear - 1 }

    var displayName: String {
        type == .opening ? "Opening Inventory \(taxYear)" : "Year-End Count \(taxYear)"
    }

    init(taxYear: Int, type: CountType, key: String = "") {
        self.taxYear = taxYear
        self.type = type
        self.key = key
    }

    init(snapshot: DataSnapshot) {
        key = snapshot.key
        let value = snapshot.value as? [String: AnyObject] ?? [:]
        id = value["id"] as? String ?? snapshot.key
        timeStamp = value["timeStamp"] as? TimeInterval ?? 0.0
        taxYear = value["taxYear"] as? Int ?? 0
        countDate = value["countDate"] as? TimeInterval ?? 0.0
        type = CountType(rawValue: value["type"] as? String ?? "") ?? .yearEnd
        status = CountStatus(rawValue: value["status"] as? String ?? "") ?? .inProgress
        finalizedAt = value["finalizedAt"] as? TimeInterval ?? 0.0
        reopenLog = value["reopenLog"] as? [TimeInterval] ?? []
        grandTotalCents = value["grandTotalCents"] as? Int ?? 0
        totalUnits = value["totalUnits"] as? Int ?? 0
        if let doneDict = value["doneLocationIds"] as? [String: Bool] {
            doneLocationIds = doneDict.filter { $0.value }.map { $0.key }
        } else if let doneArray = value["doneLocationIds"] as? [String] {
            doneLocationIds = doneArray
        }
        if let lineDicts = value["lines"] as? [String: [String: Any]] {
            lines = lineDicts.values.map { CountLine(fromDictionary: $0) }
        }
    }

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["id"] = id
        dictionary["timeStamp"] = timeStamp
        dictionary["taxYear"] = taxYear
        dictionary["countDate"] = countDate
        dictionary["type"] = type.rawValue
        dictionary["status"] = status.rawValue
        dictionary["finalizedAt"] = finalizedAt
        dictionary["reopenLog"] = reopenLog
        dictionary["grandTotalCents"] = grandTotalCents
        dictionary["totalUnits"] = totalUnits
        var doneDict: [String: Bool] = [:]
        for locId in doneLocationIds { doneDict[locId] = true }
        dictionary["doneLocationIds"] = doneDict
        var lineDict: [String: [String: Any]] = [:]
        for line in lines { lineDict[line.id] = line.toDictionary() }
        dictionary["lines"] = lineDict
        return dictionary
    }
}

/// Per-tax-year figures (Schedule C Part III inputs).
struct TaxYearRecord: Codable {
    var year: Int
    var beginningInventoryCents = 0
    var hasBeginning = false
    var beginningSource = ""    // "rollforward" | "manual"
    var endingInventoryCents = 0
    var hasEnding = false
    var endingSource = ""       // "count" | "manual"

    init(year: Int) {
        self.year = year
    }

    init(year: Int, dictionary: [String: Any]) {
        self.year = year
        beginningInventoryCents = dictionary["beginningInventoryCents"] as? Int ?? 0
        hasBeginning = dictionary["hasBeginning"] as? Bool ?? false
        beginningSource = dictionary["beginningSource"] as? String ?? ""
        endingInventoryCents = dictionary["endingInventoryCents"] as? Int ?? 0
        hasEnding = dictionary["hasEnding"] as? Bool ?? false
        endingSource = dictionary["endingSource"] as? String ?? ""
    }

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["year"] = year
        dictionary["beginningInventoryCents"] = beginningInventoryCents
        dictionary["hasBeginning"] = hasBeginning
        dictionary["beginningSource"] = beginningSource
        dictionary["endingInventoryCents"] = endingInventoryCents
        dictionary["hasEnding"] = hasEnding
        dictionary["endingSource"] = endingSource
        return dictionary
    }
}

// MARK: - Formatting helpers

enum InventoryFormat {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    static func dollars(_ cents: Int) -> String {
        return currency.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }

    static func dollars(_ cents: Double) -> String {
        return currency.string(from: NSNumber(value: cents / 100.0)) ?? "$0.00"
    }
}

// MARK: - Model: inventory logic

extension Model {

    var isRetail: Bool { businessType == .retail }

    /// Item types the segmented picker offers. Retail adds Inventory and
    /// keeps Fuel — the trailer still needs hauling.
    var availableItemTypes: [ItemType] {
        isRetail ? [.business, .personal, .fuel, .inventory] : [.business, .personal, .fuel]
    }

    /// Customer documents offered on the documents screen. Retail has no
    /// contracts or warranties — but invoices, receipts and the tax document remain.
    var availableCustomerDocuments: [CustomerDocument] {
        isRetail ? [.invoice, .receipt] : CustomerDocument.allCases
    }

    static let defaultItemCategories = ["Candles", "Fragrance", "Apparel", "Coffee & Tea", "Other"]

    /// Categories to offer in pickers: defaults plus anything the user has created.
    var itemCategories: [String] {
        var cats = Model.defaultItemCategories
        for t in itemTypes where !cats.contains(t.category) && !t.category.isEmpty {
            cats.insert(t.category, at: cats.count - 1)
        }
        return cats
    }

    // MARK: Loading

    func loadBusinessType() {
        dataLoadGroup.enter()
        businessTypeRef?.observeSingleEvent(of: .value, with: { snapshot in
            if let raw = snapshot.value as? String, let type = BusinessType(rawValue: raw) {
                self.businessType = type
            } else {
                self.businessType = .contracting
            }
            self.dataLoadGroup.leave()
        })
    }

    func loadItemTypes() {
        itemTypes.removeAll()
        dataLoadGroup.enter()
        itemTypesRef?.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                self.itemTypes.append(ItemTypeRecord(snapshot: child as! DataSnapshot))
            }
            self.itemTypes.sort { $0.name.lowercased() < $1.name.lowercased() }
            self.dataLoadGroup.leave()
        })
    }

    func loadInventoryLocations() {
        inventoryLocations.removeAll()
        dataLoadGroup.enter()
        inventoryLocationsRef?.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                self.inventoryLocations.append(InventoryLocation(snapshot: child as! DataSnapshot))
            }
            self.inventoryLocations.sort { $0.timeStamp < $1.timeStamp }
            self.dataLoadGroup.leave()
        })
    }

    func loadInventoryCounts() {
        inventoryCounts.removeAll()
        dataLoadGroup.enter()
        inventoryCountsRef?.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                self.inventoryCounts.append(InventoryCount(snapshot: child as! DataSnapshot))
            }
            self.inventoryCounts.sort { $0.taxYear > $1.taxYear }
            self.dataLoadGroup.leave()
        })
    }

    func loadTaxYearRecords() {
        taxYearRecords.removeAll()
        dataLoadGroup.enter()
        taxYearsRef?.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                if let year = Int(snap.key), let dict = snap.value as? [String: Any] {
                    self.taxYearRecords[snap.key] = TaxYearRecord(year: year, dictionary: dict)
                }
            }
            self.dataLoadGroup.leave()
        })
    }

    // MARK: Mode switching

    func setBusinessType(_ type: BusinessType) {
        businessType = type
        businessTypeRef?.setValue(type.rawValue)
        if type == .retail {
            seedDefaultLocationsIfNeeded()
        }
    }

    /// Seed the spec's default locations the first time retail mode turns on.
    func seedDefaultLocationsIfNeeded() {
        guard inventoryLocations.isEmpty else { return }
        let seeds = ["Trailer", "Storefront", "Rostretta", "Columbus store presence", "Home / storage"]
        for name in seeds {
            _ = addLocation(name: name)
        }
    }

    // MARK: Item types

    @discardableResult
    func addItemType(name: String, category: String, unitCostCents: Int, salePriceCents: Int = 0, costIsEstimate: Bool = false) -> ItemTypeRecord {
        let record = ItemTypeRecord(name: name, category: category, lastCostCents: unitCostCents, salePriceCents: salePriceCents, costIsEstimate: costIsEstimate)
        itemTypes.append(record)
        itemTypes.sort { $0.name.lowercased() < $1.name.lowercased() }
        itemTypesRef?.child(record.id).setValue(record.toDictionary())
        return record
    }

    func saveItemType(_ record: ItemTypeRecord) {
        if let index = itemTypes.firstIndex(where: { $0.id == record.id }) {
            itemTypes[index] = record
        }
        itemTypesRef?.child(record.id).setValue(record.toDictionary())
    }

    func itemTypeRecord(by id: String) -> ItemTypeRecord? {
        return itemTypes.first(where: { $0.id == id })
    }

    func itemTypeName(by id: String) -> String {
        return itemTypeRecord(by: id)?.name ?? "Unknown item"
    }

    // MARK: Locations

    var activeLocations: [InventoryLocation] {
        inventoryLocations.filter { $0.active }
    }

    @discardableResult
    func addLocation(name: String, note: String = "") -> InventoryLocation {
        let location = InventoryLocation(name: name, note: note)
        inventoryLocations.append(location)
        inventoryLocationsRef?.child(location.id).setValue(location.toDictionary())
        return location
    }

    func archiveLocation(_ location: InventoryLocation) {
        if let index = inventoryLocations.firstIndex(where: { $0.id == location.id }) {
            inventoryLocations[index].active = false
            inventoryLocationsRef?.child(location.id).setValue(inventoryLocations[index].toDictionary())
        }
    }

    // MARK: Purchases (the asset bucket)

    var inventoryPurchaseItems: [Item] {
        items.filter { $0.itemType == .inventory }
    }

    func inventoryPurchaseItems(year: Int) -> [Item] {
        inventoryPurchaseItems.filter { $0.year == year }
    }

    /// Schedule C line 36: what she actually paid for resale goods in the year
    /// (header totals — freight/tax differences from the line sum are hers to keep).
    func purchasesHeaderTotalCents(year: Int) -> Int {
        inventoryPurchaseItems(year: year).reduce(0) { $0 + $1.what }
    }

    func purchasedQty(typeId: String, year: Int) -> Int {
        var total = 0
        for item in inventoryPurchaseItems(year: year) {
            for line in item.lines where line.itemTypeId == typeId {
                total += line.qty
            }
        }
        return total
    }

    /// Purchase lines drawn from the AddItemView drafts, dropping incomplete rows.
    var validInventoryLines: [InventoryPurchaseLine] {
        inventoryLineDrafts
            .filter { !$0.itemTypeId.isEmpty && $0.qty > 0 }
            .map { InventoryPurchaseLine(itemTypeId: $0.itemTypeId, itemTypeName: $0.itemTypeName, qty: $0.qty, unitCostCents: $0.unitCostCents) }
    }

    var inventoryDraftTotalCents: Int {
        validInventoryLines.reduce(0) { $0 + $1.extensionCents }
    }

    func clearInventoryDrafts() {
        inventoryLineDrafts.removeAll()
    }

    /// After saving a purchase: remember each type's most recent cost (display only).
    func recordInventoryPurchaseSideEffects(_ item: Item) {
        for line in item.lines {
            if var record = itemTypeRecord(by: line.itemTypeId) {
                record.lastCostCents = line.unitCostCents
                saveItemType(record)
            }
        }
    }

    // MARK: Valuation — weighted moving average

    /// The finalized count that establishes stock at the start of `year`:
    /// the year-end count of `year - 1`, or an opening count for `year`.
    /// If several qualify, the latest boundary wins.
    func anchorCount(forYear year: Int) -> InventoryCount? {
        let candidates = inventoryCounts.filter { $0.status == .finalized && $0.boundaryYear < year }
        return candidates.max(by: { $0.boundaryYear < $1.boundaryYear })
    }

    func anchorQty(typeId: String, forYear year: Int) -> Int {
        guard let anchor = anchorCount(forYear: year) else { return 0 }
        return anchor.lines.filter { $0.itemTypeId == typeId }.reduce(0) { $0 + $1.qty }
    }

    /// Weighted moving average cost, in cents, for valuing stock of `typeId`
    /// during `year`. Basis = the anchor count's frozen lines plus every
    /// purchase line after the anchor boundary through `year`.
    /// 40 @ $140 then 20 @ $150 → $143.33. Sale price never enters here.
    func avgCostCents(typeId: String, forYear year: Int) -> Double {
        var qty = 0
        var costCents = 0
        let anchor = anchorCount(forYear: year)
        if let anchor = anchor {
            for line in anchor.lines where line.itemTypeId == typeId {
                qty += line.qty
                costCents += line.qty * line.unitCostUsedCents
            }
        }
        let firstYear = (anchor?.boundaryYear ?? Int.min)
        for item in inventoryPurchaseItems {
            guard item.year > firstYear && item.year <= year else { continue }
            for line in item.lines where line.itemTypeId == typeId {
                qty += line.qty
                costCents += line.qty * line.unitCostCents
            }
        }
        if qty > 0 {
            return Double(costCents) / Double(qty)
        }
        // No history yet — fall back to the last known cost for display.
        return Double(itemTypeRecord(by: typeId)?.lastCostCents ?? 0)
    }

    func currentAvgCostCents(typeId: String) -> Double {
        avgCostCents(typeId: typeId, forYear: Calendar.current.component(.year, from: Date()))
    }

    /// The per-unit cost a count line uses right now, in whole cents.
    /// Finalized counts always use their frozen snapshot.
    func lineCostCents(_ line: CountLine, in count: InventoryCount) -> Int {
        if count.status == .finalized { return line.unitCostUsedCents }
        if line.costOverridden { return line.unitCostUsedCents }
        return Int((avgCostCents(typeId: line.itemTypeId, forYear: count.taxYear)).rounded())
    }

    func countTotals(_ count: InventoryCount) -> (units: Int, cents: Int) {
        var units = 0
        var cents = 0
        for line in count.lines {
            units += line.qty
            cents += line.qty * lineCostCents(line, in: count)
        }
        return (units, cents)
    }

    func locationSubtotal(count: InventoryCount, locationId: String) -> (units: Int, cents: Int) {
        var units = 0
        var cents = 0
        for line in count.lines where line.locationId == locationId {
            units += line.qty
            cents += line.qty * lineCostCents(line, in: count)
        }
        return (units, cents)
    }

    // MARK: Counts

    func count(by id: String) -> InventoryCount? {
        inventoryCounts.first(where: { $0.id == id })
    }

    @discardableResult
    func createCount(taxYear: Int, type: CountType) -> InventoryCount {
        let count = InventoryCount(taxYear: taxYear, type: type)
        inventoryCounts.append(count)
        inventoryCounts.sort { $0.taxYear > $1.taxYear }
        inventoryCountsRef?.child(count.id).setValue(count.toDictionary())
        return count
    }

    func deleteCount(countId: String) {
        inventoryCounts.removeAll { $0.id == countId }
        inventoryCountsRef?.child(countId).removeValue()
    }

    func updateCountDate(countId: String, date: Date) {
        guard let index = inventoryCounts.firstIndex(where: { $0.id == countId }) else { return }
        inventoryCounts[index].countDate = date.timeIntervalSince1970
        inventoryCountsRef?.child(countId).child("countDate").setValue(inventoryCounts[index].countDate)
    }

    /// Autosave one line (called on every quantity commit — she can walk away
    /// mid-count and resume days later with nothing lost).
    func saveCountLine(countId: String, line: CountLine) {
        guard let index = inventoryCounts.firstIndex(where: { $0.id == countId }) else { return }
        var toSave = line
        if !toSave.costOverridden {
            toSave.unitCostUsedCents = Int(avgCostCents(typeId: line.itemTypeId, forYear: inventoryCounts[index].taxYear).rounded())
        }
        if let lineIndex = inventoryCounts[index].lines.firstIndex(where: { $0.id == toSave.id }) {
            inventoryCounts[index].lines[lineIndex] = toSave
        } else {
            inventoryCounts[index].lines.append(toSave)
        }
        inventoryCountsRef?.child(countId).child("lines").child(toSave.id).setValue(toSave.toDictionary())
    }

    func removeCountLine(countId: String, lineId: String) {
        guard let index = inventoryCounts.firstIndex(where: { $0.id == countId }) else { return }
        inventoryCounts[index].lines.removeAll { $0.id == lineId }
        inventoryCountsRef?.child(countId).child("lines").child(lineId).removeValue()
    }

    func countLine(countId: String, itemTypeId: String, locationId: String) -> CountLine? {
        guard let count = count(by: countId) else { return nil }
        return count.lines.first(where: { $0.itemTypeId == itemTypeId && $0.locationId == locationId })
    }

    func setLocationDone(countId: String, locationId: String, done: Bool) {
        guard let index = inventoryCounts.firstIndex(where: { $0.id == countId }) else { return }
        if done {
            if !inventoryCounts[index].doneLocationIds.contains(locationId) {
                inventoryCounts[index].doneLocationIds.append(locationId)
            }
        } else {
            inventoryCounts[index].doneLocationIds.removeAll { $0 == locationId }
        }
        var doneDict: [String: Bool] = [:]
        for locId in inventoryCounts[index].doneLocationIds { doneDict[locId] = true }
        inventoryCountsRef?.child(countId).child("doneLocationIds").setValue(doneDict)
    }

    /// Item types to pre-populate a count screen with: everything purchased in
    /// the count's tax year, everything with a nonzero balance at the anchor,
    /// and everything already counted in this session. Opening counts start
    /// empty and seed the catalog as she walks.
    func typesForCount(_ count: InventoryCount) -> [ItemTypeRecord] {
        var ids = Set<String>()
        if count.type == .yearEnd {
            for item in inventoryPurchaseItems(year: count.taxYear) {
                for line in item.lines { ids.insert(line.itemTypeId) }
            }
            if let anchor = anchorCount(forYear: count.taxYear) {
                var anchorTotals: [String: Int] = [:]
                for line in anchor.lines {
                    anchorTotals[line.itemTypeId, default: 0] += line.qty
                }
                for (typeId, qty) in anchorTotals where qty > 0 { ids.insert(typeId) }
            }
        }
        for line in count.lines { ids.insert(line.itemTypeId) }
        return itemTypes.filter { ids.contains($0.id) }
    }

    /// Review-screen warnings (§6.4). Warnings, not blockers.
    func countWarnings(_ count: InventoryCount) -> [String] {
        var warnings: [String] = []
        guard count.type == .yearEnd else {
            // Opening counts: only cost sanity applies.
            let noCost = count.lines.filter { lineCostCents($0, in: count) <= 0 && $0.qty > 0 }
            if !noCost.isEmpty {
                warnings.append("\(noCost.count) counted line(s) have no cost on file — their value will be $0.")
            }
            return warnings
        }
        // Negative computed units sold: counted more than she could have had.
        var countedTotals: [String: Int] = [:]
        for line in count.lines {
            countedTotals[line.itemTypeId, default: 0] += line.qty
        }
        for (typeId, counted) in countedTotals {
            let available = anchorQty(typeId: typeId, forYear: count.taxYear) + purchasedQty(typeId: typeId, year: count.taxYear)
            if counted > available {
                warnings.append("\(itemTypeName(by: typeId)): counted \(counted) but only \(available) on record — miscount, missed purchase, or an uncounted location?")
            }
        }
        // Purchased this year but zero counted anywhere (plausible if sold out).
        var purchasedIds = Set<String>()
        for item in inventoryPurchaseItems(year: count.taxYear) {
            for line in item.lines { purchasedIds.insert(line.itemTypeId) }
        }
        for typeId in purchasedIds {
            let counted = countedTotals[typeId] ?? 0
            let hasExplicitLine = count.lines.contains { $0.itemTypeId == typeId }
            if counted == 0 && !hasExplicitLine {
                warnings.append("\(itemTypeName(by: typeId)) was purchased this year but not counted anywhere — sold out, or missed?")
            }
        }
        // Locations left entirely uncounted.
        for location in activeLocations {
            let hasLines = count.lines.contains { $0.locationId == location.id }
            let markedDone = count.doneLocationIds.contains(location.id)
            if !hasLines && !markedDone {
                warnings.append("Location “\(location.name)” has no counted lines and isn’t marked done.")
            }
        }
        // Item types with no cost on file.
        let noCost = count.lines.filter { lineCostCents($0, in: count) <= 0 && $0.qty > 0 }
        if !noCost.isEmpty {
            warnings.append("\(noCost.count) counted line(s) have no cost on file — their value will be $0.")
        }
        return warnings
    }

    /// Finalize: freeze every line's unit cost, compute totals, lock the count,
    /// write ending inventory to the tax year and roll it forward as next
    /// year's beginning inventory (§6.4 — the roll-forward is essential).
    func finalizeCount(countId: String) {
        guard let index = inventoryCounts.firstIndex(where: { $0.id == countId }) else { return }
        var count = inventoryCounts[index]
        for lineIndex in count.lines.indices {
            let frozen = lineCostCents(count.lines[lineIndex], in: count)
            count.lines[lineIndex].unitCostUsedCents = frozen
        }
        var units = 0
        var cents = 0
        for line in count.lines {
            units += line.qty
            cents += line.qty * line.unitCostUsedCents
        }
        count.totalUnits = units
        count.grandTotalCents = cents
        count.status = .finalized
        count.finalizedAt = Date().timeIntervalSince1970
        inventoryCounts[index] = count
        inventoryCountsRef?.child(countId).setValue(count.toDictionary())

        if count.type == .yearEnd {
            // Ending inventory for this tax year…
            var record = taxYearRecord(count.taxYear) ?? TaxYearRecord(year: count.taxYear)
            record.endingInventoryCents = cents
            record.hasEnding = true
            record.endingSource = "count"
            saveTaxYearRecord(record)
            // …rolls forward as next year's beginning inventory.
            var nextRecord = taxYearRecord(count.taxYear + 1) ?? TaxYearRecord(year: count.taxYear + 1)
            nextRecord.beginningInventoryCents = cents
            nextRecord.hasBeginning = true
            nextRecord.beginningSource = "rollforward"
            saveTaxYearRecord(nextRecord)
        } else {
            // Opening count establishes the beginning of its tax year.
            var record = taxYearRecord(count.taxYear) ?? TaxYearRecord(year: count.taxYear)
            record.beginningInventoryCents = cents
            record.hasBeginning = true
            record.beginningSource = "count"
            saveTaxYearRecord(record)
        }
    }

    /// Reopen a finalized count — explicit action, logged (§6.4).
    func reopenCount(countId: String) {
        guard let index = inventoryCounts.firstIndex(where: { $0.id == countId }) else { return }
        inventoryCounts[index].status = .inProgress
        inventoryCounts[index].reopenLog.append(Date().timeIntervalSince1970)
        inventoryCountsRef?.child(countId).child("status").setValue(CountStatus.inProgress.rawValue)
        inventoryCountsRef?.child(countId).child("reopenLog").setValue(inventoryCounts[index].reopenLog)
    }

    // MARK: Units sold (periodic derivation — no sales are ever recorded)

    func finalizedYearEndCount(year: Int) -> InventoryCount? {
        inventoryCounts.first(where: { $0.type == .yearEnd && $0.taxYear == year && $0.status == .finalized })
    }

    func endingQty(typeId: String, year: Int) -> Int? {
        guard let count = finalizedYearEndCount(year: year) else { return nil }
        return count.lines.filter { $0.itemTypeId == typeId }.reduce(0) { $0 + $1.qty }
    }

    /// beginning + purchased − ending. Only valid in aggregate across locations.
    func unitsSold(typeId: String, year: Int) -> Int? {
        guard let ending = endingQty(typeId: typeId, year: year) else { return nil }
        return anchorQty(typeId: typeId, forYear: year) + purchasedQty(typeId: typeId, year: year) - ending
    }

    // MARK: Tax year records

    func taxYearRecord(_ year: Int) -> TaxYearRecord? {
        taxYearRecords[String(year)]
    }

    func saveTaxYearRecord(_ record: TaxYearRecord) {
        taxYearRecords[String(record.year)] = record
        taxYearsRef?.child(String(record.year)).setValue(record.toDictionary())
    }

    /// Manual escape hatch (§7.4): the return can be correct with just a number.
    func setManualBeginning(year: Int, cents: Int) {
        var record = taxYearRecord(year) ?? TaxYearRecord(year: year)
        record.beginningInventoryCents = cents
        record.hasBeginning = true
        record.beginningSource = "manual"
        saveTaxYearRecord(record)
    }

    func setManualEnding(year: Int, cents: Int) {
        var record = taxYearRecord(year) ?? TaxYearRecord(year: year)
        record.endingInventoryCents = cents
        record.hasEnding = true
        record.endingSource = "manual"
        saveTaxYearRecord(record)
    }

    /// Compute the Schedule C Part III block for the tax document.
    /// Contracting mode is hard-gated to zero so existing behavior cannot change.
    /// No ending inventory on record → COGS stays 0 (no count, no COGS, no
    /// deduction — never assume everything sold).
    func computeCOGS(forYear year: Int) {
        tdBeginningInventory = 0
        tdEndingInventory = 0
        tdInventoryPurchases = 0
        tdCOGS = 0
        tdCogsAvailable = false
        guard businessType == .retail else { return }

        tdInventoryPurchases = purchasesHeaderTotalCents(year: year)

        if let record = taxYearRecord(year), record.hasBeginning {
            tdBeginningInventory = record.beginningInventoryCents
        } else if let anchor = anchorCount(forYear: year) {
            tdBeginningInventory = anchor.grandTotalCents
        }

        if let record = taxYearRecord(year), record.hasEnding {
            tdEndingInventory = record.endingInventoryCents
            tdCogsAvailable = true
        } else if let count = finalizedYearEndCount(year: year) {
            tdEndingInventory = count.grandTotalCents
            tdCogsAvailable = true
        }

        if tdCogsAvailable {
            tdCOGS = tdBeginningInventory + tdInventoryPurchases - tdEndingInventory
        }
    }

    // MARK: Count PDF report (§6.5)

    func generateInventoryCountPDF(_ count: InventoryCount) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "BizzyBooks",
            kCGPDFContextAuthor: "app user",
            kCGPDFContextTitle: "\(count.displayName) — Inventory Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold), .foregroundColor: UIColor.black]
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: UIColor.black]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]
        let boldBodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: UIColor.black]
        let smallAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkGray]

        let leftMargin: CGFloat = 50.0
        let maxWidth = pageWidth - 100.0
        let topMargin: CGFloat = 70.0
        let lineSpacing: CGFloat = 4.0
        let sectionSpacing: CGFloat = 12.0

        func draw(_ text: String, x: CGFloat, y: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
            let attributed = NSAttributedString(string: text, attributes: attributes)
            attributed.draw(at: CGPoint(x: x, y: y))
            return attributed.size().height
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let countDateString = dateFormatter.string(from: Date(timeIntervalSince1970: count.countDate))

        let totals = countTotals(count)
        let year = count.taxYear

        let data = renderer.pdfData { context in
            // ============ SUMMARY PAGE ============
            context.beginPage()
            var y: CGFloat = topMargin
            y += draw("\(count.displayName)", x: leftMargin, y: y, attributes: titleAttributes) + lineSpacing
            y += draw("Count date: \(countDateString)   Status: \(count.status == .finalized ? "Finalized" : "In progress")", x: leftMargin, y: y, attributes: bodyAttributes) + sectionSpacing

            y += draw("TOTAL ENDING INVENTORY (at cost): \(InventoryFormat.dollars(totals.cents))", x: leftMargin, y: y, attributes: headerAttributes) + lineSpacing
            y += draw("Total units: \(totals.units)", x: leftMargin, y: y, attributes: bodyAttributes) + sectionSpacing

            // Breakdown by category
            y += draw("By category", x: leftMargin, y: y, attributes: boldBodyAttributes) + lineSpacing
            var byCategory: [String: (units: Int, cents: Int)] = [:]
            for line in count.lines {
                let category = itemTypeRecord(by: line.itemTypeId)?.category ?? "Other"
                var entry = byCategory[category] ?? (0, 0)
                entry.units += line.qty
                entry.cents += line.qty * lineCostCents(line, in: count)
                byCategory[category] = entry
            }
            for (category, entry) in byCategory.sorted(by: { $0.key < $1.key }) {
                y += draw("\(category): \(entry.units) units — \(InventoryFormat.dollars(entry.cents))", x: leftMargin + 12, y: y, attributes: bodyAttributes) + lineSpacing
            }
            y += sectionSpacing

            // Breakdown by location
            y += draw("By location", x: leftMargin, y: y, attributes: boldBodyAttributes) + lineSpacing
            for location in inventoryLocations {
                let subtotal = locationSubtotal(count: count, locationId: location.id)
                if subtotal.units > 0 || count.lines.contains(where: { $0.locationId == location.id }) {
                    y += draw("\(location.name): \(subtotal.units) units — \(InventoryFormat.dollars(subtotal.cents))", x: leftMargin + 12, y: y, attributes: bodyAttributes) + lineSpacing
                }
            }
            y += sectionSpacing

            // Schedule C Part III block (year-end counts only)
            if count.type == .yearEnd {
                let beginning = taxYearRecord(year)?.hasBeginning == true
                    ? taxYearRecord(year)!.beginningInventoryCents
                    : (anchorCount(forYear: year)?.grandTotalCents ?? 0)
                let purchases = purchasesHeaderTotalCents(year: year)
                let cogs = beginning + purchases - totals.cents
                y += draw("SCHEDULE C, PART III — COST OF GOODS SOLD", x: leftMargin, y: y, attributes: headerAttributes) + lineSpacing
                y += draw("Beginning inventory (line 35): \(InventoryFormat.dollars(beginning))", x: leftMargin + 12, y: y, attributes: bodyAttributes) + lineSpacing
                y += draw("+ Purchases (line 36): \(InventoryFormat.dollars(purchases))", x: leftMargin + 12, y: y, attributes: bodyAttributes) + lineSpacing
                y += draw("− Ending inventory (line 41): \(InventoryFormat.dollars(totals.cents))", x: leftMargin + 12, y: y, attributes: bodyAttributes) + lineSpacing
                y += draw("= Cost of Goods Sold (line 42): \(InventoryFormat.dollars(cogs))", x: leftMargin + 12, y: y, attributes: boldBodyAttributes) + sectionSpacing
            }

            let estimateCount = count.lines.filter { itemTypeRecord(by: $0.itemTypeId)?.costIsEstimate == true }.count
            if estimateCount > 0 {
                y += draw("* \(estimateCount) line(s) use reconstructed (estimated) costs — marked with * on location pages.", x: leftMargin, y: y, attributes: smallAttributes) + lineSpacing
            }
            _ = draw("Bizzy Books is a record-keeping tool, not tax advice. Review all figures with a qualified tax preparer.", x: leftMargin, y: pageHeight - 50, attributes: smallAttributes)

            // ============ ONE PAGE PER LOCATION ============
            for location in inventoryLocations {
                let locationLines = count.lines.filter { $0.locationId == location.id && $0.qty >= 0 }
                guard !locationLines.isEmpty else { continue }
                context.beginPage()
                var ly: CGFloat = topMargin
                ly += draw("Location: \(location.name)", x: leftMargin, y: ly, attributes: headerAttributes) + sectionSpacing

                let col1 = leftMargin
                let col2 = leftMargin + maxWidth * 0.55
                let col3 = leftMargin + maxWidth * 0.70
                let col4 = leftMargin + maxWidth * 0.85
                _ = draw("Item type", x: col1, y: ly, attributes: boldBodyAttributes)
                _ = draw("Qty", x: col2, y: ly, attributes: boldBodyAttributes)
                _ = draw("Unit cost", x: col3, y: ly, attributes: boldBodyAttributes)
                _ = draw("Extended", x: col4, y: ly, attributes: boldBodyAttributes)
                ly += 16

                let sorted = locationLines.sorted { itemTypeName(by: $0.itemTypeId) < itemTypeName(by: $1.itemTypeId) }
                for line in sorted {
                    if ly > pageHeight - 90 {
                        context.beginPage()
                        ly = topMargin
                    }
                    let unitCost = lineCostCents(line, in: count)
                    let record = itemTypeRecord(by: line.itemTypeId)
                    let star = (record?.costIsEstimate == true) ? " *" : ""
                    _ = draw(itemTypeName(by: line.itemTypeId) + star, x: col1, y: ly, attributes: bodyAttributes)
                    _ = draw("\(line.qty)", x: col2, y: ly, attributes: bodyAttributes)
                    _ = draw(InventoryFormat.dollars(unitCost), x: col3, y: ly, attributes: bodyAttributes)
                    _ = draw(InventoryFormat.dollars(line.qty * unitCost), x: col4, y: ly, attributes: bodyAttributes)
                    ly += 15
                }
                ly += lineSpacing
                let subtotal = locationSubtotal(count: count, locationId: location.id)
                ly += draw("Location subtotal: \(subtotal.units) units — \(InventoryFormat.dollars(subtotal.cents))", x: col1, y: ly, attributes: boldBodyAttributes) + lineSpacing
                _ = draw("Snapshot of where goods were sitting on the count date — NOT sales-by-location data. Stock moves between locations untracked; units sold is only valid in aggregate.", x: leftMargin, y: pageHeight - 50, attributes: smallAttributes)
            }

            // ============ UNITS SOLD PAGE (aggregate only) ============
            if count.type == .yearEnd && count.status == .finalized {
                context.beginPage()
                var uy: CGFloat = topMargin
                uy += draw("Units Sold — \(year) (aggregate only)", x: leftMargin, y: uy, attributes: headerAttributes) + lineSpacing
                uy += draw("Derived: beginning + purchased − ending = sold. No sales were recorded.", x: leftMargin, y: uy, attributes: smallAttributes) + sectionSpacing

                let col1 = leftMargin
                let col2 = leftMargin + maxWidth * 0.50
                let col3 = leftMargin + maxWidth * 0.63
                let col4 = leftMargin + maxWidth * 0.76
                let col5 = leftMargin + maxWidth * 0.89
                _ = draw("Item type", x: col1, y: uy, attributes: boldBodyAttributes)
                _ = draw("Begin", x: col2, y: uy, attributes: boldBodyAttributes)
                _ = draw("Bought", x: col3, y: uy, attributes: boldBodyAttributes)
                _ = draw("End", x: col4, y: uy, attributes: boldBodyAttributes)
                _ = draw("Sold", x: col5, y: uy, attributes: boldBodyAttributes)
                uy += 16

                var typeIds = Set<String>()
                for line in count.lines { typeIds.insert(line.itemTypeId) }
                for item in inventoryPurchaseItems(year: year) {
                    for line in item.lines { typeIds.insert(line.itemTypeId) }
                }
                if let anchor = anchorCount(forYear: year) {
                    for line in anchor.lines where line.qty > 0 { typeIds.insert(line.itemTypeId) }
                }
                let sortedIds = typeIds.sorted { itemTypeName(by: $0) < itemTypeName(by: $1) }
                for typeId in sortedIds {
                    if uy > pageHeight - 90 {
                        context.beginPage()
                        uy = topMargin
                    }
                    let begin = anchorQty(typeId: typeId, forYear: year)
                    let bought = purchasedQty(typeId: typeId, year: year)
                    let end = count.lines.filter { $0.itemTypeId == typeId }.reduce(0) { $0 + $1.qty }
                    let sold = begin + bought - end
                    _ = draw(itemTypeName(by: typeId), x: col1, y: uy, attributes: bodyAttributes)
                    _ = draw("\(begin)", x: col2, y: uy, attributes: bodyAttributes)
                    _ = draw("\(bought)", x: col3, y: uy, attributes: bodyAttributes)
                    _ = draw("\(end)", x: col4, y: uy, attributes: bodyAttributes)
                    _ = draw("\(sold)", x: col5, y: uy, attributes: sold < 0 ? boldBodyAttributes : bodyAttributes)
                    uy += 15
                }
            }
        }
        return data
    }
}
