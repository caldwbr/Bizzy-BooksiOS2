import SwiftUI
import Firebase
import FirebaseDatabase

@MainActor
struct AddItemView: View {
    @Bindable var model: Model
    @Binding var isAddItemViewPresented: Bool
    
    var body: some View {
        
        VStack {
            addItemHeader
            typePicker
            notesTextField
            if model.showWorkersCompToggle {
                wcToggle
            }
            yeSentence
        }
        .onAppear(perform: {
            model.clearButtonsTFsAndPickers()
        })
        .onDisappear(perform: {
            model.checkAndCreateYouEntity()
            model.loadDataAndConcatenate()
        })
        .padding()
    }
    
    var addItemHeader: some View {
        HStack {
            addItemTitle
            Spacer()
            saveButton
        }
    }
    
    var addItemTitle: some View {
        Text("Add Item")
            .font(.largeTitle)
            .padding()
    }
    
    var saveButton: some View {
        Button(action: {
            let newItem = Item(latitude: model.latitude ?? 0.0, longitude: model.longitude ?? 0.0, itemType: model.itemType, notes: model.notesValue, who: model.selectedWho, whoID: model.selectedWhoUID, what: model.whatInt, whom: model.selectedWhom, whomID: model.selectedWhomUID, personalReasonInt: model.personalReasonIndex, taxReasonInt: model.taxReasonIndex, vehicleName: model.selectedVehicle, vehicleID: model.selectedVehicleUID, workersComp: model.incursWorkersComp, projectName: model.selectedProject, projectID: model.selectedProjectUID, howMany: model.howManyInt, odometer: model.odometerInt)
            let newItemID = newItem.id
            print("New Item Id: ", newItem.id)
            let newItemDict = newItem.toDictionary()
            Database.database().reference().child("users").child(model.uid).child("items").child(newItemID).setValue(newItemDict)
            self.isAddItemViewPresented = false
        }, label: {
            Text("Save")
        })
        .disabled(model.selectedWhoUID.isEmpty || model.selectedWhomUID.isEmpty || (model.itemType == .business && model.taxReasonIndex == 0) || (model.itemType == .business && model.selectedProjectUID.isEmpty) || (model.itemType == .personal && model.personalReasonIndex == 0) || (model.itemType == .fuel && model.howManyInt == 0) || (model.itemType == .fuel && model.selectedVehicleUID.isEmpty) || (model.itemType == .fuel && model.odometerInt == 0) || (model.selectedWhoUID != model.uid && model.selectedWhomUID != model.uid) || (model.selectedWhoUID == model.uid && model.selectedWhomUID == model.uid))
        .font(.largeTitle)
        .padding()
    }
    
    var typePicker: some View {
        Picker("Item Type", selection: $model.itemType) {
            ForEach(ItemType.allCases) { itemType in
                Text(itemType.rawValue.capitalized).tag(itemType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    var notesTextField: some View {
        TextField("Notes", text: $model.notesValue).padding()
    }
    
    var wcToggle: some View {
        Toggle(isOn: $model.incursWorkersComp) {
            Text("Incurs workers comp? (leave off if sub has w.c.)")
        }
        .padding()
        .foregroundColor(Color.BizzyColor.orange)
    }
    
    var yeSentence: some View {
        FlowLayout(alignment: model.align.alignment) {
            who; paid; what; toW; whom
            switch model.itemType {
            case .business: forW; taxReason; project
            case .personal: forW; personalReason
            case .fuel: forW; howMany; gallonsOfFuelIn; vehicle; odometer
            }
        }
        .animation(.default, value: model.align)
        .frame(maxHeight: 300)
    }
    
    var who: some View {
        Button(action: { //0=Who
            print("Who tapped")
            model.showWhoSearchView = true
        }, label: {
            Text(model.selectedWho)
                .padding()
                .foregroundColor(Color.BizzyColor.whoBlue)
        })
        .sheet(isPresented: $model.showWhoSearchView) {
            WhoSearchView(model: model)
        }
    }
    
    var paid: some View {
        Text("paid").padding() //1=Paid
    }
    
    var what: some View {
        CurrencyTextField(model: model, value: $model.whatValue,  placeholder: model.whatPlaceholder) //2=What
            .foregroundColor(Color.BizzyColor.whatGreen)
            .padding(11)
    }
    
    var toW: some View {
        Text("to").padding() //3=ToW
    }
    
    var whom: some View {
        Button(action: { //4=Whom
            print("Whom tapped")
            model.showWhomSearchView = true
        }, label: {
            Text(model.selectedWhom)
                .padding()
                .foregroundColor(Color.BizzyColor.whomPurple)
        })
        .sheet(isPresented: $model.showWhomSearchView) {
            WhomSearchView(model: model)
        }
    }
    
    var forW: some View {
        Text("for").padding() //5=forW, below, 6=TaxReason
    }
    
    var taxReason: some View {
        Picker(model.taxReasonArray[0], selection: $model.taxReasonIndex) {
            ForEach(0..<model.taxReasonArray.count, id: \.self) { index in
                Text(model.taxReasonArray[index])
            }
        }
        .onChange(of: model.taxReasonIndex) { oldValue, newValue in
            if newValue == 3 {
                model.showWorkersCompToggle = true
            } else {
                model.showWorkersCompToggle = false
            }
        }
        .accentColor(Color.BizzyColor.taxReasonMagenta)
        .padding(9)
    }
    
    var project: some View {
        Button(action: { //7=Project
            model.showProjectSearchView = true
        }, label: {
            Text(model.selectedProject)
                .padding()
                .foregroundColor(Color.BizzyColor.projectBlue)
        })
        .sheet(isPresented: $model.showProjectSearchView) {
            ProjectSearchView(model: model)
        }
    }
    
    var personalReason: some View {
        Picker(model.personalReasonArray[0], selection: $model.personalReasonIndex) {
            ForEach(0..<model.personalReasonArray.count, id: \.self) { index in
                Text(model.personalReasonArray[index])
            }
        }
        .accentColor(Color.BizzyColor.personalReasonMagenta)
        .padding(9)
    }
    
    var howMany: some View {
        GallonsTextField(model: model, value: $model.howManyValue, placeholder: model.howManyPlaceholder)
            .foregroundColor(Color.BizzyColor.orange)
            .padding(11)
    }
    
    var gallonsOfFuelIn: some View {
        Text("gallons of fuel in").padding() //7=GallonsOfFuelIn, 8=Vehicle
    }
    
    var vehicle: some View {
        Button(action: {
            model.showVehicleSearchView = true
        }, label: {
            Text(model.selectedVehicle)
                .padding()
                .foregroundColor(Color.BizzyColor.taxReasonMagenta)
        })
        .sheet(isPresented: $model.showVehicleSearchView) {
            VehicleSearchView(model: model)
        }
    }
    
    var odometer: some View {
        OdometerTextField(model: model, value: $model.odometerValue, placeholder: model.odometerPlaceholder)
            .foregroundColor(Color.BizzyColor.grey)
            .padding(11)
    }
    
}

