//
//  TFCurrencyGallonsOdo.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import Foundation
import SwiftUI

struct CurrencyTextField: View {
    @Binding var value: String
    private let formatter: NumberFormatter
    private let maxDigits = 10
    var placeholder: String

    init(value: Binding<String>, placeholder: String = "what") {
        self._value = value
        self.placeholder = placeholder
        self.formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if value.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.BizzyColor.whatGreen)
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            TextField("", text: $value)
                .foregroundColor(Color.BizzyColor.whatGreen)
                .keyboardType(.decimalPad)
                .onChange(of: value) { newValue, _ in
                    formatCurrencyInput(newValue)
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        }
    }

    private func formatCurrencyInput(_ input: String) {
        let numericString = input.filter { "0123456789".contains($0) }
        if let intValue = Int(numericString), intValue < Int(pow(10.0, Double(maxDigits))) {
            let centsValue = Double(intValue) / 100.0
            if let formattedString = formatter.string(from: NSNumber(value: centsValue)) {
                value = formattedString
            }
        }
    }
}

struct GallonsTextField: View {
    @Binding var value: String
    private let formatter: NumberFormatter
    private let maxDigits = 10
    var placeholder: String

    init(value: Binding<String>, placeholder: String = "how many") {
        self._value = value
        self.placeholder = placeholder
        self.formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 3
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if value.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.BizzyColor.darkerGreen)
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            TextField("", text: $value)
                .foregroundColor(Color.BizzyColor.darkerGreen)
                .keyboardType(.decimalPad)
                .onChange(of: value) { newValue, _ in
                    formatGallonsInput(newValue)
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        }
    }

    private func formatGallonsInput(_ input: String) {
        let numericString = input.filter { "0123456789".contains($0) }
        if let intValue = Int(numericString), intValue < Int(pow(10.0, Double(maxDigits))) {
            let gallonsValue = Double(intValue) / 1000.0 // Starting with three decimal points
            if let formattedString = formatter.string(from: NSNumber(value: gallonsValue)) {
                value = formattedString
            }
        }
    }
}

struct OdometerTextField: View {
    @Binding var value: String
    private let formatter: NumberFormatter
    private let maxDigits = 10
    var placeholder: String

    init(value: Binding<String>, placeholder: String = "odometer") {
        self._value = value
        self.placeholder = placeholder
        self.formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0 // No fractional part
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if value.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.BizzyColor.grey)
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            TextField("", text: $value)
                .foregroundColor(Color.BizzyColor.grey)
                .keyboardType(.numberPad)
                .onChange(of: value) { newValue, _ in
                    formatOdometerInput(newValue)
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        }
    }

    private func formatOdometerInput(_ input: String) {
        let numericString = input.filter { "0123456789".contains($0) }
        if let intValue = Int(numericString), intValue < Int(pow(10.0, Double(maxDigits))) {
            if let formattedString = formatter.string(from: NSNumber(value: intValue)) {
                value = formattedString
            }
        }
    }
}

enum Align: String, CaseIterable, Identifiable {
    case top, bottom, center, firstTextBaseline, lastTextBaseline

    var id: Self { self }

    var alignment: VerticalAlignment {
        switch self {
        case .top:
            return .top
        case .bottom:
            return .bottom
        case .center:
            return .center
        case .firstTextBaseline:
            return .firstTextBaseline
        case .lastTextBaseline:
            return .lastTextBaseline
        }
    }
}

enum ItemType: String, CaseIterable, Identifiable, Codable {
    case business = "Business"
    case personal = "Personal"
    case fuel = "Fuel"
    
    var id: String { self.rawValue }
}
