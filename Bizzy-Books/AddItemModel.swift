//
//  AddItemModel.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 12/19/23.
//

import Foundation
import SwiftUI

struct AddItemModel {
    var sentenceElements: [SentenceElement] = []
    
    var elements: [SentenceElement] {
        return sentenceElements
    }

    mutating func updateElement(at index: Int, with newElement: SentenceElement) {
        // Ensure the index is valid
        guard sentenceElements.indices.contains(index) else { return }
        sentenceElements[index] = newElement
        // Update the element for the specified category
    }

    // Add logic to calculate minimum widths based on content, if needed
}

struct SentenceElement: Identifiable {
    
    enum SemanticType {
        case who, whom, whichVehicle, project //Button
        case text //paid, toW, forWhat, gallonsOfFuelIn
        case what, forHowMany, odometer //Numeric TextField
        case taxReason, personalReason, workersComp //picker
        
        var color: Color {
            switch self {
            case .who:
                return .BizzyColor.whoBlue
            case .what:
                return .BizzyColor.whatGreen
            case .whom:
                return .BizzyColor.whomPurple
            case .taxReason:
                return .BizzyColor.taxReasonMagenta
            case .personalReason:
                return .BizzyColor.personalReasonMagenta
            case .workersComp:
                return .BizzyColor.orange
            case .project:
                return .BizzyColor.projectBlue
            case .forHowMany:
                return .BizzyColor.darkerGreen
            case .odometer:
                return .BizzyColor.grey
            case .whichVehicle:
                return .BizzyColor.orange
            case .text:
                return .black
            }
        }
    }
    
    enum ElementType {
        case text(String, size: CGSize)
        case button(String, action: () -> Void, size: CGSize)
        case textField(String, String, size: CGSize)
        case picker([String], Int, CGSize) //Array of options and selected index
    }
    
    let semanticType: SemanticType
    var type: ElementType
    
    var id: String {
        switch type {
        case .text(let text, _):
            return "text-\(text)"
        case .button(let title, _, _):
            return "button-\(title)"
        case .textField(let placeholder, _, _):
            return "textField-\(placeholder)"
        case .picker(let options, let selectedIndex, _):
            let optionsString = options.joined(separator: "-")
            return "picker-\(semanticType)-\(optionsString)-\(selectedIndex)"
        }
    }
    
    var size: CGSize {
        switch type {
        case .text(_, let size),
             .button(_, _, let size),
             .textField(_, _, let size),
             .picker(_, _, let size):
            return size
        }
    }
    
    var value: String {
        switch type {
        case .text(let text, _),
             .button(let text, _, _),
             .textField(_, let text, _):
            return text
        case .picker(let options, let selectedIndex, _):
            return options[selectedIndex]
        }
    }
    
    init(semanticType: SemanticType, type: ElementType) {
        self.semanticType = semanticType
        self.type = type
    }
}

extension SentenceElement {
    static func button(_ value: String, semanticType: SemanticType, action: @escaping () -> Void, size: CGSize) -> Self {
        Self(semanticType: semanticType, type: .button(value, action: action, size: size))
    }
    
    static func textField(_ placeholder: String, semanticType: SemanticType, text: String, size: CGSize) -> Self {
        Self(semanticType: semanticType, type: .textField(placeholder, text, size: size))
    }
    
    static func text(_ value: String, size: CGSize) -> Self {
        Self(semanticType: .text, type: .text(value, size: size))
    }
    
    static func picker(_ options: [String], semanticType: SemanticType, selectedIndex: Int = 0, size: CGSize) -> Self {
        Self(semanticType: semanticType, type: .picker(options, selectedIndex, size))
    }
}

