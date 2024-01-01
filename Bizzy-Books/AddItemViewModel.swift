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
    @Published var itemType = ItemType.business {
        didSet {
            updateSentenceElements()
            print("Yo Color: \(model.sentenceElements[0].semanticType.color)")
        }
    }
    
    private func updateSentenceElements() {
        model.sentenceElements = [.button("Who ▼", semanticType: .who, action: {}), .text(" paid "), .textField("what", semanticType: .what, text: "", size: CGSize()), .text(" to "), .button("whom ▼", semanticType: .whom, action: {})]
        switch itemType {
        case .business:
            model.sentenceElements.append(.text(" for "))
            model.sentenceElements.append(.button("tax reason ▼", semanticType: .taxReason, action: {}))
            model.sentenceElements.append(.button("project ▼", semanticType: .project, action: {}))
        case .personal:
            model.sentenceElements.append(.text(" for "))
            model.sentenceElements.append(.button("personal reason ▼", semanticType: .personalReason, action: {}))
        case .fuel:
            model.sentenceElements.append(.text(" for "))
            model.sentenceElements.append(.textField("how many", semanticType: .forHowMany, text: "", size: CGSize()))
            model.sentenceElements.append(.text(" gallons of fuel in "))
            model.sentenceElements.append(.button("which vehicle ▼", semanticType: .whichVehicle, action: {}))
            model.sentenceElements.append(.textField("odometer", semanticType: .odometer, text: "", size: CGSize()))
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

enum ItemType: String, CaseIterable, Identifiable, Codable {
    case business = "Business"
    case personal = "Personal"
    case fuel = "Fuel"
    
    var id: String { self.rawValue }

}

