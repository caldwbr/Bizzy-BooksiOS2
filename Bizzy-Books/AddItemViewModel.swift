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
    @Published var selectedTaxReasonIndex: Int = 0
    @Published var selectedTaxReason: TaxReason = .placeholder
    @Published var selectedPersonalReasonIndex: Int = 0
    @Published var selectedPersonalReason: PersonalReason = .placeholder
    @Published var selectedWorkersCompReasonIndex: Int = 0
    @Published var selectedWorkersCompReason: WorkersComp = .placeholder
    @Published var model: AddItemModel
    @Published var itemType = ItemType.business {
        didSet {
            updateSentenceElements()
            print("Yo Color: \(model.sentenceElements[0].semanticType.color)")
        }
    }
    
    private func updateSentenceElements() {
        model.sentenceElements = [
            .button("Who ▼", semanticType: .who, action: {}, size: sizeForElementContent("Who ▼", semanticType: .who)),
            .text(" paid ", size: sizeForElementContent(" paid ", semanticType: .text)),
            .textField("what", semanticType: .what, text: "", size: sizeForElementContent("what", semanticType: .what)),
            .text(" to ", size: sizeForElementContent(" to ", semanticType: .text)),
            .button("whom ▼", semanticType: .whom, action: {}, size: sizeForElementContent("whom ▼", semanticType: .whom))
        ]

        switch itemType {
        case .business:
            model.sentenceElements.append(.text(" for ", size: sizeForElementContent(" for ", semanticType: .text)))
            model.sentenceElements.append(.button("tax reason", semanticType: .taxReason, action: {}, size: sizeForElementContent("tax reason", semanticType: .taxReason)))
            model.sentenceElements.append(.button("project ▼", semanticType: .project, action: {}, size: sizeForElementContent("project ▼", semanticType: .project)))
        case .personal:
            model.sentenceElements.append(.text(" for ", size: sizeForElementContent(" for ", semanticType: .text)))
            model.sentenceElements.append(.button("personal reason", semanticType: .personalReason, action: {}, size: sizeForElementContent("personal reason", semanticType: .personalReason)))
        case .fuel:
            model.sentenceElements.append(.text(" for ", size: sizeForElementContent(" for ", semanticType: .text)))
            model.sentenceElements.append(.textField("how many", semanticType: .forHowMany, text: "", size: sizeForElementContent("how many", semanticType: .forHowMany)))
            model.sentenceElements.append(.text(" gallons of fuel in ", size: sizeForElementContent(" gallons of fuel in ", semanticType: .text)))
            model.sentenceElements.append(.button("which vehicle ▼", semanticType: .whichVehicle, action: {}, size: sizeForElementContent("which vehicle ▼", semanticType: .whichVehicle)))
            model.sentenceElements.append(.textField("odometer", semanticType: .odometer, text: "", size: sizeForElementContent("odometer", semanticType: .odometer)))
        }
    }
    
    func sizeForElementContent(_ content: String, semanticType: SentenceElement.SemanticType) -> CGSize {
        // Calculate the size based on content and type
        // This is a placeholder - you'll need to implement actual size calculation
        let width = CGFloat(content.count * 10) // Example: 10 points per character
        let height: CGFloat = 30 // Example: fixed height
        return CGSize(width: width, height: height)
    }


    
    func updateSelectedPersonalReason(newReason: PersonalReason) {
        selectedPersonalReason = newReason
        selectedPersonalReasonIndex = PersonalReason.displayCases.firstIndex(of: newReason) ?? 0
    }
    
    func updateSelectedTaxReason(newReason: TaxReason) {
        selectedTaxReason = newReason
        selectedTaxReasonIndex = TaxReason.displayCases.firstIndex(of: newReason) ?? 0
    }
    
    func updateSelectedWorkersComp(newReason: WorkersComp) {
        selectedWorkersCompReason = newReason
        selectedWorkersCompReasonIndex = WorkersComp.displayCases.firstIndex(of: newReason) ?? 0
    }
    
    func updateSentenceElementPicker(at index: Int, with newIndex: Int) {
        guard model.sentenceElements.indices.contains(index) else { return }
        var element = model.sentenceElements[index]
        
        switch element.type {
        case .picker(let options, _, let size):
            // Update only the selected index of the picker
            element.type = .picker(options, newIndex, size)
        default:
            // Handle other types or do nothing if they're not applicable
            break
        }
        
        model.sentenceElements[index] = element
    }
    
    init() {
        self.model = AddItemModel()
        
        updateSentenceElements()
    }
    
    // Functions to handle user interactions, like updating elements
    func updateElement(at index: Int, with newElement: SentenceElement) {
        model.updateElement(at: index, with: newElement)
    }
    
    func updateElementSize(at index: Int, newSize: CGSize) {
        guard model.sentenceElements.indices.contains(index) else { return }
        var element = model.sentenceElements[index]
        
        switch element.type {
        case .text(let text, _):
            element.type = .text(text, size: newSize)
        case .button(let title, let action, _):
            element.type = .button(title, action: action, size: newSize)
        case .textField(let placeholder, let text, _):
            element.type = .textField(placeholder, text, size: newSize)
        case .picker(let options, let selectedIndex, _):
            element.type = .picker(options, selectedIndex, newSize)
        }
        
        model.sentenceElements[index] = element
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

