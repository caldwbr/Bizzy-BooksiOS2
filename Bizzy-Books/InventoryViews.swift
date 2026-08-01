//
//  InventoryViews.swift
//  Bizzy-Books
//
//  All retail-mode inventory UI: purchase line entry, inventory list,
//  locations, and the opening / year-end count flow.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseDatabase

// MARK: - Small input helpers

/// Currency field that writes whole cents. Digits-only entry, $ formatted display.
struct CentsTextField: View {
    @Binding var text: String
    @Binding var cents: Int
    var placeholder: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
            }
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .onChange(of: text) { _, newValue in
                    format(newValue)
                }
        }
    }

    private func format(_ input: String) {
        let numericString = input.filter { "0123456789".contains($0) }
        guard !numericString.isEmpty else {
            if cents != 0 { cents = 0 }
            return
        }
        if let intValue = Int(numericString), intValue < 1_000_000_000 {
            cents = intValue
            let formatted = InventoryFormat.dollars(intValue)
            if formatted != text {
                text = formatted
            }
        }
    }
}

/// Whole-number quantity field. Empty means "not counted" — never zero.
struct QtyTextField: View {
    @Binding var text: String
    var placeholder: String
    var onCommit: (String) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
            }
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .onChange(of: text) { _, newValue in
                    let digits = newValue.filter { "0123456789".contains($0) }
                    if digits != newValue {
                        text = digits
                        return
                    }
                    onCommit(digits)
                }
        }
    }
}

// MARK: - Purchase entry lines (inside AddItemView)

@MainActor
struct InventoryLinesEditor: View {
    @Bindable var model: Model
    @State private var pickingDraft: InventoryLineDraft? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shipment lines")
                .font(.headline)

            ForEach($model.inventoryLineDrafts) { $draft in
                InventoryDraftRow(draft: $draft, onPickType: {
                    pickingDraft = draft
                }, onDelete: {
                    let deletedId = draft.id
                    model.inventoryLineDrafts.removeAll { $0.id == deletedId }
                })
            }

            Button(action: {
                model.inventoryLineDrafts.append(InventoryLineDraft())
            }, label: {
                Label("Add line", systemImage: "plus.circle")
            })

            HStack {
                Text("Lines total: \(InventoryFormat.dollars(model.inventoryDraftTotalCents))")
                    .font(.subheadline)
                    .bold()
                Spacer()
            }
            if model.whatInt > 0 && model.inventoryDraftTotalCents != model.whatInt {
                Text("Lines don’t match the total paid — freight, tax, or discounts can cause this. Saving is still allowed.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            Text("Inventory is recorded today but is NOT an expense — it becomes deductible when it sells (COGS at year end).")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .onAppear {
            if model.inventoryLineDrafts.isEmpty {
                model.inventoryLineDrafts.append(InventoryLineDraft())
            }
        }
        .sheet(item: $pickingDraft) { draft in
            ItemTypePickerSheet(model: model, prefillCostCents: draft.unitCostCents) { record in
                if let index = model.inventoryLineDrafts.firstIndex(where: { $0.id == draft.id }) {
                    model.inventoryLineDrafts[index].itemTypeId = record.id
                    model.inventoryLineDrafts[index].itemTypeName = record.name
                    if model.inventoryLineDrafts[index].unitCostCents == 0 && record.lastCostCents > 0 {
                        model.inventoryLineDrafts[index].unitCostCents = record.lastCostCents
                        model.inventoryLineDrafts[index].costText = InventoryFormat.dollars(record.lastCostCents)
                    }
                }
                pickingDraft = nil
            }
        }
    }
}

