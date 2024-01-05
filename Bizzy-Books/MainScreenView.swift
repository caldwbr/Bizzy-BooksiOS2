import Foundation
import SwiftUI
import Firebase
import Combine

class MainScreenViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var entities: [Entity] = []
    @Published var projects: [Project] = []
    @Published var vehicles: [Vehicle] = []
    @Published var userEntity: Entity? // Replace YourEntityType with your actual data model.

    @Published private var uid: String = ""
    @Published private var userRef: DatabaseReference!

    @Published private var itemsRef: DatabaseReference!
    @Published private var entitiesRef: DatabaseReference!
    @Published private var projectsRef: DatabaseReference!
    @Published private var vehiclesRef: DatabaseReference!

    private var db = Firestore.firestore()

    init() {
        configureFirebaseReferences()
        fetchDataFromFirebase()
        checkAndCreateYouEntity()
    }

    private func configureFirebaseReferences() {
        uid = Auth.auth().currentUser?.uid ?? ""
        userRef = Database.database().reference().child("users").child(uid)

        // Access the data for the specific user.
        itemsRef = userRef.child("items")
        entitiesRef = userRef.child("entities")
        projectsRef = userRef.child("projects")
        vehiclesRef = userRef.child("vehicles")
    }

    private func fetchDataFromFirebase() {
        // Use Firebase's observe methods to read data from the references.
        itemsRef.observe(.value) { snapshot in
            // Parse and populate the 'items' array from the snapshot.
            // Ensure you decode the snapshot data into 'Item' objects.
        }

        entitiesRef.observe(.value) { snapshot in
            // Parse and populate the 'entities' array from the snapshot.
            // Ensure you decode the snapshot data into 'Entity' objects.
        }

        projectsRef.observe(.value) { snapshot in
            // Parse and populate the 'projects' array from the snapshot.
            // Ensure you decode the snapshot data into 'Project' objects.
        }

        vehiclesRef.observe(.value) { snapshot in
            // Parse and populate the 'vehicles' array from the snapshot.
            // Ensure you decode the snapshot data into 'Vehicle' objects.
        }
    }

    private func checkAndCreateYouEntity() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return // User is not logged in, so we can't create the entity.
        }

        let youEntityRef = Database.database().reference().child("users").child(uid).child("entities").child(uid)

        youEntityRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                // "you" entity already exists, retrieve it if needed.
            } else {
                // "you" entity does not exist, create it and upload to the Realtime Database.
                let newEntity = Entity(id: uid, name: "You")
                let newEntityData = try? JSONEncoder().encode(newEntity)

                youEntityRef.setValue(newEntityData) { error, _ in
                    if let error = error {
                        print("Error creating/updating entity: \(error)")
                    } else {
                        self.userEntity = newEntity
                    }
                }
            }
        }
    }
}



