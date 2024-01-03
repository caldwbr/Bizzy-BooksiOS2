import SwiftUI

struct AddItemView: View {
    
    @ObservedObject var viewModel: AddItemViewModel
    @Binding var itemType: ItemType
    @State var align = Align.center
    @State var currencyValue: String = ""
    @State var gallonsValue: String = ""
    @State var odometerValue: String = ""
    @State var notesValue: String = ""
    @State var showWhoSearchView = false
    @Binding var selectedWho: String
    @Binding var selectedWhoUID: String?
    @State var showWhomSearchView = false
    @Binding var selectedWhom: String
    @Binding var selectedWhomUID: String?
    @State var showVehicleSearchView = false
    @Binding var selectedVehicle: String
    @Binding var selectedVehicleUID: String?
    @State var showProjectSearchView = false
    @Binding var selectedProject: String
    @Binding var selectedProjectUID: String?
    @ObservedObject var whoViewModel: WhoViewModel
    @ObservedObject var whomViewModel: WhomViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var vehicleViewModel: VehicleViewModel
    @State var displaySentence: [(String?, String)]
    @State var whichSentence: Int
    @State var showWorkersCompToggle = false
    @State var incursWorkersComp = false
    @Binding var selectedTaxReason: String
    @Binding var selectedTaxReasonUID: String?
    @Binding var selectedPersonalReason: String
    @Binding var selectedPersonalReasonUID: String?
    
