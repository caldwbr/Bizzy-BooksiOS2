import Foundation
import SwiftUI
import Firebase
import Combine

@MainActor
struct MainScreenView: View {
    @Environment(Model.self) var model
    @State private var isFilterActive = false
    @State private var isEditing = false
    @State private var isEditingSheetPresented = false
    @State private var showingAddItemView = false
    @State private var isReportsViewPresented = false
    @State var searchCardsText = ""
    var body: some View {
        Self._printChanges()
        @Bindable var model = model
        return VStack {
            TextField("", text: $model.authEmail)
            HeaderHStack(isFilterActive: $isFilterActive)
            FilterByHStack(model: model, searchCardsText: $searchCardsText, isFilterActive: $isFilterActive)
            BodyScrollView(model: model, searchCardsText: $searchCardsText, isFilterActive: $isFilterActive)
            FooterHStack(model: model, isFilterActive: $isFilterActive, isEditing: $isEditing, isEditingSheetPresented: $isEditingSheetPresented, showingAddItemView: $showingAddItemView, isReportsViewPresented: $isReportsViewPresented)
        }
        .onAppear(perform: {            model.configureFirebaseReferences()
            model.checkAndCreateYouEntity()
            model.loadDataAndConcatenate()
        })
    }
}



struct HeaderHStack: View {
    @Binding var isFilterActive: Bool
    var body: some View {
        HStack {
            // Left circle containing user profile picture or Bizzy icon
            CircleAvatarView(imageName: "bizzyBeeImage")
            
            Spacer()
            
            Text("Bizzy Books")
                .font(.title)
                .bold()
            
            Spacer()
            
            Button("Settings") {
                openSettings()
            }
        }
        .padding()
        .background(Color.offWhiteGray)
    }
}

struct FilterByHStack: View {
    @Bindable var model: Model
    @Binding var searchCardsText: String
    @Binding var isFilterActive: Bool
    var body: some View {
        HStack {
            TextField("Search", text: $searchCardsText)
                .onChange(of: searchCardsText) { oldText, newText in
                    model.filteredUniversals.removeAll()
                    model.universals.forEach { universal in
                        if universal.title.lowercased().contains(newText.lowercased()) {
                            model.filteredUniversals.append(universal) // Append matching items
                        }
                    }
                    model.displayedUniversals.removeAll()
                    model.displayedUniversals = model.filteredUniversals
                }
        }
        .padding()
        .background(Color.offWhiteGray)
        .opacity(isFilterActive ? 1.0 : 0.0)
    }
}

struct BodyScrollView: View {
    @Bindable var model: Model
    @Binding var searchCardsText: String
    @Binding var isFilterActive: Bool
    var body: some View {
        return ScrollView {
            if model.displayedUniversals.isEmpty {
                ProgressView() // or a custom placeholder view
            } else {
                LazyVStack {
                    ForEach(model.displayedUniversals) { displayedUniversal in
                        CardView(model: model, displayedUniversal: displayedUniversal)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
                    }
                }//.searchable(text: $searchCardsText)
            }
        }
    }
}

struct FooterHStack: View {
    @Bindable var model: Model
    @Binding var isFilterActive: Bool
    @Binding var isEditing: Bool
    @Binding var isEditingSheetPresented: Bool
    @Binding var showingAddItemView: Bool
    @Binding var isReportsViewPresented: Bool
    
    var body: some View {
        Self._printChanges()
        return HStack {
            Button("Edit") {
                editBusiness()
                isEditing.toggle()
                isEditingSheetPresented = true
            }
            .padding()
            .sheet(isPresented: $isEditingSheetPresented) {
                EditBusinessView(model: model)
            }
            
            Spacer()
            
            Button(action: {
                if isFilterActive {
                    model.displayedUniversals.removeAll()
                    model.displayedUniversals = model.universals
                }
                isFilterActive.toggle()
            }) {Image(systemName: "magnifyingglass").foregroundColor(.blue).disabled(!model.hasLoaded)}
            
            Spacer()
            
            Button(action: {
                isReportsViewPresented = true
            }) {
                Image(systemName: "book")
                    .foregroundColor(.blue)
            }
            .sheet(isPresented: $isReportsViewPresented) {
                ReportsView(model: model)
            }
            
            Spacer()
            
            Button(action: {
                showingAddItemView = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
            .padding()
            .sheet(isPresented: $showingAddItemView) {
                AddItemView(model: model, isAddItemViewPresented: $showingAddItemView)
            }
        }
        .padding()
        .background(Color.offWhiteGray)
    }
}


struct CircleAvatarView: View {
    let imageName: String // Name of the user's profile picture or "bizzy_icon" for the default icon
    
    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: 40, height: 40) // Adjust the size as needed
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.blue, lineWidth: 2)) // Add a border if desired
    }
}

