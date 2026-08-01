//
//  Bizzy_BooksTests.swift
//  Bizzy-BooksTests
//
//  Created by Brad Caldwell on 11/22/23.
//

import XCTest
@testable import Bizzy_Books

final class Bizzy_BooksTests: XCTestCase {

    // MARK: - Helpers

    @MainActor
    private func makeItem(type: ItemType, taxReasonInt: Int = 0, what: Int, lines: [InventoryPurchaseLine] = []) -> Item {
        var item = Item(latitude: 0, longitude: 0, itemType: type, notes: "", what: what, whom: "Vendor", whomID: "v1", personalReasonInt: 0, taxReasonInt: taxReasonInt, vehicleName: "", vehicleID: "", workersComp: false, projectName: "Overhead", projectID: "OverheadID", howMany: 0, odometer: 0)
        item.lines = lines
        return item
    }

    /// Spec §8 regression test: inventory purchases must NEVER appear in the
    /// Part II expense totals — if they land in both COGS and expenses, the
    /// return double-counts the deduction.
    @MainActor
    func testInventoryPurchasesExcludedFromExpenses() throws {
        let model = Model()
        model.businessType = .retail
        let year = Calendar.current.component(.year, from: Date())
        model.items = [
            makeItem(type: .business, taxReasonInt: 1, what: 100_000),  // $1,000 income
            makeItem(type: .business, taxReasonInt: 2, what: 20_000),   // $200 supplies
            makeItem(type: .inventory, what: 50_000,                    // $500 inventory purchase
                     lines: [InventoryPurchaseLine(itemTypeId: "t1", itemTypeName: "Candles", qty: 10, unitCostCents: 5_000)])
        ]
        model.calculateTaxData(forYear: year)

        XCTAssertEqual(model.tdGrossIncome, 100_000)
        XCTAssertEqual(model.tdSupplies, 20_000, "Supplies expense behavior unchanged")
        XCTAssertEqual(model.tdTotalExpenses, 20_000, "Inventory must NOT appear in Part II expense totals")
        XCTAssertEqual(model.tdInventoryPurchases, 50_000, "Inventory posts to the asset bucket")
        // No ending inventory on record yet → no COGS deduction is taken.
        XCTAssertEqual(model.tdCOGS, 0)
        XCTAssertFalse(model.tdCogsAvailable)
        // Net profit is unchanged by the inventory purchase (asset, not expense).
        XCTAssertEqual(model.tdNetIncome, 80_000)
    }

    /// Contracting mode must behave identically to the pre-inventory build.
    @MainActor
    func testContractingModeUnchanged() throws {
        let model = Model()
        model.businessType = .contracting
        let year = Calendar.current.component(.year, from: Date())
        model.items = [
            makeItem(type: .business, taxReasonInt: 1, what: 100_000),
            makeItem(type: .business, taxReasonInt: 2, what: 20_000),
        ]
        model.calculateTaxData(forYear: year)
        XCTAssertEqual(model.tdCOGS, 0)
        XCTAssertEqual(model.tdGrossProfit, 100_000)
        XCTAssertEqual(model.tdTotalExpenses, 20_000)
        XCTAssertEqual(model.tdNetIncome, 80_000)
    }

    /// Spec §10 acceptance: 40 @ $140 then 20 @ $150 → weighted average
    /// $143.33 (not last cost, not simple mean).
    @MainActor
    func testWeightedAverageCost() throws {
        let model = Model()
        model.businessType = .retail
        let year = Calendar.current.component(.year, from: Date())
        let typeId = "candle-large"
        model.items = [
            makeItem(type: .inventory, what: 40 * 14_000, lines: [InventoryPurchaseLine(itemTypeId: typeId, itemTypeName: "Large Candle", qty: 40, unitCostCents: 14_000)]),
            makeItem(type: .inventory, what: 20 * 15_000, lines: [InventoryPurchaseLine(itemTypeId: typeId, itemTypeName: "Large Candle", qty: 20, unitCostCents: 15_000)]),
        ]
        let avg = model.avgCostCents(typeId: typeId, forYear: year)
        XCTAssertEqual(avg, 14333.333, accuracy: 0.34, "Weighted moving average ≈ $143.33")
    }