struct MainScreenView: View {
    @State private var isFilterActive = false
    @State private var isEditing = false
    @State private var isEditingSheetPresented = false
    @State private var showingAddItemView = false
    @State private var selectedItemType: ItemType = .business
    @ObservedObject var addItemViewModel = AddItemViewModel()
    @State private var whoViewModel = WhoViewModel()
    @State private var whomViewModel = WhomViewModel()
    @State private var projectViewModel = ProjectViewModel()
    @State private var vehicleViewModel = VehicleViewModel()
    @State private var selectedWho: String = WhoSE.tuple.1
    @State private var selectedWhoUID: String? = nil
    @State private var selectedWhom: String = WhomSE.tuple.1
    @State private var selectedWhomUID: String? = nil
    @State private var selectedVehicle: String = VehicleSE.tuple.1
    @State private var selectedVehicleUID: String? = nil
    @State private var selectedProject: String = WhoSE.tuple.1
    @State private var selectedProjectUID: String? = nil
    @State private var selectedTaxReason: String = TaxReasonSE.tuple.1
    @State private var selectedTaxReasonUID: String? = TaxReasonSE.tuple.0
    @State private var selectedPersonalReason: String = PersonalReasonSE.tuple.1
    @State private var selectedPersonalReasonUID: String? = PersonalReasonSE.tuple.0
    var body: some View {
        Self._printChanges()
       return VStack {
            HeaderHStack(isFilterActive: $isFilterActive)
            FilterByHStack(isFilterActive: $isFilterActive)
            BodyScrollView(isFilterActive: $isFilterActive)
            FooterHStack(
                isFilterActive: $isFilterActive,
                isEditing: $isEditing,
                isEditingSheetPresented: $isEditingSheetPresented,
                showingAddItemView: $showingAddItemView,
                selectedItemType: $selectedItemType,
                addItemViewModel: addItemViewModel,
                selectedWho: $selectedWho,
                selectedWhoUID: $selectedWhoUID,
                selectedWhom: $selectedWhom,
                selectedWhomUID: $selectedWhomUID,
                selectedVehicle: $selectedVehicle,
                selectedVehicleUID: $selectedVehicleUID,
                selectedProject: $selectedProject,
                selectedProjectUID: $selectedProjectUID,
                whoViewModel: $whoViewModel,
                whomViewModel: $whomViewModel,
                projectViewModel: $projectViewModel, 
                vehicleViewModel: $vehicleViewModel,
                selectedTaxReason: $selectedTaxReason,
                selectedTaxReasonUID: $selectedTaxReasonUID,
                selectedPersonalReason: $selectedPersonalReason,
                selectedPersonalReasonUID: $selectedPersonalReasonUID
            )
        }
        .onChange(of: selectedItemType) { oldValue, newValue in
                print(oldValue, newValue)
        }
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
    @Binding var isFilterActive: Bool
    var body: some View {
        HStack {
            // Add your filter UI elements here
        }
        .padding()
        .background(Color.offWhiteGray)
        .opacity(isFilterActive ? 1.0 : 0.0)
    }
}

struct BodyScrollView: View {
    @Binding var isFilterActive: Bool
    var body: some View {
        ScrollView {
            // Card views go here, generated dynamically
        }
    }
}

struct FooterHStack: View {
    @Binding var isFilterActive: Bool
    @Binding var isEditing: Bool
    @Binding var isEditingSheetPresented: Bool
    @Binding var showingAddItemView: Bool
    @Binding var selectedItemType: ItemType
    @ObservedObject var addItemViewModel: AddItemViewModel
    @Binding var selectedWho: String
    @Binding var selectedWhoUID: String?
    @Binding var selectedWhom: String
    @Binding var selectedWhomUID: String?
    @Binding var selectedVehicle: String
    @Binding var selectedVehicleUID: String?
    @Binding var selectedProject: String
    @Binding var selectedProjectUID: String?
    @Binding var whoViewModel: WhoViewModel
    @Binding var whomViewModel: WhomViewModel
    @Binding var projectViewModel: ProjectViewModel
    @Binding var vehicleViewModel: VehicleViewModel
    @Binding var selectedTaxReason: String
    @Binding var selectedTaxReasonUID: String?
    @Binding var selectedPersonalReason: String
    @Binding var selectedPersonalReasonUID: String?
    
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
                EditBusinessView()
            }
            
            Spacer()
            
            Button(action: {
                filterBy()
                isFilterActive.toggle()
            }) {Image(systemName: "magnifyingglass").foregroundColor(.blue)}
            
            Spacer()
            
            NavigationLink(destination: DocumentGenerationView()) {
                Image(systemName: "book")
                    .foregroundColor(.blue)
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
                AddItemView(viewModel: addItemViewModel, itemType: $selectedItemType, selectedWho: $selectedWho, selectedWhoUID: $selectedWhoUID, selectedWhom: $selectedWhom, selectedWhomUID: $selectedWhomUID, selectedVehicle: $selectedVehicle, selectedVehicleUID: $selectedVehicleUID, selectedProject: $selectedProject, selectedProjectUID: $selectedProjectUID, whoViewModel: whoViewModel, whomViewModel: whomViewModel, projectViewModel: projectViewModel, vehicleViewModel: vehicleViewModel, selectedTaxReason: $selectedTaxReason, selectedTaxReasonUID: $selectedTaxReasonUID, selectedPersonalReason: $selectedPersonalReason, selectedPersonalReasonUID: $selectedPersonalReasonUID)
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

func filterBy() {
    return
}

// Define your DocumentGenerationView
struct DocumentGenerationView: View {
    var body: some View {
        // Your document generation view content here
        Text("Document Generation View")
    }
}

extension Color {
    static let offWhiteGray = Color(red: 0.95, green: 0.95, blue: 0.95) // Customize the RGB values as needed
}