@MainActor
struct CardView: View {
    @Bindable var model: Model
    var displayedUniversal: Universal
    // Helper function to format the timestamp
    func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    var mainSentence: some View {
        FlowLayout(alignment: model.align.alignment) {
            if displayedUniversal.itemTaxReasonInt == 1 {
                whom; paid; what; toW; whoO
            } else {
                whoS; paid; what; toW; whom
            }
            switch displayedUniversal.itemItemType {
            case .business: forW; taxReason; project
            case .personal: forW; personalReason
            case .fuel: forW; howMany; gallonsOfFuelIn; vehicle; odometer
            }
        }
        .animation(.default, value: model.align)
        .frame(maxHeight: .infinity)
    }
    
    var whoS: some View {
        Text("You")
            .foregroundColor(Color.BizzyColor.whoBlue)
            .padding()
    }
    
    var whoO: some View {
        Text("you")
            .foregroundColor(Color.BizzyColor.whoBlue)
            .padding()
    }
    
    var paid: some View {
        Text("paid").padding() //1=Paid
    }
    
    var what: some View {
        Text(formattedWhat)
            .foregroundColor(displayedUniversal.itemWhat < 0 ? Color.red : Color.BizzyColor.whatGreen)
            .padding()
    }
    
    var formattedWhat: String {
        let pennies = displayedUniversal.itemWhat
        guard pennies != 0 else {
            return "$0.00"
        }
        
        let dollars = Double(pennies) / 100.0
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = "$"
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
    
    var toW: some View {
        Text("to").padding() //3=ToW
    }
    
    var whom: some View {
        Text(displayedUniversal.itemWhom)
            .foregroundColor(Color.BizzyColor.whomPurple)
            .padding()
    }
    
    var forW: some View {
        Text("for").padding() //5=forW, below, 6=TaxReason
    }
    
    var taxReason: some View {
        Text(String(displayedUniversal.taxReasonString))
            .foregroundColor(Color.BizzyColor.taxReasonMagenta)
            .padding()
    }
    
    var project: some View {
        Text(displayedUniversal.itemProjectName)
            .foregroundColor(Color.BizzyColor.projectBlue)
            .padding()
    }
    
    var personalReason: some View {
        Text(String(displayedUniversal.personalReasonString))
            .foregroundColor(Color.BizzyColor.taxReasonMagenta)
            .padding()
    }
    
    var howMany: some View {
        Text(formattedHowMany)
            .foregroundColor(Color.BizzyColor.orange)
            .padding()
    }
    
    var formattedHowMany: String {
        let microgallons = displayedUniversal.itemHowMany
        print("uGallons: \(microgallons)")
        guard microgallons != 0 else {
            return "0.000"
        }
        
        let gallons = Double(microgallons) / 1000.0
        return String(format: "%.3f", gallons)
    }
    
    var gallonsOfFuelIn: some View {
        Text("gallons of fuel in").padding() //7=GallonsOfFuelIn, 8=Vehicle
    }
    
    var vehicle: some View {
        Text(displayedUniversal.itemVehicleName)
            .foregroundColor(Color.BizzyColor.taxReasonMagenta).padding()
    }
    
    var odometer: some View {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = ","
        
        if let formattedOdometer = numberFormatter.string(from: NSNumber(value: displayedUniversal.itemOdometer)) {
            return Text(formattedOdometer)
                .foregroundColor(Color.BizzyColor.grey)
                .padding()
        } else {
            return Text("odometer n/a")
                .foregroundColor(Color.red)
                .padding()
        }
    }
    
    var entityList: some View {
        VStack(alignment: .leading) {
            if !displayedUniversal.entityBusinessName.isEmpty {
                Text("Business Name: \(displayedUniversal.entityBusinessName)")
            }
            if !displayedUniversal.entityStreet.isEmpty {
                Text("Street: \(displayedUniversal.entityStreet)")
            }
            if !displayedUniversal.entityCity.isEmpty {
                Text("City: \(displayedUniversal.entityCity)")
            }
            if !displayedUniversal.entityState.isEmpty {
                Text("State: \(displayedUniversal.entityState)")
            }
            if !displayedUniversal.entityZip.isEmpty {
                Text("Zip: \(displayedUniversal.entityZip)")
            }
            if !displayedUniversal.entityPhone.isEmpty {
                Text("Phone: \(displayedUniversal.entityPhone)")
            }
            if !displayedUniversal.entityEmail.isEmpty {
                Text("Email: \(displayedUniversal.entityEmail)")
            }
            if !displayedUniversal.entityEIN.isEmpty {
                Text("EIN: \(displayedUniversal.entityEIN)")
            }
            if !displayedUniversal.entitySSN.isEmpty {
                Text("SSN: \(displayedUniversal.entitySSN)")
            }
        }
    }

    var vehicleList: some View {
        VStack(alignment: .leading) {
            if !displayedUniversal.vehicleModel.isEmpty {
                Text("Model: \(displayedUniversal.vehicleModel)")
            }
            if !displayedUniversal.vehicleLicensePlate.isEmpty {
                Text("License Plate: \(displayedUniversal.vehicleLicensePlate)")
            }
            if !displayedUniversal.vehicleVIN.isEmpty {
                Text("VIN: \(displayedUniversal.vehicleVIN)")
            }
            if !displayedUniversal.vehicleYear.isEmpty {
                Text("Year: \(displayedUniversal.vehicleYear)")
            }
            if !displayedUniversal.vehicleMake.isEmpty {
                Text("Make: \(displayedUniversal.vehicleMake)")
            }
            if !displayedUniversal.vehicleColor.isEmpty {
                Text("Color: \(displayedUniversal.vehicleColor)")
            }
            if !displayedUniversal.vehiclePicd.isEmpty {
                Text("Picd: \(displayedUniversal.vehiclePicd)")
            }
        }
    }

    var projectList: some View {
        VStack(alignment: .leading) {
            if !displayedUniversal.projectNotes.isEmpty {
                Text("Notes: \(displayedUniversal.projectNotes)")
            }
            if !displayedUniversal.projectCustomerName.isEmpty {
                Text("Customer Name: \(displayedUniversal.projectCustomerName)")
            }
            if !displayedUniversal.projectJobsiteStreet.isEmpty {
                Text("Jobsite Street: \(displayedUniversal.projectJobsiteStreet)")
            }
            if !displayedUniversal.projectJobsiteCity.isEmpty {
                Text("Jobsite City: \(displayedUniversal.projectJobsiteCity)")
            }
            if !displayedUniversal.projectJobsiteState.isEmpty {
                Text("Jobsite State: \(displayedUniversal.projectJobsiteState)")
            }
            if !displayedUniversal.projectJobsiteZip.isEmpty {
                Text("Jobsite Zip: \(displayedUniversal.projectJobsiteZip)")
            }
            if !displayedUniversal.projectCustomerSSN.isEmpty {
                Text("Customer SSN: \(displayedUniversal.projectCustomerSSN)")
            }
            if !displayedUniversal.projectCustomerEIN.isEmpty {
                Text("Customer EIN: \(displayedUniversal.projectCustomerEIN)")
            }
        }
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: displayedUniversal.systemImageName)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(displayedUniversal.title)
                    .font(.headline)
            }
            