    init(viewModel: AddItemViewModel,
         itemType: Binding<ItemType>,
         selectedWho: Binding<String>,
         selectedWhoUID: Binding<String?>,
         selectedWhom: Binding<String>,
         selectedWhomUID: Binding<String?>,
         selectedVehicle: Binding<String>,
         selectedVehicleUID: Binding<String?>,
         selectedProject: Binding<String>,
         selectedProjectUID: Binding<String?>,
         whoViewModel: WhoViewModel,
         whomViewModel: WhomViewModel,
         projectViewModel: ProjectViewModel,
         vehicleViewModel: VehicleViewModel,
         displaySentence: [(String?, String)] = Sentences.one,
         whichSentence: Int = 1,
         showWorkersCompToggle: Bool = false,
         incursWorkersComp: Bool = false,
         selectedTaxReason: Binding<String>,
         selectedTaxReasonUID: Binding<String?>,
         selectedPersonalReason: Binding<String>,
         selectedPersonalReasonUID: Binding<String?>) {

        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._itemType = itemType
        self._selectedWho = selectedWho
        self._selectedWhoUID = selectedWhoUID
        self._selectedWhom = selectedWhom
        self._selectedWhomUID = selectedWhomUID
        self._selectedVehicle = selectedVehicle
        self._selectedVehicleUID = selectedVehicleUID
        self._selectedProject = selectedProject
        self._selectedProjectUID = selectedProjectUID
        self._whoViewModel = ObservedObject(wrappedValue: whoViewModel)
        self._whomViewModel = ObservedObject(wrappedValue: whomViewModel)
        self._projectViewModel = ObservedObject(wrappedValue: projectViewModel)
        self._vehicleViewModel = ObservedObject(wrappedValue: vehicleViewModel)
        self._displaySentence = State(initialValue: Sentences.one)
        self._whichSentence = State(initialValue: 1)
        self._showWorkersCompToggle = State(initialValue: showWorkersCompToggle)
        self._incursWorkersComp = State(initialValue: incursWorkersComp)
        self._selectedTaxReason = selectedTaxReason
        self._selectedTaxReasonUID = selectedPersonalReasonUID
        self._selectedPersonalReason = selectedPersonalReason
        self._selectedPersonalReasonUID = selectedPersonalReasonUID
    }

    
    var body: some View {
        VStack {
            HStack {
                Text("Add Item")
                    .font(.largeTitle)
                    .padding()
                Spacer()
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
                switch newValue {
                case .business:
                    whichSentence = 1
                    displaySentence = Sentences.one
                case .personal:
                    whichSentence = 2
                    displaySentence = Sentences.two
                case .fuel:
                    whichSentence = 3
                    displaySentence = Sentences.three
                }
            }
            if showWorkersCompToggle {
                Toggle(isOn: $incursWorkersComp) {
                    Text("Incurs workers comp? (leave off if sub has w.c.)")
                }
                .padding()
                .foregroundColor(Color.BizzyColor.orange)
            }
            TextField("Notes", text: $notesValue).padding()
            let layout = FlowLayout(alignment: align.alignment)
            layout {
                Button(action: { //0=Who
                    showWhoSearchView = true
                }, label: {
                    Text(displaySentence[0].1)
                        .padding()
                        .foregroundColor(WhoSE.color)
                })
                .sheet(isPresented: $showWhoSearchView) {
                    WhoSearchView(selectedWho: $selectedWho, selectedWhoUID: $selectedWhoUID, onSelection: { selectedWho, selectedWhoUID in
                        displaySentence[0].0 = selectedWhoUID
                        displaySentence[0].1 = selectedWho
                    }, whoViewModel: whoViewModel)
                }
                Text(displaySentence[1].1).padding() //1=Paid
                CurrencyTextField(value: $currencyValue,  placeholder: "what") //2=What
                    .foregroundColor(WhatSE.color)
                    .padding(11)
                Text(displaySentence[3].1).padding() //3=ToW
                Button(action: { //4=Whom
                    showWhomSearchView = true
                }, label: {
                    Text(displaySentence[4].1)
                        .padding()
                        .foregroundColor(WhomSE.color)
                })
                .sheet(isPresented: $showWhomSearchView) {
                    WhomSearchView(selectedWhom: $selectedWhom, selectedWhomUID: $selectedWhomUID, onSelection: { selected, selectedUID in
                        displaySentence[4].0 = selectedUID
                        displaySentence[4].1 = selected
                    }, whomViewModel: whomViewModel)
                }
                switch whichSentence {
                case 1: //Business
                    Text(displaySentence[5].1).padding() //5=forW, below, 6=TaxReason
                    Picker(displaySentence[6].1, selection: $selectedTaxReasonUID) {
                        ForEach(TaxReason.allCases.indices, id: \.self) { index in
                            Text(TaxReason.allCases[index].rawValue).tag(index)
                        }
                    }
                    .onChange(of: Int(selectedTaxReasonUID!)!) { newIndex, _ in
                        let newReason = TaxReason.allCases[newIndex].rawValue
                        displaySentence[6] = (String(newIndex), newReason)
                        if newReason == "Workers Comp" {
                            showWorkersCompToggle = true
                        } else {
                            showWorkersCompToggle = false
                        }
                    }
                    .accentColor(TaxReasonSE.color)
                    .padding(9)
                    Button(action: { //7=Project
                        showProjectSearchView = true
                    }, label: {
                        Text(displaySentence[7].1)
                            .padding()
                            .foregroundColor(ProjectSE.color)
                    })
                    .sheet(isPresented: $showProjectSearchView) {
                        ProjectSearchView(selectedProject: $selectedProject, selectedProjectUID: $selectedProjectUID, onSelection: { selectedProject, selectedProjectUID in
                            displaySentence[7].0 = selectedProjectUID
                            displaySentence[7].1 = selectedProject
                        }, projectViewModel: projectViewModel)
                    }
                case 2:
                    Text(displaySentence[5].1).padding() //5=forW, below, 6=PersonalReason
                    Picker(displaySentence[6].1, selection: Binding(
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
                default: //case 3:
                    Text(displaySentence[5].1).padding() //5=forH, below, 6=HowMany
                    GallonsTextField(value: $gallonsValue, placeholder: displaySentence[6].1)
                        .foregroundColor(HowManySE.color)
                        .padding(11)
                    Text(displaySentence[7].1).padding() //7=GallonsOfFuelIn, 8=Vehicle
                    Button(action: {
                        showVehicleSearchView = true
                    }, label: {
                        Text(displaySentence[8].1)
                            .padding()
                            .foregroundColor(VehicleSE.color)
                    })
                    .sheet(isPresented: $showVehicleSearchView) {
                        VehicleSearchView(selectedVehicle: $selectedVehicle, selectedVehicleUID: $selectedVehicleUID, onSelection: { selectedVehicle, selectedVehicleUID in
                            displaySentence[8].0 = selectedVehicleUID
                            displaySentence[8].1 = selectedVehicle
                        }, vehicleViewModel: vehicleViewModel)
                    }
                    OdometerTextField(value: $odometerValue, placeholder: displaySentence[9].1)
                        .foregroundColor(OdometerSE.color)
                        .padding(11)
                }
            }
            .animation(.default, value: align)
            .frame(maxHeight: 300)
        }
        .padding()
        .onAppear {
            Sentences.clearValues()
        }
    }
}

