//
//  AddItemModel.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 12/19/23.
//

import Foundation
struct AddItemModel {
    var sentenceElements: [SentenceElement]

    init() {
        // Default to business case
        sentenceElements = [
            .button("Who ▼", action: {/* Action */}, size: CGSize(width: 100, height: 30)),
            .text(" paid ", size: CGSize(width: 40, height: 30)),
            .textField("what", "", size: CGSize(width: 100, height: 30)),
            .text(" to ", size: CGSize(width: 20, height: 30)),
            .button("whom ▼", action: {/* Action */}, size: CGSize(width: 100, height: 30)),
            .text(" for ", size: CGSize(width: 30, height: 30)),
            .button("what tax reason ▼", action: {/* Action */}, size: CGSize(width: 100, height: 30))
            // Add more elements as needed for the business case
        ]
    }

    mutating func updateElement(at index: Int, with newElement: SentenceElement) {
        // Ensure the index is valid
        guard sentenceElements.indices.contains(index) else { return }
        sentenceElements[index] = newElement
    }

    // Add logic to calculate minimum widths based on content, if needed
}

enum SentenceElement {
    case text(String, size: CGSize)
    case button(String, action: () -> Void, size: CGSize)
    case textField(String, String, size: CGSize) // Placeholder and current text

    var id: String {
        switch self {
        case .text(let text, _):
            return "text-\(text)"
        case .button(let title, _, _):
            return "button-\(title)"
        case .textField(let placeholder, _, _):
            return "textField-\(placeholder)"
        }
    }
    
    var size: CGSize {
        switch self {
        case .text(_, let size),
                .button(_, _, let size),
                .textField(_, _, let size):
            return size
        }
    }
}