    /// Spec §10 acceptance: beginning 10 + purchased 60 − ending 9 = 61 sold.
    @MainActor
    func testUnitsSoldDerivation() throws {
        let model = Model()
        model.businessType = .retail
        let year = Calendar.current.component(.year, from: Date())
        let typeId = "t1"

        var anchor = InventoryCount(taxYear: year - 1, type: .yearEnd)
        anchor.status = .finalized
        anchor.lines = [CountLine(itemTypeId: typeId, locationId: "loc1", qty: 10, unitCostUsedCents: 14_000)]
        anchor.grandTotalCents = 10 * 14_000

        var ending = InventoryCount(taxYear: year, type: .yearEnd)
        ending.status = .finalized
        ending.lines = [CountLine(itemTypeId: typeId, locationId: "loc1", qty: 9, unitCostUsedCents: 14_333)]
        ending.grandTotalCents = 9 * 14_333

        model.inventoryCounts = [anchor, ending]
        model.items = [
            makeItem(type: .inventory, what: 60 * 14_000, lines: [InventoryPurchaseLine(itemTypeId: typeId, itemTypeName: "T", qty: 60, unitCostCents: 14_000)])
        ]

        XCTAssertEqual(model.unitsSold(typeId: typeId, year: year), 61)
    }

    /// Ending inventory from a finalized count feeds COGS, and COGS reduces
    /// net income: B 0 + P $6,000 − E $1,289.97 = COGS $4,710.03.
    @MainActor
    func testCOGSComputation() throws {
        let model = Model()
        model.businessType = .retail
        let year = Calendar.current.component(.year, from: Date())
        let typeId = "t1"

        var ending = InventoryCount(taxYear: year, type: .yearEnd)
        ending.status = .finalized
        ending.lines = [CountLine(itemTypeId: typeId, locationId: "loc1", qty: 9, unitCostUsedCents: 14_333)]
        ending.grandTotalCents = 9 * 14_333
        model.inventoryCounts = [ending]

        model.items = [
            makeItem(type: .business, taxReasonInt: 1, what: 1_000_000),   // $10,000 receipts
            makeItem(type: .inventory, what: 600_000,
                     lines: [InventoryPurchaseLine(itemTypeId: typeId, itemTypeName: "T", qty: 40, unitCostCents: 15_000)])
        ]
        model.calculateTaxData(forYear: year)

        XCTAssertTrue(model.tdCogsAvailable)
        XCTAssertEqual(model.tdEndingInventory, 128_997)
        XCTAssertEqual(model.tdCOGS, 600_000 - 128_997)
        XCTAssertEqual(model.tdGrossProfit, 1_000_000 - model.tdCOGS)
        XCTAssertEqual(model.tdNetIncome, model.tdGrossProfit)
    }

    /// Spec §5.4 hard rule: sale price must never touch a tax figure.
    @MainActor
    func testSalePriceNeverTouchesTaxMath() throws {
        let model = Model()
        model.businessType = .retail
        let year = Calendar.current.component(.year, from: Date())
        let typeId = "t1"
        var record = ItemTypeRecord(name: "Candle", category: "Candles", lastCostCents: 14_000)
        record.id = typeId
        model.itemTypes = [record]
        model.items = [
            makeItem(type: .inventory, what: 10 * 14_000, lines: [InventoryPurchaseLine(itemTypeId: typeId, itemTypeName: "Candle", qty: 10, unitCostCents: 14_000)])
        ]
        model.calculateTaxData(forYear: year)
        let purchasesBefore = model.tdInventoryPurchases
        let cogsBefore = model.tdCOGS
        let avgBefore = model.avgCostCents(typeId: typeId, forYear: year)

        // Populate an outrageous sticker price…
        model.itemTypes[0].salePriceCents = 999_999

        model.calculateTaxData(forYear: year)
        // …and no tax figure anywhere may change.
        XCTAssertEqual(model.tdInventoryPurchases, purchasesBefore)
        XCTAssertEqual(model.tdCOGS, cogsBefore)
        XCTAssertEqual(model.avgCostCents(typeId: typeId, forYear: year), avgBefore)
    }
}