/// One draft line row of a purchase being entered.
struct InventoryDraftRow: View {
    @Binding var draft: InventoryLineDraft
    var onPickType: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onPickType, label: {
                Text(draft.itemTypeName.isEmpty ? "item type ▼" : draft.itemTypeName)
                    .foregroundColor(Color.BizzyColor.taxReasonMagenta)
                    .lineLimit(1)
            })
            Spacer()
            QtyTextField(text: $draft.qtyText, placeholder: "qty") { digits in
                draft.qty = Int(digits) ?? 0
            }
            .frame(width: 50)
            CentsTextField(text: $draft.costText, cents: $draft.unitCostCents, placeholder: "cost ea")
                .frame(width: 90)
            Text(InventoryFormat.dollars(draft.extensionCents))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
            Button(action: onDelete, label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            })
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Item type picker + creator

@MainActor
struct ItemTypePickerSheet: View {
    @Bindable var model: Model
    var prefillCostCents: Int = 0
    var onSelect: (ItemTypeRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var showingNewTypeSheet = false

    private var results: [ItemTypeRecord] {
        let active = model.itemTypes.filter { $0.active }
        guard !searchQuery.isEmpty else { return active }
        return active.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search item types", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                List {
                    ForEach(results) { record in
                        Button(action: {
                            onSelect(record)
                            dismiss()
                        }, label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.name)
                                    .foregroundColor(.primary)
                                Text("\(record.category) · last cost \(InventoryFormat.dollars(record.lastCostCents))\(record.costIsEstimate ? " (est.)" : "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        })
                    }
                }
                .listStyle(.plain)

                Button(action: {
                    showingNewTypeSheet = true
                }, label: {
                    Label("New item type", systemImage: "plus")
                        .padding()
                })
            }
            .navigationTitle("Item Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewTypeSheet) {
                NewItemTypeSheet(model: model, prefillName: searchQuery, prefillCostCents: prefillCostCents) { record in
                    onSelect(record)
                    dismiss()
                }
            }
        }
    }
}

/// Minimal creation sheet (§5.2) — this is the friction point, keep it tiny.
@MainActor
struct NewItemTypeSheet: View {
    @Bindable var model: Model
    var prefillName: String = ""
    var prefillCostCents: Int = 0
    var onCreated: (ItemTypeRecord) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "Other"
    @State private var newCategory = ""
    @State private var costText = ""
    @State private var costCents = 0
    @State private var salePriceText = ""
    @State private var salePriceCents = 0
    @State private var costIsEstimate = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Type")) {
                    TextField("Name (e.g. Vanilla Essence Candle — Large)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(model.itemCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    TextField("Or new category", text: $newCategory)
                }
                Section(header: Text("Cost you paid (per unit)")) {
                    CentsTextField(text: $costText, cents: $costCents, placeholder: "unit cost — what YOU paid")
                    Toggle("Cost is an estimate (old stock, records gone)", isOn: $costIsEstimate)
                }
                Section(header: Text("Sticker price (optional)"), footer: Text("Display only, for margin insight. Never used for taxes — inventory is always valued at what you paid.")) {
                    CentsTextField(text: $salePriceText, cents: $salePriceCents, placeholder: "sale / sticker price")
                }
                Section {
                    Button("Create") {
                        let finalCategory = newCategory.trimmingCharacters(in: .whitespaces).isEmpty ? category : newCategory.trimmingCharacters(in: .whitespaces)
                        let record = model.addItemType(name: name.trimmingCharacters(in: .whitespaces), category: finalCategory, unitCostCents: costCents, salePriceCents: salePriceCents, costIsEstimate: costIsEstimate)
                        onCreated(record)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("New Item Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                name = prefillName
                if prefillCostCents > 0 {
                    costCents = prefillCostCents
                    costText = InventoryFormat.dollars(prefillCostCents)
                }
            }
        }
    }
}

