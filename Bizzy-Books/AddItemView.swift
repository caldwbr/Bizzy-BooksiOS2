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
    @State var align = Align.top
    
    var body: some View {
        VStack {
            Text("Add Item")
                .font(.largeTitle)
                .padding()
            Button(action: {}, label: {
                Text("TEST BUTTON SUP")
                    .foregroundColor(.red)
            })
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
            
            let layout = FlowLayout(alignment: align.alignment)
            layout {
                ForEach(0..<20) { ix in
                    Text("Item \(ix)")
                        .background(Capsule()
                            .fill(Color(hue: .init(ix)/10, saturation: 0.8, brightness: 0.8)))
                }
            }
            .animation(.default, value: align)
            .frame(maxHeight: .infinity)
            
            ScrollView {
                SentenceFlowView(elements: viewModel.model.sentenceElements) { element in
                    switch element.type {
                    case .text(let text, _):
                        Text(text)
                            .padding()
                    case .textField(let placeholder, let text, _):
                        TextField(placeholder, text: .constant(text))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .foregroundColor(element.semanticType.color)
                    case .button(let title, let action, _):
                        Button(action: action, label: {
                            Text(title)
                                .foregroundColor(element.semanticType.color)
                        })
                    }
                }
                .border(Color.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