            Divider()
            
            let notes = displayedUniversal.notes
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            switch displayedUniversal.type {
            case .entity:
                entityList
            case .vehicle:
                vehicleList
            case .project:
                projectList
            case .item:
                mainSentence
            }
            
            Spacer()
            
            Text(formatDate(displayedUniversal.timestamp))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}

extension Universal {
    var title: String {
        switch type {
        case .item:
            return itemItemType.rawValue
        case .entity:
            return entityName
        case .project:
            return projectName
        case .vehicle:
            return vehicleName
        }
    }
    
    var notes: String {
        switch type {
        case .item(let item):
            return item.notes
        case .entity(let entity):
            // Return some entity specific note if needed
            return ""
        case .project(let project):
            return project.notes
        case .vehicle(let vehicle):
            // Return some vehicle specific note if needed
            return ""
        }
    }
    
    var systemImageName: String {
        switch type {
        case .item(let item):
            switch item.itemType {
            case .fuel:
                return "fuelpump.circle"
            case .personal:
                return "house.circle"
            case .business:
                return "building.2.crop.circle"
            }
        case .entity:
            return "person.circle"
        case .project:
            return "hammer.circle"
        case .vehicle:
            return "car.circle"
        }
    }
    
    
}

func openSettings() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
        return
    }
    
    if UIApplication.shared.canOpenURL(settingsURL) {
        UIApplication.shared.open(settingsURL, options: [:]) { success in
            if success {
                print("Opened Settings")
            } else {
                print("Failed to open Settings")
            }
        }
    }
}

func editBusiness() {
    return
}



extension Color {
    static let offWhiteGray = Color(red: 0.95, green: 0.95, blue: 0.95) // Customize the RGB values as needed
}