@MainActor
struct EditItemTypeSheet: View {
    @Bindable var model: Model
    var record: ItemTypeRecord
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "Other"
    @State private var salePriceText = ""
    @State private var salePriceCents = 0
    @State private var costIsEstimate = false
    @State private var active = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Type")) {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(model.itemCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    Toggle("Active", isOn: $active)
                    Toggle("Cost is an estimate", isOn: $costIsEstimate)
                }
                Section(header: Text("Sticker price (optional)"), footer: Text("Display only — never used for taxes.")) {
                    CentsTextField(text: $salePriceText, cents: $salePriceCents, placeholder: "sale / sticker price")
                }
                Section {
                    Button("Save") {
                        var updated = record
                        updated.name = name
                        updated.category = category
                        updated.salePriceCents = salePriceCents
                        updated.costIsEstimate = costIsEstimate
                        updated.active = active
                        model.saveItemType(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Edit Item Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                name = record.name
                category = record.category
                salePriceCents = record.salePriceCents
                if record.salePriceCents > 0 {
                    salePriceText = InventoryFormat.dollars(record.salePriceCents)
                }
                costIsEstimate = record.costIsEstimate
                active = record.active
            }
        }
    }
}

// MARK: - Inventory home (Items / Counts)

@MainActor
struct InventoryHomeView: View {
    @Bindable var model: Model
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack {
                Picker("", selection: $tab) {
                    Text("Items").tag(0)
                    Text("Counts").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if tab == 0 {
                    InventoryItemsTab(model: model)
                } else {
                    InventoryCountsTab(model: model)
                }
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: Items tab (§5.5 — by purchase / by item type)

@MainActor
struct InventoryItemsTab: View {
    @Bindable var model: Model
    @State private var presentation = 0

    var body: some View {
        VStack {
            Picker("", selection: $presentation) {
                Text("By purchase").tag(0)
                Text("By item type").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if presentation == 0 {
                PurchasesList(model: model)
            } else {
                ItemTypeListContent(model: model)
            }
        }
    }
}

@MainActor
struct PurchasesList: View {
    @Bindable var model: Model

    private var purchases: [Item] {
        model.inventoryPurchaseItems.sorted { $0.timeStamp > $1.timeStamp }
    }

    private func formatDate(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    var body: some View {
        List {
            if purchases.isEmpty {
                Text("No inventory purchases yet. Add one with ＋ on the main screen (item type “Inventory”).")
                    .foregroundColor(.secondary)
            }
            ForEach(purchases) { item in
                DisclosureGroup {
                    ForEach(item.lines) { line in
                        HStack {
                            Text(line.itemTypeName.isEmpty ? model.itemTypeName(by: line.itemTypeId) : line.itemTypeName)
                                .font(.subheadline)
                            Spacer()
                            Text("\(line.qty) × \(InventoryFormat.dollars(line.unitCostCents)) = \(InventoryFormat.dollars(line.extensionCents))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.whom.isEmpty ? "Purchase" : item.whom)
                                .font(.headline)
                            Text(formatDate(item.timeStamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(InventoryFormat.dollars(item.what))
                            .bold()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

@MainActor
struct ItemTypeListContent: View {
    @Bindable var model: Model
    @State private var searchQuery = ""
    @State private var editingRecord: ItemTypeRecord? = nil

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    private var results: [ItemTypeRecord] {
        let base = model.itemTypes.filter { $0.active }
        guard !searchQuery.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        VStack {
            TextField("Search item types", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            List {
                if results.isEmpty {
                    Text("No item types yet — they’re created inside a purchase or count.")
                        .foregroundColor(.secondary)
                }
                ForEach(results) { record in
                    Button(action: {
                        editingRecord = record
                    }, label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(record.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(record.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: 12) {
                                Text("bought \(currentYear): \(model.purchasedQty(typeId: record.id, year: currentYear))")
                                Text("avg cost: \(InventoryFormat.dollars(model.currentAvgCostCents(typeId: record.id)))")
                                Text("last: \(InventoryFormat.dollars(record.lastCostCents))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            if record.salePriceCents > 0 {
                                let margin = Double(record.salePriceCents) - model.currentAvgCostCents(typeId: record.id)
                                Text("sticker \(InventoryFormat.dollars(record.salePriceCents)) · margin \(InventoryFormat.dollars(margin)) — display only, not used for taxes")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            if record.costIsEstimate {
                                Text("cost is an estimate")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    })
                }
            }
            .listStyle(.plain)
        }
        .sheet(item: $editingRecord) { record in
            EditItemTypeSheet(model: model, record: record)
        }
    }
}

// MARK: Counts tab

@MainActor
struct InventoryCountsTab: View {
    @Bindable var model: Model
    @State private var showingNewCountSheet = false
    @State private var showingManualSheet = false

    var body: some View {
        List {
            Section {
                Button(action: {
                    showingNewCountSheet = true
                }, label: {
                    Label("Start a count", systemImage: "plus.circle.fill")
                })
                Button(action: {
                    showingManualSheet = true
                }, label: {
                    Label("Enter beginning/ending figures manually", systemImage: "square.and.pencil")
                })
            } footer: {
                Text("The year-end count is what makes COGS possible: whatever is missing must have sold. No count, no COGS.")
            }

            Section(header: Text("Counts")) {
                if model.inventoryCounts.isEmpty {
                    Text("No counts yet.")
                        .foregroundColor(.secondary)
                }
                ForEach(model.inventoryCounts) { count in
                    NavigationLink(destination: CountDetailView(model: model, countId: count.id)) {
                        HStack {
                            Image(systemName: count.status == .finalized ? "checkmark.seal.fill" : "clock")
                                .foregroundColor(count.status == .finalized ? .green : .orange)
                            VStack(alignment: .leading) {
                                Text(count.displayName)
                                Text(count.status == .finalized
                                     ? "Finalized — \(InventoryFormat.dollars(count.grandTotalCents)) (\(count.totalUnits) units)"
                                     : "In progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewCountSheet) {
            NewCountSheet(model: model)
        }
        .sheet(isPresented: $showingManualSheet) {
            ManualFiguresSheet(model: model)
        }
    }
}

@MainActor
struct NewCountSheet: View {
    @Bindable var model: Model
    @Environment(\.dismiss) private var dismiss
    @State private var taxYear = Calendar.current.component(.year, from: Date())
    @State private var countType: CountType = .yearEnd

    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text(countType == .opening
                                     ? "Walk every location and enter what’s on hand. This builds your item catalog and sets beginning inventory — do it once when you start using inventory tracking."
                                     : "Nominally December 31, but a few days either side is fine — it’s labeled by tax year, not date.")) {
                    Picker("Type", selection: $countType) {
                        Text("Year-end count").tag(CountType.yearEnd)
                        Text("Opening inventory").tag(CountType.opening)
                    }
                    Picker("Tax year", selection: $taxYear) {
                        ForEach(Array(2023...2060), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                }
                Section {
                    Button("Start count") {
                        _ = model.createCount(taxYear: taxYear, type: countType)
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Count")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// §7.4 escape hatch: a preparer-supplied number is enough for a correct return.
@MainActor
struct ManualFiguresSheet: View {
    @Bindable var model: Model
    @Environment(\.dismiss) private var dismiss
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var beginningText = ""
    @State private var beginningCents = 0
    @State private var endingText = ""
    @State private var endingCents = 0
    @State private var setBeginning = false
    @State private var setEnding = false

    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("Use this if you (or your preparer) already have the inventory figure and don’t want to walk the store. Value at COST you paid — never sticker price.")) {
                    Picker("Tax year", selection: $year) {
                        ForEach(Array(2023...2060), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    .onChange(of: year) { _, _ in
                        prefill()
                    }
                }
                Section(header: Text("Beginning inventory (Jan 1)")) {
                    Toggle("Set beginning manually", isOn: $setBeginning)
                    if setBeginning {
                        CentsTextField(text: $beginningText, cents: $beginningCents, placeholder: "beginning inventory at cost")
                    }
                }
                Section(header: Text("Ending inventory (Dec 31)")) {
                    Toggle("Set ending manually", isOn: $setEnding)
                    if setEnding {
                        CentsTextField(text: $endingText, cents: $endingCents, placeholder: "ending inventory at cost")
                    }
                }
                Section {
                    Button("Save") {
                        if setBeginning {
                            model.setManualBeginning(year: year, cents: beginningCents)
                        }
                        if setEnding {
                            model.setManualEnding(year: year, cents: endingCents)
                        }
                        dismiss()
                    }
                    .disabled(!setBeginning && !setEnding)
                }
            }
            .navigationTitle("Manual Figures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                prefill()
            }
        }
    }

    private func prefill() {
        if let record = model.taxYearRecord(year) {
            if record.hasBeginning {
                beginningCents = record.beginningInventoryCents
                beginningText = InventoryFormat.dollars(record.beginningInventoryCents)
            }
            if record.hasEnding {
                endingCents = record.endingInventoryCents
                endingText = InventoryFormat.dollars(record.endingInventoryCents)
            }
        }
    }
}

// MARK: - Count detail (locations, review, finalize)

@MainActor
struct CountDetailView: View {
    @Bindable var model: Model
    var countId: String
    @State private var showingAddLocation = false
    @State private var showingFinalizeConfirm = false
    @State private var pdfURL: URL? = nil

    private var count: InventoryCount? {
        model.count(by: countId)
    }

    var body: some View {
        Group {
            if let count = count {
                List {
                    Section {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(count.status == .finalized ? "Finalized (locked)" : "In progress")
                                .foregroundColor(count.status == .finalized ? .green : .orange)
                        }
                        if count.status == .inProgress {
                            DatePicker("Count date", selection: Binding(
                                get: { Date(timeIntervalSince1970: count.countDate) },
                                set: { model.updateCountDate(countId: countId, date: $0) }
                            ), displayedComponents: .date)
                        }
                        let totals = model.countTotals(count)
                        HStack {
                            Text("Running total")
                            Spacer()
                            Text("\(totals.units) units — \(InventoryFormat.dollars(totals.cents))")
                                .bold()
                        }
                    }

                    Section(header: Text("Locations — count each place you’re standing in")) {
                        ForEach(model.activeLocations) { location in
                            NavigationLink(destination: LocationCountView(model: model, countId: countId, locationId: location.id)) {
                                HStack {
                                    Image(systemName: locationIcon(count: count, locationId: location.id))
                                        .foregroundColor(locationColor(count: count, locationId: location.id))
                                    Text(location.name)
                                    Spacer()
                                    let subtotal = model.locationSubtotal(count: count, locationId: location.id)
                                    Text(subtotal.units > 0 ? "\(subtotal.units) · \(InventoryFormat.dollars(subtotal.cents))" : "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .disabled(count.status == .finalized)
                        }
                        if count.status == .inProgress {
                            Button(action: {
                                showingAddLocation = true
                            }, label: {
                                Label("Add location", systemImage: "plus")
                            })
                        }
                    }

                    if count.status == .inProgress {
                        Section(header: Text("Review")) {
                            let warnings = model.countWarnings(count)
                            if warnings.isEmpty {
                                Text("Nothing suspicious found.")
                                    .foregroundColor(.green)
                            } else {
                                ForEach(warnings, id: \.self) { warning in
                                    Label(warning, systemImage: "exclamationmark.triangle")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            Button(action: {
                                showingFinalizeConfirm = true
                            }, label: {
                                Text("Finalize count")
                                    .bold()
                            })
                            .confirmationDialog("Finalize this count? Costs are frozen, the count locks, and totals post to the tax year. You can reopen later (it’s logged).",
                                                isPresented: $showingFinalizeConfirm, titleVisibility: .visible) {
                                Button("Finalize") {
                                    model.finalizeCount(countId: countId)
                                    pdfURL = nil
                                }
                                Button("Cancel", role: .cancel) { }
                            }
                        }
                    } else {
                        Section(header: Text("Report")) {
                            if let url = pdfURL {
                                ShareLink(item: url) {
                                    Label("Share PDF report", systemImage: "square.and.arrow.up")
                                }
                            } else {
                                Button(action: {
                                    generatePDF(count)
                                }, label: {
                                    Label("Generate PDF report", systemImage: "doc.richtext")
                                })
                            }
                            Button(role: .destructive, action: {
                                model.reopenCount(countId: countId)
                                pdfURL = nil
                            }, label: {
                                Label("Reopen count (logged)", systemImage: "lock.open")
                            })
                        }
                    }
                }
                .navigationTitle(count.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink("Item types") {
                            ItemTypeListContent(model: model)
                                .navigationTitle("Reference")
                        }
                    }
                }
                .sheet(isPresented: $showingAddLocation) {
                    AddLocationSheet(model: model)
                }
            } else {
                Text("Count not found.")
            }
        }
    }

    private func locationIcon(count: InventoryCount, locationId: String) -> String {
        if count.doneLocationIds.contains(locationId) { return "checkmark.circle.fill" }
        if count.lines.contains(where: { $0.locationId == locationId }) { return "clock.fill" }
        return "circle"
    }

    private func locationColor(count: InventoryCount, locationId: String) -> Color {
        if count.doneLocationIds.contains(locationId) { return .green }
        if count.lines.contains(where: { $0.locationId == locationId }) { return .orange }
        return .gray
    }

    private func generatePDF(_ count: InventoryCount) {
        guard let data = model.generateInventoryCountPDF(count) else { return }
        do {
            pdfURL = try model.savePDFDataToTemporaryFile(data)
        } catch {
            print("Error saving count PDF: \(error)")
        }
    }
}

@MainActor
struct AddLocationSheet: View {
    @Bindable var model: Model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Location name", text: $name)
                TextField("Note (optional)", text: $note)
                Button("Add") {
                    _ = model.addLocation(name: name.trimmingCharacters(in: .whitespaces), note: note)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Per-location count screen (§6.2)

@MainActor
struct LocationCountView: View {
    @Bindable var model: Model
    var countId: String
    var locationId: String
    @State private var searchQuery = ""
    @State private var extraTypeIds: [String] = []
    @State private var showingTypePicker = false

    private var count: InventoryCount? {
        model.count(by: countId)
    }

    private var locationName: String {
        model.inventoryLocations.first(where: { $0.id == locationId })?.name ?? "Location"
    }

    private var visibleTypes: [ItemTypeRecord] {
        guard let count = count else { return [] }
        var types = model.typesForCount(count)
        for typeId in extraTypeIds {
            if !types.contains(where: { $0.id == typeId }), let record = model.itemTypeRecord(by: typeId) {
                types.append(record)
            }
        }
        if !searchQuery.isEmpty {
            types = types.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        return types
    }

    private var groupedTypes: [(category: String, types: [ItemTypeRecord])] {
        let grouped = Dictionary(grouping: visibleTypes, by: { $0.category })
        return grouped.keys.sorted().map { key in
            (category: key, types: grouped[key]!.sorted { $0.name.lowercased() < $1.name.lowercased() })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search item types", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .padding(.top, 8)

            List {
                if visibleTypes.isEmpty {
                    Text("Nothing to count yet — add item types as you find them.")
                        .foregroundColor(.secondary)
                }
                ForEach(groupedTypes, id: \.category) { group in
                    Section(header: Text(group.category)) {
                        ForEach(group.types) { record in
                            CountLineRow(model: model, countId: countId, locationId: locationId, record: record)
                        }
                    }
                }
                Section {
                    Button(action: {
                        showingTypePicker = true
                    }, label: {
                        Label("Add item type not on this list", systemImage: "plus")
                    })
                }
            }
            .listStyle(.insetGrouped)

            // Running subtotal + done toggle, pinned at the bottom.
            if let count = count {
                let subtotal = model.locationSubtotal(count: count, locationId: locationId)
                VStack(spacing: 6) {
                    HStack {
                        Text("\(locationName): \(subtotal.units) units — \(InventoryFormat.dollars(subtotal.cents))")
                            .font(.headline)
                        Spacer()
                    }
                    Toggle("Mark this location done", isOn: Binding(
                        get: { count.doneLocationIds.contains(locationId) },
                        set: { model.setLocationDone(countId: countId, locationId: locationId, done: $0) }
                    ))
                    .font(.subheadline)
                }
                .padding()
                .background(Color.offWhiteGray)
            }
        }
        .navigationTitle(locationName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTypePicker) {
            ItemTypePickerSheet(model: model) { record in
                if !extraTypeIds.contains(record.id) {
                    extraTypeIds.append(record.id)
                }
            }
        }
    }
}

/// One item type at one location. Blank = not counted here. An explicit 0
/// (typed, or via “None”) = counted, none here. Autosaves on every change.
@MainActor
struct CountLineRow: View {
    @Bindable var model: Model
    var countId: String
    var locationId: String
    var record: ItemTypeRecord

    @State private var qtyText = ""
    @State private var loaded = false
    @State private var editingCost = false
    @State private var overrideText = ""
    @State private var overrideCents = 0

    private var existingLine: CountLine? {
        model.countLine(countId: countId, itemTypeId: record.id, locationId: locationId)
    }

    private var displayCostCents: Int {
        if let line = existingLine, let count = model.count(by: countId) {
            return model.lineCostCents(line, in: count)
        }
        if let count = model.count(by: countId) {
            return Int(model.avgCostCents(typeId: record.id, forYear: count.taxYear).rounded())
        }
        return record.lastCostCents
    }

    private var isFinalized: Bool {
        model.count(by: countId)?.status == .finalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.name)
                        .font(.body)
                    HStack(spacing: 4) {
                        Text("cost you paid: \(InventoryFormat.dollars(displayCostCents))\(record.costIsEstimate ? " (est.)" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !isFinalized {
                            Button(action: {
                                overrideCents = displayCostCents
                                overrideText = InventoryFormat.dollars(displayCostCents)
                                editingCost.toggle()
                            }, label: {
                                Image(systemName: "pencil.circle")
                                    .font(.caption)
                            })
                            .buttonStyle(.borderless)
                        }
                    }
                }
                Spacer()
                if !isFinalized {
                    Button("None") {
                        qtyText = "0"
                        commitQty("0")
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                QtyTextField(text: $qtyText, placeholder: "—") { digits in
                    commitQty(digits)
                }
                .frame(width: 64)
                .multilineTextAlignment(.trailing)
                .disabled(isFinalized)
                if let line = existingLine {
                    Text(InventoryFormat.dollars(line.qty * displayCostCents))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                } else {
                    Text("not counted")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(width: 70, alignment: .trailing)
                }
            }
            if editingCost && !isFinalized {
                HStack {
                    Text("Override cost:")
                        .font(.caption)
                    CentsTextField(text: $overrideText, cents: $overrideCents, placeholder: "cost you paid")
                        .frame(width: 100)
                    Button("Apply") {
                        applyOverride()
                        editingCost = false
                    }
                    .font(.caption)
                    Button("Clear") {
                        clearOverride()
                        editingCost = false
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            if !loaded {
                loaded = true
                if let line = existingLine {
                    qtyText = String(line.qty)
                }
            }
        }
    }

    private func commitQty(_ digits: String) {
        guard !isFinalized else { return }
        if digits.isEmpty {
            // Blank = not counted here (remove any line).
            if let line = existingLine {
                model.removeCountLine(countId: countId, lineId: line.id)
            }
            return
        }
        let qty = Int(digits) ?? 0
        var line = existingLine ?? CountLine(itemTypeId: record.id, locationId: locationId, qty: qty)
        line.qty = qty
        model.saveCountLine(countId: countId, line: line)
    }

    private func applyOverride() {
        guard var line = existingLine else {
            // No quantity yet — create an explicit 0 line carrying the override.
            var line = CountLine(itemTypeId: record.id, locationId: locationId, qty: 0)
            line.unitCostUsedCents = overrideCents
            line.costOverridden = true
            model.saveCountLine(countId: countId, line: line)
            qtyText = "0"
            return
        }
        line.unitCostUsedCents = overrideCents
        line.costOverridden = true
        model.saveCountLine(countId: countId, line: line)
    }

    private func clearOverride() {
        guard var line = existingLine else { return }
        line.costOverridden = false
        model.saveCountLine(countId: countId, line: line)
    }
}
