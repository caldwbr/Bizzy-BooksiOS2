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
    @Published var itemType = ItemType.business {
        didSet {
            
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
}



