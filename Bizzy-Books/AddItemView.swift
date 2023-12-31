import SwiftUI

struct AddItemView: View {
    @ObservedObject var viewModel: AddItemViewModel
    @Binding var itemType: ItemType
    
    var body: some View {
        VStack {
            Text("Add Item")
                .font(.largeTitle)
                .padding()
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
            
            ScrollView {
                SentenceFlowView(elements: viewModel.model.sentenceElements, cell: { element in
                    switch element.type {
                    case .text(let text, _):
                        Text(text)
                            .padding()
                    case .textField(let placeholder, let text, _):
                        TextField(placeholder, text: .constant(text))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    case .button(let title, let action, _):
                        switch element.semanticType {
                        case .whom:
                            Button(action: action, label: {
                                Text(title)
                            })
                            .buttonStyle(WhomButtonStyle())
                            .padding()
                        default:
                            Button(action: {}, label: {
                                Text(title)
                            })
                            .padding()
                        }
                    }
                })
                .border(Color.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
//    private func createSentenceLayout(geometry: GeometryProxy, elements: [SentenceElement]) -> some View {
//        var widthUsed: CGFloat = 0
//        var lineHeight: CGFloat = 0 // Track the height of the current line
//        
//        return VStack(alignment: .leading, spacing: 4) { // Adjust spacing as needed
//            ForEach(elements, id: \.id) { element in
//                Group { // Wrap the entire element in a Group
//                    self.view(for: element) // Call the view-building function
//                        .padding(4) // Adjust padding as needed
//                        .alignmentGuide(.leading, computeValue: { dimension in
//                            // Check if element fits in the current line or needs a new line
//                            if widthUsed + dimension.width > geometry.size.width {
//                                widthUsed = 0 // Reset for a new line
//                                return widthUsed
//                            } else {
//                                let offset = widthUsed
//                                widthUsed += dimension.width
//                                return offset
//                            }
//                        })
//                }
//            }
//        }
//    }
//    
//    @ViewBuilder
//    private func view(for element: SentenceElement) -> some View {
//        switch element.type {
//        case .text(let text, let size):
//            Text(text)
//                .frame(width: size.width, height: size.height)
//        case .textField(let placeholder, let text, let size):
//            TextField(placeholder, text: .constant(text))
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .frame(width: size.width, height: size.height)
//        case .button(let title, let action, let size):
//            switch element.semanticType {
//            case .whom:
//                Button(action: {}, label: {
//                    Text(title)
//                })
//                .buttonStyle(WhomButtonStyle())
//                .frame(width: size.width, height: size.height)
//            default:
//                Button(action: {}, label: {
//                    Text(title)
//                })
//                .frame(width: size.width, height: size.height)
//            }
//        }
//    }

}

struct WhomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .foregroundStyle(Color.BizzyColor.whomPurple)
        }
}

