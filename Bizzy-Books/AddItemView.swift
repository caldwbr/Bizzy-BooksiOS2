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
                        case .button(let title, let action, let size):
                            Button(action: action) {
                                Text(title)
                            }
                            .padding()
                        case .textField(let placeholder, let currentText, _):
                            TextField(placeholder, text: Binding.constant(currentText))
                                .padding()
                        }
                })
                .border(Color.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func createSentenceLayout(geometry: GeometryProxy, elements: [SentenceElement]) -> some View {
            var widthUsed: CGFloat = 0
            var lineHeight: CGFloat = 0 // Track the height of the current line

            return VStack(alignment: .leading, spacing: 4) { // Adjust spacing as needed
                ForEach(elements, id: \.id) { element in
                    Group { // Wrap the entire element in a Group
                        self.view(for: element) // Call the view-building function
                            .padding(4) // Adjust padding as needed
                            .alignmentGuide(.leading, computeValue: { dimension in
                                // Check if element fits in the current line or needs a new line
                                if widthUsed + dimension.width > geometry.size.width {
                                    widthUsed = 0 // Reset for a new line
                                    return widthUsed
                                } else {
                                    let offset = widthUsed
                                    widthUsed += dimension.width
                                    return offset
                                }
                            })
                    }
                }
            }
        }

    
    @ViewBuilder
    private func view(for element: SentenceElement) -> some View {
        Text(String(describing: element))
//        switch element {
//        case .text(let text, let size):
//            Text(text)
//                .frame(width: size.width, height: size.height) // Use size here
//        case .button(let title, let action, let size):
//            Button(title, action: action)
//                .frame(width: size.width, height: size.height) // Use size here
//        case .textField(let placeholder, let text, let size):
//            TextField(placeholder, text: .constant(text))
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .frame(width: size.width, height: size.height) // Use size here
//        }
    }

}

extension View {
    func asAnyView() -> AnyView {
        AnyView(self)
    }
}

/*
struct AddItemView: View {
    @State private var selectedCategory: Category = .business
    @State private var whatAmount: String = ""
    @State private var howManyGallonsAmount: String = ""
    @State private var odoAmount: String = ""

    @State private var flowItems: [AnyView] = []
    private var gridLayout: [GridItem] = Array(repeating: .init(.flexible()), count: 1)

    var body: some View {
        VStack {
            Picker("Category", selection: $selectedCategory) {
                Text("Business").tag(Category.business)
                Text("Personal").tag(Category.personal)
                Text("Fuel").tag(Category.fuel)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedCategory) { oldValue, newValue in
                updateFlowItems(for: newValue)
            }

            ScrollView {
                LazyVGrid(columns: gridLayout, spacing: 10) {
                    ForEach(0..<flowItems.count, id: \.self) { index in
                        flowItems[index]
                    }
                }
                .padding()
            }
        }
        .onAppear {
            updateFlowItems(for: selectedCategory)
        }
    }

    func updateFlowItems(for category: Category) {
        var items = commonFlowItems()
        switch category {
        case .business:
            // Add specific items for the business case
            items.append(contentsOf: businessSpecificPart())
        case .personal:
            // Add specific items for the personal case
            items.append(contentsOf: personalSpecificPart())
        case .fuel:
            // Add specific items for the fuel case
            items.append(contentsOf: fuelSpecificPart())
        }
        flowItems = items
    }

    func commonFlowItems() -> [AnyView] {
        return [
            AnyView(Button("Who ▼") { /* action */ }
                .padding(3)
                .foregroundColor(Color.BizzyColor.whoBlue)),
            AnyView(Text(" paid ")
                .padding(3)),
            AnyView(TextField("what", text: $whatAmount)
                .padding(3)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(Color.BizzyColor.whatGreen)),
            AnyView(Text(" to ")
                .padding(3)),
            AnyView(Button("whom ▼") { /* action */ }
                .padding(3)
                .foregroundColor(Color.BizzyColor.whomPurple))
        ]
    }

    // Define businessSpecificPart, personalSpecificPart, and fuelSpecificPart functions
    func businessSpecificPart() -> [AnyView] {
        return [
            AnyView(Text("for")
                .padding(3)),
            AnyView(Button("what tax reason ▼") { /* action for tax reason */ }
                .padding(3)
                .foregroundColor(Color.BizzyColor.taxReasonMagenta)),
            AnyView(Button("project ▼") { /* action for project */ }
                .padding(3)
                .foregroundColor(Color.BizzyColor.projectBlue))
        ]
    }

    func personalSpecificPart() -> [AnyView] {
        return [
            AnyView(Text("for")
                .padding(3)),
            AnyView(Button("what personal reason ▼") { /* action for personal reason */ }
                .padding(3)
                .foregroundColor(Color.BizzyColor.personalReasonMagenta))
        ]
    }
    
    func fuelSpecificPart() -> [AnyView] {
        return [
            AnyView(Text(" for ")
                .padding(3)),
            AnyView(TextField("how many", text: $howManyGallonsAmount)
                .padding(3)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(Color.BizzyColor.darkerGreen)),
            AnyView(Text(" gallons of fuel in your ")
                .padding(3)),
            AnyView(Button("vehicle ▼") { /* action for vehicle */ }
                .padding(3)
                .foregroundColor(Color.BizzyColor.orange)),
            AnyView(Text(" at ")
                .padding(3)),
            AnyView(TextField("odometer reading", text: $odoAmount)
                .padding(3)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(Color.BizzyColor.grey))
        ]
    }
} 
 
 
 sentenceElements = [
     .button("Who ▼", action: {/* Action */}, size: CGSize(width: 100, height: 30)),
     .text(" paid ", size: CGSize(width: 40, height: 30)),
     .textField("what", "", size: CGSize(width: 100, height: 30)),
     .text(" to ", size: CGSize(width: 20, height: 30)),
     .button("whom ▼", action: {/* Action */}, size: CGSize(width: 100, height: 30)),
     .text(" for ", size: CGSize(width: 30, height: 30)),
     .button("what tax reason ▼", action: {/* Action */}, size: CGSize(width: 100, height: 30))
     // Add more elements as needed for the business case
 ]*/
