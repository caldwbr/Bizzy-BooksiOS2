//
//  AddItemViewModel.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 12/19/23.
//

import Foundation
import Combine

class AddItemViewModel: ObservableObject {
    @Published var model = AddItemModel()
    @Published var selectedType: ItemType = .business
    @Published var sentenceItems: [Item] = []
    
    init() {
        loadItems()
    }
    
    func loadItems() {
        sentenceItems = [
            Item(value: "Example 1"),
            Item(value: "Example 2")
        ]
    }
    
    // Functions to handle user interactions, like updating elements
    func updateElement(at index: Int, with newElement: SentenceElement) {
        model.updateElement(at: index, with: newElement)
    }

    // Additional functionality as required by your app
    func saveItem() {
        
    }
}

struct Item: Identifiable {
    var id = UUID()
    var value: String
}

enum ItemType: String, CaseIterable {
    case business = "Business"
    case personal = "Personal"
    case fuel = "Fuel"
}

