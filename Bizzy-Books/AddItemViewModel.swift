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
extension AddItemView {
    @MainActor class ViewModel: ObservableObject {
        
        @Published var displaySentence: [(String?, String)]
        @Published var selectedTaxReasonIndex: Int = 0
        @Published var selectedTaxReason: TaxReason = .placeholder
        @Published var selectedPersonalReasonIndex: Int = 0
        @Published var selectedPersonalReason: PersonalReason = .placeholder
        @Published var selectedWorkersCompReasonIndex: Int = 0
        @Published var selectedWorkersCompReason: WorkersComp = .placeholder
        @Published var itemType = ItemType.business {
            didSet {
                
            }
        }
        @Published var align = Align.center
        @Published var currencyValue: String = ""
        @Published var gallonsValue: String = ""
        @Published var odometerValue: String = ""
        @Published var notesValue: String = ""
        @Published var showWhoSearchView = false
        @Published var showWhomSearchView = false
        @Published var showVehicleSearchView = false
        @Published var showProjectSearchView = false
        @Published var whichSentence: Int = 1
        @Published var what: Int = 0
        @Published var showWorkersCompToggle = false
        @Published var incursWorkersComp = false
        
        //Previously @Binding in AddItemView
        @Published var selectedWho: String = ""
        @Published var selectedWhoUID: String? = nil
        @Published var selectedWhom: String = ""
        @Published var selectedWhomUID: String? = nil
        @Published var selectedVehicle: String = ""
        @Published var selectedVehicleUID: String? = nil
        @Published var selectedProject: String = ""
        @Published var selectedProjectUID: String? = nil
        @Published var selectedTaxReasonUID: String? = nil
        @Published var selectedPersonalReasonUID: String? = nil
        
        init() {
            displaySentence = Sentences.one
            whichSentence = 1
        }
        
        func createNewItemWithLocation() -> Item {
                // Here, you can create a new 'Item' with location information.
                // You can access necessary properties from your ViewModel and UI fields.
                
                // For example:
                let newItem = Item(
                    itemType: itemType,
                    who: displaySentence[0].1,
                    whoID: displaySentence[0].0!,
                    what: what,
                    whom: displaySentence[4].1,
                    whomID: displaySentence[4].0!
                )
                
                // You can then return the newly created 'Item'.
                return newItem
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
    }
}
