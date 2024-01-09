//
//  Model.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/5/24.
//

import Foundation
import Observation
import Firebase
import FirebaseDatabase
import FirebaseAuth
import SwiftUI
import Contacts

@MainActor
@Observable class Model {
    //Previously AuthenticationViewModel
    var authEmail = ""
    var authPassword = ""
    var authConfirmPassword = ""
    
    var flow: AuthenticationFlow = .login
    
    var isValid  = false
    var authenticationState: AuthenticationState = .unauthenticated
    var errorMessage = ""
    var user: User? = nil
    var displayName = ""
    
    private var authStateHandler: AuthStateDidChangeListenerHandle? = nil
    
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                self.authenticationState = user == nil ? .unauthenticated : .authenticated
                self.displayName = user?.email ?? ""
            }
        }
    }
    
    func switchFlow() {
        flow = flow == .login ? .signUp : .login
        errorMessage = ""
    }
    
    func wait() async {
        do {
            print("Wait")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            print("Done")
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func reset() {
        flow = .login
        authEmail = ""
        authPassword = ""
        authConfirmPassword = ""
    }
    
    var fieldName = ""
    var fieldBusinessName = ""
    var fieldEmail = ""
    var fieldPhone = ""
    var fieldStreet = ""
    var fieldCity = ""
    var fieldState = ""
    var fieldZip = ""
    var fieldEIN = ""
    var fieldSSN = ""
    var fieldIsSearchEnabled = true
    var contacts: [CNContact] = []
    var predicate: NSPredicate = NSPredicate(value: false)
        
    let contactStore = CNContactStore()
    var suggestedContacts: [CNContact] = []
    let keys = [CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactGivenNameKey, CNContactFamilyNameKey]
    let keysToFetch: [CNKeyDescriptor] = [
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            // Add other keys you need here
        ]
    
    func requestContactsPermission(completion: @escaping (Bool) -> Void) {
        contactStore.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func contactPredicate(forName name: String) -> NSPredicate {
        return CNContact.predicateForContacts(matchingName: name)
    }
    
    func searchContacts(name: String, completion: @escaping ([CNContact]?) -> Void) {
        contactStore.requestAccess(for: .contacts) { (granted, error) in
            if granted {
                let predicate = CNContact.predicateForContacts(matchingName: name)
                if let fetchedContacts = try? self.contactStore.unifiedContacts(matching: predicate, keysToFetch: self.keys as [CNKeyDescriptor]) {
                    DispatchQueue.main.async {
                        completion(fetchedContacts)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func fillInContactDetails(for contact: CNContact) {
        // Populate fields from the clicked contact directly
        fieldName = contact.givenName + " " + contact.familyName
        fieldEmail = contact.emailAddresses.first?.value as String? ?? ""
        fieldPhone = contact.phoneNumbers.first?.value.stringValue ?? ""
        
        // Fetch and set address details
        if let postalAddress = contact.postalAddresses.first?.value {
            fieldStreet = "\(postalAddress.street)"
            fieldCity = "\(postalAddress.city)"
            fieldState = "\(postalAddress.state)"
            fieldZip = "\(postalAddress.postalCode)"
        }
    }

    
    func clearFields() {
        fieldIsSearchEnabled = true
        fieldName = ""
        fieldBusinessName = ""
        fieldEmail = ""
        fieldPhone = ""
        fieldStreet = ""
        fieldCity = ""
        fieldState = ""
        fieldZip = ""
        fieldEIN = ""
        fieldSSN = ""
        suggestedContacts.removeAll()
        contacts.removeAll()
        predicate = NSPredicate(value: false)
    }
    
    func saveWhoEntity() {
        let newEntity = Entity(
            name: fieldName,
            businessName: fieldBusinessName,
            street: fieldStreet,
            city: fieldCity,
            state: fieldState,
            zip: fieldZip,
            phone: fieldPhone,
            email: fieldEmail,
            ein: fieldEIN,
            ssn: fieldSSN
        )
        selectedWho = newEntity.name
        selectedWhoUID = newEntity.id
        let newEntityDict = newEntity.toDictionary() // Convert the Entity to a dictionary
        Database.database().reference().child("users").child(uid).child("entities").child(newEntity.id).setValue(newEntityDict) // Save the Entity to Firebase
    }
    
    //Previously MainScreenViewModel
    var items: [Item] = []
    var entities: [Entity] = []
    var projects: [Project] = []
    var vehicles: [Vehicle] = []
    var userEntity: Entity? = nil  // Replace YourEntityType with your actual data model.
    var uid: String = ""
    var userRef: DatabaseReference? = nil
    var itemsRef: DatabaseReference? = nil
    var entitiesRef: DatabaseReference? = nil
    var projectsRef: DatabaseReference? = nil
    var vehiclesRef: DatabaseReference? = nil
    var customerName = ""
    var customerUID = ""
    var youEntity: YouEntity? = nil
    var youBusinessEntity: YouBusinessEntity? = nil
    
    func configureFirebaseReferences() {
        uid = Auth.auth().currentUser?.uid ?? ""
        userRef = Database.database().reference().child("users").child(uid)
        itemsRef = Database.database().reference().child("users").child(uid).child("items")
        entitiesRef = Database.database().reference().child("users").child(uid).child("entities")
        projectsRef = Database.database().reference().child("users").child(uid).child("projects")
        vehiclesRef = Database.database().reference().child("users").child(uid).child("vehicles")
    }
    
    func fetchDataFromFirebase() {
        // Use Firebase's observe methods to read data from the references.
        itemsRef!.observe(.value) { snapshot in
            // Parse and populate the 'items' array from the snapshot.
            // Ensure you decode the snapshot data into 'Item' objects.
        }
        
        entitiesRef!.observe(.value) { snapshot in
            // Parse and populate the 'entities' array from the snapshot.
            // Ensure you decode the snapshot data into 'Entity' objects.
        }
        
        projectsRef!.observe(.value) { snapshot in
            // Parse and populate the 'projects' array from the snapshot.
            // Ensure you decode the snapshot data into 'Project' objects.
        }
        
        vehiclesRef!.observe(.value) { snapshot in
            // Parse and populate the 'vehicles' array from the snapshot.
            // Ensure you decode the snapshot data into 'Vehicle' objects.
        }
    }
    
    func checkAndCreateYouEntity() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return // User is not logged in, so we can't create the entity.
        }
        
        let youEntityRef = Database.database().reference().child("users").child(uid).child("youentity")
        let youBusinessEntityRef = Database.database().reference().child("users").child(uid).child("youbusinessentity")
        youEntityRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                if let youEntityRefDictionary = snapshot.value as? [String: Any] {
                    self.youEntity = YouEntity(fromDictionary: youEntityRefDictionary)
                } else {
                    self.youEntity = YouEntity(uid: uid)
                }
            } else {
                self.youEntity = YouEntity(uid: uid)
                if let youEntityDict = self.youEntity?.toDictionary() {
                    youEntityRef.setValue(youEntityDict)
                }
            }
        }
        
        //Load youBusinessEntity
        youBusinessEntityRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                if let youBusinessEntityRefDictionary = snapshot.value as? [String: Any] {
                    self.youBusinessEntity = YouBusinessEntity(fromDictionary: youBusinessEntityRefDictionary)
                    print("YOOO")
                    print(self.youBusinessEntity?.name ?? "Suppy")
                } else {
                    self.youBusinessEntity = YouBusinessEntity()
                    let youBusinessEntityDict = self.youBusinessEntity?.toDictionary()
                }
            } else {
                self.youBusinessEntity = YouBusinessEntity()
                if let youBusinessEntityDict = self.youBusinessEntity?.toDictionary() {
                    youBusinessEntityRef.setValue(youBusinessEntityDict)
                }
            }
        }
    }
    
    //Previously AddItemViewModel
    let taxReasonArray: [String] = ["tax reason", "Income", "Supplies", "Labor", "Vehicle", "Pro Help", "Ins (WC+GL)", "Tax+License", "Travel", "Meals", "Office", "Advertising", "Machine Rent", "Property Rent", "Emp Benefit", "Depreciation", "Depletion", "Utilities", "Commissions", "Wages", "Mortgage Int", "Other Int", "Repairs", "Pension"]
    var taxReasonIndex: Int = 0
    let personalReasonArray: [String] = ["personal reason", "Food", "Fun", "Pet", "Utilities", "Phone", "Internet", "Office", "Medical", "Travel", "Clothes", "Other"]
    var personalReasonIndex: Int = 0
    var itemType = ItemType.business
    var align = Align.center
    var whatInt = 0
    var whatValue = ""
    let whatPlaceholder = "what"
    var howManyInt = 0
    var howManyValue = ""
    let howManyPlaceholder = "how many"
    var odometerInt = 0
    var odometerValue = ""
    let odometerPlaceholder = "odometer"
    var notesValue = ""
    let notesPlaceholder = "Notes"
    var showWhoSearchView = false
    var showWhomSearchView = false
    var showVehicleSearchView = false
    var showProjectSearchView = false
    var showWorkersCompToggle = false
    var incursWorkersComp = false
    var latitude: Double? = nil
    var longitude: Double? = nil
    
    //Previously @Binding in AddItemView
    var selectedWho = ""
    var selectedWhoUID = ""
    let whoPlaceholder = "Who ▼"
    var selectedWhom = ""
    var selectedWhomUID = ""
    let whomPlaceholder = "whom ▼"
    var selectedVehicle = ""
    var selectedVehicleUID = ""
    let vehiclePlaceholder = "vehicle ▼"
    var selectedProject = ""
    var selectedProjectUID = ""
    var projectPlaceholder = "project ▼"
    
    func sizeForElementContent(_ content: String, semanticType: SentenceElement.SemanticType) -> CGSize {
        // Calculate the size based on content and type
        // This is a placeholder - you'll need to implement actual size calculation
        let width = CGFloat(content.count * 10) // Example: 10 points per character
        let height: CGFloat = 30 // Example: fixed height
        return CGSize(width: width, height: height)
    }
    
    //Formerly ProjectViewModel
    var filteredProjects: [Project] = []
    
    func loadProjects() {
        // Load your entities here
        // For example:
        projects = [
            Project(name: "Proj 1"),
            Project(name: "Proj 2")
        ]
        filteredProjects = projects
    }
    
    func searchProjects(query: String) {
        if query.isEmpty {
            filteredProjects = projects
        } else {
            filteredProjects = projects.filter { project in
                project.name.lowercased().contains(query.lowercased())
            }
        }
    }
    
    //Formerly VehicleViewModel
    var filteredVehicles: [Vehicle] = []
    
    func loadVehicles() {
        // Load your entities here
        // For example:
        //        vehicles = [
        //            Vehicle(year: "2012", make: "Toyota", model: "Prius"),
        //            Vehicle(year: "2015", make: "Toyota", model: "Prius"),
        //            Vehicle(year: "2018", make: "Toyota", model: "Prius")
        //        ]
        //        filteredVehicles = vehicles
    }
    
    func searchVehicles(query: String) {
        if query.isEmpty {
            filteredVehicles = vehicles
        } else {
            filteredVehicles = vehicles.filter { vehicle in
                vehicle.name.lowercased().contains(query.lowercased())
            }
        }
    }
    
    //Formerly WhoViewModel
    var whoEntities: [Entity] = []
    var filteredWhoEntities: [Entity] = []
    
    func loadWhoEntities() {
        // Load your entities here
        // For example:
        //        whoEntities = [
        //            Entity(name: "Steve Caldwell"),
        //            Entity(name: "Entity 1"),
        //            Entity(name: "Entity 2"),
        //            Entity(name: "Entity 3")
        //        ]
        //        filteredWhoEntities = whoEntities
    }
    
    func whoSearchEntities(query: String) {
        if query.isEmpty {
            filteredWhoEntities = whoEntities
        } else {
            filteredWhoEntities = whoEntities.filter { entity in
                entity.name.lowercased().contains(query.lowercased())
            }
        }
    }
    
    //Formerly WhomViewModel
    var whomEntities: [Entity] = []
    var filteredWhomEntities: [Entity] = []
    
    func loadWhomEntities() {
        // Load your entities here
        // For example:
        //        whomEntities = [
        //            Entity(name: "Entity 1"),
        //            Entity(name: "Entity 2"),
        //            Entity(name: "Entity 3")
        //        ]
        //        filteredWhomEntities = whomEntities
    }
    
    func whomSearchEntities(query: String) {
        if query.isEmpty {
            filteredWhomEntities = whomEntities
        } else {
            filteredWhomEntities = whomEntities.filter { entity in
                entity.name.lowercased().contains(query.lowercased())
            }
        }
    }
    
    func clearButtonsTFsAndPickers() {
        selectedWho = whoPlaceholder
        selectedWhoUID = ""
        whatInt = 0
        whatValue = ""
        selectedWhom = whomPlaceholder
        selectedWhomUID = ""
        taxReasonIndex = 0
        personalReasonIndex = 0
        selectedProject = projectPlaceholder
        selectedProjectUID = ""
        selectedVehicle = vehiclePlaceholder
        selectedVehicleUID = ""
        howManyInt = 0
        howManyValue = ""
        odometerInt = 0
        odometerValue = ""
        notesValue = ""
        showWorkersCompToggle = false
        incursWorkersComp = false
    }
}


enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationFlow: Hashable {
    case login
    case signUp
}

// MARK: - Email and Password Authentication

extension Model {
    func signInWithEmailPassword() async -> Bool {
        authenticationState = .authenticating
        do {
            try await Auth.auth().signIn(withEmail: self.authEmail, password: self.authPassword)
            return true
        }
        catch  {
            print(error)
            errorMessage = error.localizedDescription
            authenticationState = .unauthenticated
            return false
        }
    }
    
    func signUpWithEmailPassword() async -> Bool {
        authenticationState = .authenticating
        do  {
            try await Auth.auth().createUser(withEmail: authEmail, password: authPassword)
            return true
        }
        catch {
            print(error)
            errorMessage = error.localizedDescription
            authenticationState = .unauthenticated
            return false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteAccount() async -> Bool {
        do {
            try await user?.delete()
            return true
        }
        catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

