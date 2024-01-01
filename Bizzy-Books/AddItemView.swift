import SwiftUI

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

struct AddItemView: View {
    @ObservedObject var viewModel: AddItemViewModel
    @Binding var itemType: ItemType
    @State var align = Align.center
    @State var currencyValue: String = ""
    @State var gallonsValue: String = ""
    @State var odometerValue: String = ""
    @State var notesValue: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("Add Item")
                    .font(.largeTitle)
                    .padding()
                Button(action: {}, label: {
                    Text("Save")
                })
                .font(.largeTitle)
                .padding()
            }
            Picker("Item Type", selection: $itemType) {
                ForEach(ItemType.allCases) { itemType in
                    Text(itemType.rawValue.capitalized).tag(itemType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: itemType) { oldValue, newValue in
                viewModel.itemType = newValue
            }
            TextField("Notes", text: $notesValue).padding()
            
            let layout = FlowLayout(alignment: align.alignment)
            layout {
                ForEach(viewModel.model.sentenceElements) { element in
                    switch element.type {
                    case .text(let text, _):
                        Text(text)
                            .padding()
                    case .textField(let placeholder, let text, _):
                        switch element.semanticType {
                        case .what:
                            CurrencyTextField(value: $currencyValue, placeholder: "what")
                                .padding(11)
                        case .forHowMany:
                            GallonsTextField(value: $gallonsValue, placeholder: "how many")
                                .padding(11)
                        default:
                            OdometerTextField(value: $odometerValue, placeholder: "Odometer")
                                .padding(11)
                        }
                    case .button(let title, let action, _):
                        Button(action: action, label: {
                            Text(title)
                                .padding()
                                .foregroundColor(element.semanticType.color)
                        })
                    }
                }
            }
            .animation(.default, value: align)
            .frame(maxHeight: .infinity)
        }
    }

}

struct FlowLayout: Layout {
    var alignment: VerticalAlignment
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.replacingUnspecifiedDimensions().width
        let dimensions = subviews.map { $0.dimensions(in: .unspecified) }
        return layout(dimensions: dimensions, containerWidth: containerWidth, alignment: alignment).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let dimensions = subviews.map { $0.dimensions(in: .unspecified) }
        let offsets = layout(dimensions: dimensions, containerWidth: bounds.width, alignment: alignment).offsets
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: offset.x + bounds.minX, y: offset.y + bounds.minY), proposal: .unspecified)
        }
    }
}

func layout(dimensions: [ViewDimensions], spacing: CGFloat = 10, containerWidth: CGFloat, alignment: VerticalAlignment) -> (offsets: [CGPoint], size: CGSize) {
    var result: [CGRect] = []
    var currentPosition: CGPoint = .zero
    var currentLine: [CGRect] = []
    var maxLineHeight: CGFloat = 0
    
    func flushLine() {
        currentPosition.x = 0
        let union = currentLine.union
        result.append(contentsOf: currentLine.map { rect in
            var copy = rect
            copy.origin.y += currentPosition.y - union.minY
            return copy
        })
        
        currentPosition.y += union.height + spacing
        currentLine.removeAll()
    }
    
    for dim in dimensions {
        if currentPosition.x + dim.width > containerWidth {
            flushLine()
        }
        
        currentLine.append(CGRect(x: currentPosition.x, y: dim[alignment], width: dim.width, height: dim.height))
        currentPosition.x += dim.width
        currentPosition.x += spacing
    }
    flushLine()
    
    return (result.map { $0.origin }, result.union.size)
}

extension Sequence where Element == CGRect {
    var union: CGRect {
        reduce(.null, { $0.union($1) })
    }
}

struct CurrencyTextField: View {
    @Binding var value: String
    private let formatter: NumberFormatter
    private let maxDigits = 10
    var placeholder: String

    init(value: Binding<String>, placeholder: String = "Amount") {
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
                .onChange(of: value) { newValue in
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

    init(value: Binding<String>, placeholder: String = "Gallons") {
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
                .onChange(of: value) { newValue in
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

    init(value: Binding<String>, placeholder: String = "Odometer") {
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
                .onChange(of: value) { newValue in
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
