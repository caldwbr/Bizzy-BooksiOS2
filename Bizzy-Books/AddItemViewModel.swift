//
//  AddItemViewModel.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 12/19/23.
//

import Foundation
import Combine
import SwiftUI
//petrsima@icloud.com
class AddItemViewModel: ObservableObject {
    
    //TODO: consider deriving this from itemType instead of caching separately
    @Published var model: AddItemModel
    

//    var sentenceElements: [String] {
//        switch itemType {
//        case .business:
//            return  [.button("business", action: {})]
//        case .personal:
//            return [.button("personal", action: {})]
//        case .fuel:
//            return [.button("fueld", action: {})]
//        }
//    }
    
    @Published var itemType = ItemType.business {
        didSet {
            updateSentenceElements()
        }
    }
    
    private func updateSentenceElements() {
        switch itemType {
        case .business:
            model.sentenceElements = [.button("business", action: {})]
        case .personal:
            model.sentenceElements = [.button("personal", action: {})]
        case .fuel:
            model.sentenceElements = [.button("fueld", action: {})]
        }
    }
    
    init() {
        self.model = AddItemModel()
        
        updateSentenceElements()
    }
    
    // Functions to handle user interactions, like updating elements
    func updateElement(at index: Int, with newElement: SentenceElement) {
        model.updateElement(at: index, with: newElement)
    }

    // Additional functionality as required by your app
    func saveItem() {
        
    }
}

//struct SentenceElement: Identifiable {
//    var id = UUID()
//    var value: String
//}

enum ItemType: String, CaseIterable, Identifiable {
    case business = "Business"
    case personal = "Personal"
    case fuel = "Fuel"
    
    var id: String { self.rawValue }

}


