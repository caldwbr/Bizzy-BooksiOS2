import SwiftUI

struct AddItemView: View {
    @StateObject private var viewModel = ViewModel()
    @ObservedObject var whoViewModel: WhoViewModel
    @ObservedObject var whomViewModel: WhomViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var vehicleViewModel: VehicleViewModel
    
    var body: some View { yeView }
    
    var yeView: some View {
        VStack {
            addItemHeader
            typePicker
            notesTextField
            if viewModel.showWorkersCompToggle {
                wcToggle
            }
            yeSentence
        }
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
            let newItem = viewModel.createNewItemWithLocation()
        }, label: {
            Text("Save")
        })
        .font(.largeTitle)
        .padding()
    }
    
    var typePicker: some View {
        Picker("Item Type", selection: $viewModel.itemType) {
            ForEach(ItemType.allCases) { itemType in
                Text(itemType.rawValue.capitalized).tag(itemType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: viewModel.itemType) { oldValue, newValue in
            switch newValue {
            case .business:
                viewModel.whichSentence = 1
                viewModel.displaySentence = Sentences.one
            case .personal:
                viewModel.whichSentence = 2
                viewModel.displaySentence = Sentences.two
            case .fuel:
                viewModel.whichSentence = 3
                viewModel.displaySentence = Sentences.three
            }
        }
    }
    
    var notesTextField: some View {
        TextField("Notes", text: $viewModel.notesValue).padding()
    }
    
    var wcToggle: some View {
        Toggle(isOn: $viewModel.incursWorkersComp) {
            Text("Incurs workers comp? (leave off if sub has w.c.)")
        }
        .padding()
        .foregroundColor(Color.BizzyColor.orange)
    }
    
    var yeSentence: some View {
        FlowLayout(alignment: viewModel.align.alignment) {
            who; paid; what; toW; whom
            switch viewModel.whichSentence {
            case 1: forW; taxReason; project
            case 2: forWP; personalReason
            default: forH; howMany; gallonsOfFuelIn; vehicle; odometer
            }
        }
        .animation(.default, value: viewModel.align)
        .frame(maxHeight: 300)
    }
    
    var who: some View {
        Button(action: { //0=Who
            viewModel.showWhoSearchView = true
        }, label: {
            Text(viewModel.displaySentence[0].1)
                .padding()
                .foregroundColor(WhoSE.color)
        })
        .sheet(isPresented: $viewModel.showWhoSearchView) {
            WhoSearchView(selectedWho: $viewModel.selectedWho, selectedWhoUID: $viewModel.selectedWhoUID, onSelection: { selectedWho, selectedWhoUID in
                viewModel.displaySentence[0].0 = selectedWhoUID
                viewModel.displaySentence[0].1 = selectedWho
            }, whoViewModel: whoViewModel)
        }
    }
    
    var paid: some View {
        Text(viewModel.displaySentence[1].1).padding() //1=Paid
    }
    
    var what: some View {
        CurrencyTextField(value: $viewModel.currencyValue,  placeholder: "what") //2=What
            .foregroundColor(WhatSE.color)
            .padding(11)
    }
    
    var toW: some View {
        Text(viewModel.displaySentence[3].1).padding() //3=ToW
    }
    
    var whom: some View {
        Button(action: { //4=Whom
            viewModel.showWhomSearchView = true
        }, label: {
            Text(viewModel.displaySentence[4].1)
                .padding()
                .foregroundColor(WhomSE.color)
        })
        .sheet(isPresented: $viewModel.showWhomSearchView) {
            WhomSearchView(selectedWhom: $viewModel.selectedWhom, selectedWhomUID: $viewModel.selectedWhomUID, onSelection: { selected, selectedUID in
                viewModel.displaySentence[4].0 = selectedUID
                viewModel.displaySentence[4].1 = selected
            }, whomViewModel: whomViewModel)
        }
    }
    
    var forW: some View {
        Text(viewModel.displaySentence[5].1).padding() //5=forW, below, 6=TaxReason
    }
    
    var taxReason: some View {
        Picker(viewModel.displaySentence[6].1, selection: $viewModel.selectedTaxReasonUID) {
            ForEach(TaxReason.allCases.indices, id: \.self) { index in
                Text(TaxReason.allCases[index].rawValue).tag(index)
            }
        }
        .onChange(of: Int(viewModel.selectedTaxReasonUID!)!) { newIndex, _ in
            let newReason = TaxReason.allCases[newIndex].rawValue
            viewModel.displaySentence[6] = (String(newIndex), newReason)
            if newReason == "Workers Comp" {
                viewModel.showWorkersCompToggle = true
            } else {
                viewModel.showWorkersCompToggle = false
            }
        }
        .accentColor(TaxReasonSE.color)
        .padding(9)
    }
    
    var project: some View {
        Button(action: { //7=Project
            viewModel.showProjectSearchView = true
        }, label: {
            Text(viewModel.displaySentence[7].1)
                .padding()
                .foregroundColor(ProjectSE.color)
        })
        .sheet(isPresented: $viewModel.showProjectSearchView) {
            ProjectSearchView(selectedProject: $viewModel.selectedProject, selectedProjectUID: $viewModel.selectedProjectUID, onSelection: { selectedProject, selectedProjectUID in
                viewModel.displaySentence[7].0 = selectedProjectUID
                viewModel.displaySentence[7].1 = selectedProject
            }, projectViewModel: projectViewModel)
        }
    }
    
    var forWP: some View {
        Text(viewModel.displaySentence[5].1).padding() //5=forW, below, 6=PersonalReason
    }
    
    var personalReason: some View {
        Picker(viewModel.displaySentence[6].1, selection: Binding(
            get: { viewModel.selectedPersonalReasonIndex },
            set: { newIndex in
                viewModel.selectedPersonalReasonIndex = newIndex
                let newReason = PersonalReason.allCases[newIndex]
                viewModel.updateSelectedPersonalReason(newReason: newReason)
            }
        )) {
            ForEach(PersonalReason.allCases.indices, id: \.self) { index in
                Text(PersonalReason.allCases[index].rawValue).tag(index)
            }
        }
        .accentColor(PersonalReasonSE.color)
        .padding(9)
    }
    
    var forH: some View {
        Text(viewModel.displaySentence[5].1).padding() //5=forH, below, 6=HowMany
    }
    
    var howMany: some View {
        GallonsTextField(value: $viewModel.gallonsValue, placeholder: viewModel.displaySentence[6].1)
            .foregroundColor(HowManySE.color)
            .padding(11)
    }
    
    var gallonsOfFuelIn: some View {
        Text(viewModel.displaySentence[7].1).padding() //7=GallonsOfFuelIn, 8=Vehicle
    }
    
    var vehicle: some View {
        Button(action: {
            viewModel.showVehicleSearchView = true
        }, label: {
            Text(viewModel.displaySentence[8].1)
                .padding()
                .foregroundColor(VehicleSE.color)
        })
        .sheet(isPresented: $viewModel.showVehicleSearchView) {
            VehicleSearchView(selectedVehicle: $viewModel.selectedVehicle, selectedVehicleUID: $viewModel.selectedVehicleUID, onSelection: { selectedVehicle, selectedVehicleUID in
                viewModel.displaySentence[8].0 = selectedVehicleUID
                viewModel.displaySentence[8].1 = selectedVehicle
            }, vehicleViewModel: vehicleViewModel)
        }
    }
    
    var odometer: some View {
        OdometerTextField(value: $viewModel.odometerValue, placeholder: viewModel.displaySentence[9].1)
            .foregroundColor(OdometerSE.color)
            .padding(11)
    }
}

