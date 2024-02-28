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
import FirebaseStorage
import FirebaseAuth
import SwiftUI
import Contacts

@MainActor
@Observable class Model {
    //Previously AuthenticationViewModel
    var authEmail = ""
    var authPassword = ""
    var authConfirmPassword = ""
    var hasLoaded = false
    
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
    //var fieldIsSearchEnabled = true
    var contacts: [CNContact] = []
    var predicate: NSPredicate = NSPredicate(value: false)
    
    let contactStore = CNContactStore()
    var suggestedContacts: [CNContact] = []
    var suggestedEntities: [Entity] = []
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
    
    func searchEntities(entityName: String, completion: @escaping ([Entity]?) -> Void) {
        // Filter the existing entities array based on the entityName
        let fetchedEntities = entities.filter { entity in
            return entity.name.contains(entityName)
        }
        
        DispatchQueue.main.async {
            completion(fetchedEntities)
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
        // fieldIsSearchEnabled = true
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
    
    func saveWhomEntity() {
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
        selectedWhom = newEntity.name
        selectedWhomUID = newEntity.id
        let newEntityDict = newEntity.toDictionary() // Convert the Entity to a dictionary
        Database.database().reference().child("users").child(uid).child("entities").child(newEntity.id).setValue(newEntityDict) // Save the Entity to Firebase
    }
    
    func saveCustomerEntity() {
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
        selectedCustomerName = newEntity.name
        selectedCustomerNameUID = newEntity.id
        let newEntityDict = newEntity.toDictionary() // Convert the Entity to a dictionary
        Database.database().reference().child("users").child(uid).child("entities").child(newEntity.id).setValue(newEntityDict) // Save the Entity to Firebase
    }
    
    //Previously MainScreenViewModel
    var items: [Item] = []
    var entities: [Entity] = []
    var projects: [Project] = []
    var vehicles: [Vehicle] = []
    var scopes: [Scope] = []
    var userEntity: Entity? = nil  // Replace YourEntityType with your actual data model.
    var uid: String = ""
    var userRef: DatabaseReference? = nil
    var itemsRef: DatabaseReference? = nil
    var entitiesRef: DatabaseReference? = nil
    var projectsRef: DatabaseReference? = nil
    var vehiclesRef: DatabaseReference? = nil
    var scopesRef: DatabaseReference? = nil
    var selectedCustomerName = ""
    var selectedCustomerNameUID = ""
    var youEntity: Entity? = nil
    var youBusinessEntity: YouBusinessEntity? = nil
    var projectOverhead: Project? = nil
    var projectNumbersRef: DatabaseReference? = nil
    var storageRef: StorageReference? = nil
    var logoStorageRef: StorageReference? = nil
    var termsPDFRef: StorageReference? = nil
    
    func configureFirebaseReferences() {
        uid = Auth.auth().currentUser?.uid ?? ""
        userRef = Database.database().reference().child("users").child(uid)
        itemsRef = Database.database().reference().child("users").child(uid).child("items")
        entitiesRef = Database.database().reference().child("users").child(uid).child("entities")
        projectsRef = Database.database().reference().child("users").child(uid).child("projects")
        vehiclesRef = Database.database().reference().child("users").child(uid).child("vehicles")
        scopesRef = Database.database().reference().child("users").child(uid).child("scopes")
        projectNumbersRef = Database.database().reference().child("users").child(uid).child("projectnumbers")
        storageRef = Storage.storage().reference(forURL: "gs://bizzy-books-2.appspot.com")
        logoStorageRef = storageRef?.child("\(uid)/logo.jpg")
        termsPDFRef = storageRef?.child("\(uid)/terms_and_conditions/current_terms.pdf")
    }
    
    func checkAndCreateYouEntity() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return // User is not logged in, so we can't create the entity.
        }
        
        let youRef = Database.database().reference().child("users").child(uid).child("entities").child(uid)
        
        youRef.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                self.youEntity =  Entity(name: "You", key: self.uid)
                if let youEntityDict = self.youEntity?.toDictionary() {
                    youRef.setValue(youEntityDict)
                }
            }
        }
        
        let overheadRef = Database.database().reference().child("users").child(uid).child("projects").child("OverheadID")
        
        overheadRef.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                self.projectOverhead = Project(name: "Overhead", key: "OverheadID")
                if let projectOverheadDict = self.projectOverhead?.toDictionary() {
                    overheadRef.setValue(projectOverheadDict)
                }
            }
        }
        
        let youBusinessEntityRef = Database.database().reference().child("users").child(uid).child("youbusinessentity")
        
        youBusinessEntityRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                if let youBusinessEntityRefDictionary = snapshot.value as? [String: Any] {
                    self.youBusinessEntity = YouBusinessEntity(fromDictionary: youBusinessEntityRefDictionary)
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
    var transactionYear = 0
    
    func sizeForElementContent(_ content: String, semanticType: SentenceElement.SemanticType) -> CGSize {
        // Calculate the size based on content and type
        // This is a placeholder - you'll need to implement actual size calculation
        let width = CGFloat(content.count * 10) // Example: 10 points per character
        let height: CGFloat = 30 // Example: fixed height
        return CGSize(width: width, height: height)
    }
    
    //Formerly ProjectViewModel
    var filteredProjects: [Project] = []
    var filteredEntities: [Entity] = []
    var universals: [Universal] = []
    var displayedUniversals: [Universal] = []
    var filteredUniversals: [Universal] = []
    let dataLoadGroup = DispatchGroup()
    
    func loadItems() {
        items.removeAll()
        dataLoadGroup.enter()
        itemsRef?.observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                self.items.append(Item(snapshot: item as! DataSnapshot))
            }
            self.dataLoadGroup.leave()
        })
    }
    
    func concatenateUniversals() {
        // Clear existing universals
        universals.removeAll()
        
        // Append items
        for item in items {
            let newUniversal = Universal(type: .item(item))
            universals.append(newUniversal)
        }
        
        // Append entities
        for entity in entities {
            let newUniversal = Universal(type: .entity(entity))
            universals.append(newUniversal)
        }
        
        // Append projects
        for project in projects {
            let newUniversal = Universal(type: .project(project))
            universals.append(newUniversal)
        }
        
        // Append vehicles
        for vehicle in vehicles {
            let newUniversal = Universal(type: .vehicle(vehicle))
            universals.append(newUniversal)
        }
        
        // Sort universals by timestamp
        universals.sort { $0.timestamp > $1.timestamp }
        
        // Update displayedUniversals if needed
        displayedUniversals = universals
        hasLoaded = true
    }

    
    func saveCustomTexts(for projectNumber: String, with templates: TextTemplates) {
        let db = Firestore.firestore()
        let projectRef = db.collection("projects").document(projectNumber)
        
        projectRef.updateData([
            "binderText": templates.binderText,
            "invoiceText": templates.invoiceText,
            "receiptText": templates.receiptText,
            "warrantyText": templates.warrantyText
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    func fetchCustomTexts(for projectNumber: String, completion: @escaping (TextTemplates?) -> Void) {
        let db = Firestore.firestore()
        let projectRef = db.collection("projects").document(projectNumber)
        
        projectRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let templates = TextTemplates(
                    binderText: data?["binderText"] as? String ?? "",
                    invoiceText: data?["invoiceText"] as? String ?? "",
                    receiptText: data?["receiptText"] as? String ?? "",
                    warrantyText: data?["warrantyText"] as? String ?? ""
                )
                completion(templates)
            } else {
                print("Document does not exist")
                completion(nil)
            }
        }
    }

    
    func loadProjects() {
        projects.removeAll()
        dataLoadGroup.enter()
        projectsRef?.observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                self.projects.append(Project(snapshot: item as! DataSnapshot))
            }
            self.dataLoadGroup.leave()
        })
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
        vehicles.removeAll()
        dataLoadGroup.enter()
        vehiclesRef?.observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                self.vehicles.append(Vehicle(snapshot: item as! DataSnapshot))
            }
            self.dataLoadGroup.leave()
        })
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
    var tailoredScopes: [TailoredScope] = []
    
    func updateDescription(id: String, newDescription: String) {
        if let index = tailoredScopes.firstIndex(where: { $0.id == id }) {
            var scope = tailoredScopes[index]
            scope.desc = newDescription
            tailoredScopes[index] = scope  // Replace the old struct with the updated one
        }
    }

    func updatePriceEa(id: String, newPriceEa: Int) {
        if let index = tailoredScopes.firstIndex(where: { $0.id == id }) {
            var scope = tailoredScopes[index]
            let isNegative = priceEaIsNegative[id] ?? false
            scope.priceEa = isNegative ? -abs(newPriceEa) : abs(newPriceEa)
            tailoredScopes[index] = scope  // Replace the old struct with the updated one
        }
    }
    
    func loadEntities() {
        entities.removeAll()
        dataLoadGroup.enter()
        entitiesRef?.observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                self.entities.append(Entity(snapshot: item as! DataSnapshot))
            }
            self.dataLoadGroup.leave()
        })
    }
    
    func loadScopes() {
        scopes.removeAll()
        dataLoadGroup.enter()
        scopesRef?.observeSingleEvent(of: .value, with: { snapshot in
            for scope in snapshot.children {
                self.scopes.append(Scope(snapshot: scope as! DataSnapshot))
            }
            self.dataLoadGroup.leave()
        })
    }
    
    func fetchTailoredScopes(forProjectUID projectUID: String, completion: @escaping (Bool) -> Void) {
        clearDocumentsBuffer()
        priceEaIsNegative.removeAll()
        let tailoredScopesRef = Database.database().reference().child("users").child(uid).child("tailoredscopes").child(projectUID)
        tailoredScopesRef.observeSingleEvent(of: .value, with: { snapshot in
            for tailoredScope in snapshot.children {
                self.tailoredScopes.append(TailoredScope(snapshot: tailoredScope as! DataSnapshot))
            }
            for tailoredScope in self.tailoredScopes {
                if tailoredScope.priceEa < 0 {
                    self.priceEaIsNegative[tailoredScope.id] = true
                } else {
                    self.priceEaIsNegative[tailoredScope.id] = false
                }
            }
            completion(true)
        }) { error in
            print(error.localizedDescription)
            completion(false)
        }
    }
    
    var selectedProjectUIDForCustDoc: String = ""
    
    func uploadTailoredScopes(completion: @escaping (Bool) -> Void) {
        // Reference to the Firebase node where tailored scopes will be stored
        let tailoredScopesRef = Database.database().reference().child("users").child(uid).child("tailoredscopes").child(selectedProjectUIDForCustDoc)

        // Loop over each tailored scope in the model
        for tailoredScope in tailoredScopes {
            // Convert each tailored scope to a dictionary suitable for Firebase
            let tailoredScopeDict = tailoredScope.toDictionary()
            // Use the tailored scope's id as the key for its Firebase node
            tailoredScopesRef.child(tailoredScope.id).setValue(tailoredScopeDict, withCompletionBlock: { error, _ in
                if let error = error {
                    print("Error uploading tailored scope: \(error.localizedDescription)")
                    completion(false)
                    return
                }
            })
        }

        // Call completion handler once all uploads have been initiated
        // Note: This does not guarantee all uploads have finished.
        // Consider a more robust completion handling mechanism if necessary.
        completion(true)
    }

    
    func loadLogo() {
        guard let logoStorageRefNotNil = logoStorageRef else {
            return
        }
        dataLoadGroup.enter()
        logoStorageRefNotNil.getData(maxSize: 1 * 1024 * 1024) { data, error in
            defer {
                self.dataLoadGroup.leave()
            }
            if let error = error {
                print("Error fetching logo: \(error)")
            } else if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.logoImage = image
                }
            }
        }
    }
    
    func loadDataAndConcatenate() {
        loadItems()
        loadProjects()
        loadVehicles()
        loadEntities()
        loadScopes()
        loadLogo()
        
        dataLoadGroup.notify(queue: .main) {
            self.concatenateUniversals()
        }
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
    var filteredWhomEntities: [Entity] = []
    var filteredCustomerEntities: [Entity] = []
    
    func whomSearchEntities(query: String) {
        if query.isEmpty {
            filteredWhomEntities = entities
        } else {
            filteredWhomEntities = entities.filter { entity in
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
        selectedCustomerName = ""
        selectedCustomerNameUID = ""
        howManyInt = 0
        howManyValue = ""
        odometerInt = 0
        odometerValue = ""
        notesValue = ""
        showWorkersCompToggle = false
        incursWorkersComp = false
    }
    
    func clearDocumentsBuffer() {
        tailoredScopes.removeAll()
    }
    
    func removeTailoredScope(withId id: String) {
        DispatchQueue.main.async {
            self.tailoredScopes.removeAll { $0.id == id }
        }
    }
    
    var trialName = "Brad" // Assuming this is part of your class properties
    
    var whatIsNegative = false
    var priceEaIsNegative: [String: Bool] = [:]

    // Business Expenses
    var tdGrossIncome = 0
    var tdNonLaborExpenses = 0
    var tdTotalExpenses = 0
    var tdSupplies = 0
    var tdLabor = 0
    var tdVehicle = 0
    var tdProHelp = 0
    var tdInsurance = 0 // Assuming "Ins (WC+GL)" stands for Insurance (Workers' Compensation + General Liability)
    var tdTaxLicense = 0
    var tdTravel = 0
    var tdMeals = 0
    var tdOffice = 0 // Note: "Office" appears twice in your list. Ensure to differentiate or consolidate as needed.
    var tdAdvertising = 0
    var tdMachineRent = 0
    var tdPropertyRent = 0
    var tdEmpBenefit = 0
    var tdDepreciation = 0
    var tdDepletion = 0
    var tdUtilitiesBusiness = 0 // Renamed to differentiate from personal "Utilities"
    var tdCommissions = 0
    var tdWages = 0
    var tdMortgageInt = 0
    var tdOtherInt = 0
    var tdRepairs = 0
    var tdPension = 0

    // Personal Expenses (assuming these are separate categories)
    var tdPersonalReason = 0
    var tdFood = 0
    var tdFun = 0
    var tdPet = 0
    var tdUtilitiesPersonal = 0 // Renamed to differentiate from business "Utilities"
    var tdPhone = 0
    var tdInternet = 0
    var tdOfficePersonal = 0 // Assuming differentiation from business "Office"
    var tdMedical = 0
    var tdTravelPersonal = 0 // Assuming differentiation from business "Travel"
    var tdClothes = 0
    var tdOtherPersonal = 0

    var tdNetIncome = 0
    var itemsByYear: [Item] = []
    
    func resetTDValues() {
        tdGrossIncome = 0
        tdNonLaborExpenses = 0
        tdTotalExpenses = 0
        tdSupplies = 0
        tdLabor = 0
        tdVehicle = 0
        tdProHelp = 0
        tdInsurance = 0 // Assuming "Ins (WC+GL)" stands for Insurance (Workers' Compensation + General Liability)
        tdTaxLicense = 0
        tdTravel = 0
        tdMeals = 0
        tdOffice = 0 // Note: "Office" appears twice in your list. Ensure to differentiate or consolidate as needed.
        tdAdvertising = 0
        tdMachineRent = 0
        tdPropertyRent = 0
        tdEmpBenefit = 0
        tdDepreciation = 0
        tdDepletion = 0
        tdUtilitiesBusiness = 0 // Renamed to differentiate from personal "Utilities"
        tdCommissions = 0
        tdWages = 0
        tdMortgageInt = 0
        tdOtherInt = 0
        tdRepairs = 0
        tdPension = 0

        // Personal Expenses (assuming these are separate categories)
        tdPersonalReason = 0
        tdFood = 0
        tdFun = 0
        tdPet = 0
        tdUtilitiesPersonal = 0 // Renamed to differentiate from business "Utilities"
        tdPhone = 0
        tdInternet = 0
        tdOfficePersonal = 0 // Assuming differentiation from business "Office"
        tdMedical = 0
        tdTravelPersonal = 0 // Assuming differentiation from business "Travel"
        tdClothes = 0
        tdOtherPersonal = 0

        tdNetIncome = 0
    }
    
    // Tax Reason Int to String Mapping
    // 0 - "tax reason" (General or default category)
    // 1 - "Income"
    // 2 - "Supplies"
    // 3 - "Labor"
    // 4 - "Vehicle"
    // 5 - "Pro Help" (Professional Help)
    // 6 - "Ins (WC+GL)" (Insurance, including Workers' Compensation and General Liability)
    // 7 - "Tax+License" (Taxes and Licenses)
    // 8 - "Travel"
    // 9 - "Meals"
    // 10 - "Office" (Office Expenses)
    // 11 - "Advertising"
    // 12 - "Machine Rent"
    // 13 - "Property Rent"
    // 14 - "Emp Benefit" (Employee Benefits)
    // 15 - "Depreciation"
    // 16 - "Depletion"
    // 17 - "Utilities"
    // 18 - "Commissions"
    // 19 - "Wages"
    // 20 - "Mortgage Int" (Mortgage Interest)
    // 21 - "Other Int" (Other Interest)
    // 22 - "Repairs"
    // 23 - "Pension"
    
    // Personal Reason Int to String Mapping
    // 0 - "personal reason" (General or default category)
    // 1 - "Food"
    // 2 - "Fun"
    // 3 - "Pet"
    // 4 - "Utilities"
    // 5 - "Phone"
    // 6 - "Internet"
    // 7 - "Office" (Home Office or Personal Office Expenses)
    // 8 - "Medical"
    // 9 - "Travel"
    // 10 - "Clothes"
    // 11 - "Other" (Miscellaneous Personal Expenses)
    
    struct WorkersCompRecord {
        var workerName: String
        var incurredWC: Int
        var noWC: Int
        var total: Int
    }
    
    struct FuelStopRecord {
        var date: Date
        var gasStation: String
        var odometer: Int
        var amountSpent: Int
        var gallonsFilled: Int
    }
    
    struct ProjectRecord {
        var projectName: String
        var grossIncome: Int
        var materialsCost: Int
        var laborAndProHelpCost: Int
        var netIncome: Int {
            grossIncome - (materialsCost + laborAndProHelpCost)
        }
    }

    var workersCompRecords: [WorkersCompRecord] = []
    var vehicleFuelStops: [String: [FuelStopRecord]] = [:]
    var projectRecords: [ProjectRecord] = []
    
    func calculateTaxData(forYear year: Int) {
        itemsByYear.removeAll()
        workersCompRecords.removeAll()
        vehicleFuelStops.removeAll()
        projectRecords.removeAll()
        itemsByYear = items.filter { $0.year == year }
        resetTDValues()
        // Temporary storage for aggregating data
        var tempWorkersCompData: [String: (name: String, incurredWC: Int, noWC: Int)] = [:]
        var projectData: [String: (name: String, grossIncome: Int, materialsCost: Int, laborAndProHelpCost: Int)] = [:]
        
        for item in itemsByYear {
            if item.itemType == .business {
                if !item.projectID.isEmpty {
                    let projectID = item.projectID
                    let projectName = getProjectName(by: projectID)
                    
                    // Initialize data structure if necessary
                    if projectData[projectID] == nil {
                        projectData[projectID] = (name: projectName, grossIncome: 0, materialsCost: 0, laborAndProHelpCost: 0)
                    }
                    
                    switch item.taxReasonInt {
                    case 1: // Income
                        projectData[projectID]?.grossIncome += item.what
                    case 3, 5: // Labor or Pro Help
                        projectData[projectID]?.laborAndProHelpCost += item.what
                    case 0: // Ignore default,  as they are not part of the calculations here
                        break
                    default: // Materials (everything else except Income, Labor, and Pro Help)
                        projectData[projectID]?.materialsCost += item.what
                    }
                }
                if item.taxReasonInt == 3 {
                    let workerName = getWorkerName(by: item.whomID)
                    
                    // Initialize or update the worker's comp data for this worker
                    if var workerData = tempWorkersCompData[item.whomID] {
                        if item.workersComp {
                            workerData.incurredWC += item.what
                        } else {
                            workerData.noWC += item.what
                        }
                        tempWorkersCompData[item.whomID] = workerData
                    } else {
                        tempWorkersCompData[item.whomID] = (name: workerName, incurredWC: item.workersComp ? item.what : 0, noWC: !item.workersComp ? item.what : 0)
                    }
                }
                switch item.taxReasonInt {
                case 1:
                    tdGrossIncome += item.what
                case 2:
                    tdSupplies += item.what
                case 3:
                    tdLabor += item.what
                case 4:
                    tdVehicle += item.what
                case 5:
                    tdProHelp += item.what
                case 6:
                    tdInsurance += item.what
                case 7:
                    tdTaxLicense += item.what
                case 8:
                    tdTravel += item.what
                case 9:
                    tdMeals += item.what
                case 10:
                    tdOffice += item.what
                case 11:
                    tdAdvertising += item.what
                case 12:
                    tdMachineRent += item.what
                case 13:
                    tdPropertyRent += item.what
                case 14:
                    tdEmpBenefit += item.what
                case 15:
                    tdDepreciation += item.what
                case 16:
                    tdDepletion += item.what
                case 17:
                    tdUtilitiesBusiness += item.what
                case 18:
                    tdCommissions += item.what
                case 19:
                    tdWages += item.what
                case 20:
                    tdMortgageInt += item.what
                case 21:
                    tdOtherInt += item.what
                case 22:
                    tdRepairs += item.what
                case 23:
                    tdPension += item.what
                default:
                    // Handle any other cases or log an unexpected value
                    print("Unexpected tax reason: \(item.taxReasonInt)")
                }
            } else if item.itemType == .personal { // Assuming differentiation based on itemType
                switch item.personalReasonInt {
                case 1:
                    tdFood += item.what
                case 2:
                    tdFun += item.what
                case 3:
                    tdPet += item.what
                case 4:
                    tdUtilitiesPersonal += item.what
                case 5:
                    tdPhone += item.what
                case 6:
                    tdInternet += item.what
                case 7:
                    tdOfficePersonal += item.what
                case 8:
                    tdMedical += item.what
                case 9:
                    tdTravelPersonal += item.what
                case 10:
                    tdClothes += item.what
                case 11:
                    tdOtherPersonal += item.what
                default:
                    // Handle any other cases or log an unexpected value
                    print("Unexpected personal reason: \(item.personalReasonInt)")
                }
            }  else if item.itemType == .fuel {
                let date = Date(timeIntervalSince1970: item.timeStamp)
                let fuelStop = FuelStopRecord(
                    date: date,
                    gasStation: item.whom,
                    odometer: item.odometer,
                    amountSpent: item.what,
                    gallonsFilled: item.howMany
                )
                
                // Append this record to the correct vehicle's array
                if var stops = vehicleFuelStops[item.vehicleID] {
                    stops.append(fuelStop)
                    vehicleFuelStops[item.vehicleID] = stops
                } else {
                    vehicleFuelStops[item.vehicleID] = [fuelStop]
                }
            }
        }
        projectRecords = projectData.values.map {
                ProjectRecord(projectName: $0.name, grossIncome: $0.grossIncome, materialsCost: $0.materialsCost, laborAndProHelpCost: $0.laborAndProHelpCost)
            }
        // Convert the temporary storage into your final WorkersCompRecords array
        workersCompRecords = tempWorkersCompData.map { id, data in
            WorkersCompRecord(workerName: data.name, incurredWC: data.incurredWC, noWC: data.noWC, total: data.incurredWC + data.noWC)
        }
        // At this point, all the variables like tdGrossIncome, tdSupplies, etc.,
        // hold the summation of their respective categories for the given year.
        // Summation of all tax reasons to get total expenses
        tdNonLaborExpenses = tdSupplies + tdVehicle + tdProHelp + tdInsurance +
                          tdTaxLicense + tdTravel + tdMeals + tdOffice + tdAdvertising +
                          tdMachineRent + tdPropertyRent + tdEmpBenefit + tdDepreciation +
                          tdDepletion + tdUtilitiesBusiness + tdCommissions + tdWages +
                          tdMortgageInt + tdOtherInt + tdRepairs + tdPension
        tdTotalExpenses = tdNonLaborExpenses + tdLabor
        //print("Vehicle Fuel Stops: \(vehicleFuelStops)")
    }
    
    func getProjectName(by id: String) -> String {
        // For example, look up the project in a projects array
        if let matchingProject = projects.first(where: { $0.id == id }) {
            return matchingProject.name
        } else {
            return "Name not found for ID \(id)"
        }
    }
    
    func getWorkerName(by id: String) -> String {
        // Use the `first(where:)` method to find the matching entity
        if let matchingEntity = entities.first(where: { $0.id == id }) {
            // If found, return the entity's name
            return matchingEntity.name
        } else {
            // If not found, return a default value or indicate not found
            return "Name not found for ID \(id)"
        }
    }
    
    var docuType: CustomerDocument = .contract
    var isGeneratingPDF = false
    var logoImageURL = ""
    var logoImage: UIImage? = nil
    
    func generateTaxPDFReport(forYear year: Int) -> Data? {
        isGeneratingPDF = true
        calculateTaxData(forYear: year)
        let pdfMetaData = [
            kCGPDFContextCreator: "MyApp",
            kCGPDFContextAuthor: "app user",
            kCGPDFContextTitle: "Financial Report for Fiscal Year \(year)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            // Define your text attributes
            let attributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            // Customize the header of your PDF with the fiscal year
            let header = "Financial Report for Fiscal Year \(year)"
            header.draw(at: CGPoint(x: 20, y: 20), withAttributes: attributes)
            
            // Example drawing code, replace or expand with your content
            let text = "User Report for \(self.trialName)"
            text.draw(at: CGPoint(x: 20, y: 50), withAttributes: attributes)
            
            // Add more content as needed, such as financial data for the year
            // You might loop through your data here, drawing each item
        }
        isGeneratingPDF = false
        return data
    }
    
    func generateCustomerPDFReport(forProjectUID projectUID: String) -> Data? {
        isGeneratingPDF = true
        let pdfMetaData = [
            kCGPDFContextCreator: "MyApp",
            kCGPDFContextAuthor: "app user",
            kCGPDFContextTitle: "\(docuType.displayName) for Project \(projectUID)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "MinionPro-Regular", size: 12)!,
                .foregroundColor: UIColor.black
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            let fontAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "MinionPro-Regular", size: 12)!,
                .foregroundColor: UIColor.black
            ]
            let attributesBold: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "minionpro-bold", size: 12)!,
                .foregroundColor: UIColor.black
            ]
            let attributesRegular: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "MinionPro-Regular", size: 10)!,
                .foregroundColor: UIColor.black
            ]
            let leftMargin: CGFloat = 40.0
            let rightMargin: CGFloat = 40.0
            let maxWidth = pageWidth - leftMargin - rightMargin

            var currentYPosition: CGFloat = 120  // Initial Y position for the first item
            let itemSpacing: CGFloat = 20.0
            let smallSpacing: CGFloat = 5.0
            let tinySpacing: CGFloat = 2.0
            
            // Header specific to document type and project
            //let header = "\(docuType.displayName) Document for Project ID: \(projectUID)"
            //header.draw(at: CGPoint(x: 20, y: 20), withAttributes: fontAttributes)
            
            // Now, switch over the document type to customize the content
            switch docuType {
            case .contract:
                //let text = "Contract Details for \(projectUID)"
                //text.draw(at: CGPoint(x: 20, y: 50), withAttributes: titleAttributes)
                // Add more specific drawing code for contract document
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                let dateString = dateFormatter.string(from: Date())
                let dateAttributes = [NSAttributedString.Key.font: UIFont(name: "MinionPro-Regular", size: 10)!]
                let dateStringSize = dateString.size(withAttributes: dateAttributes)
                dateString.draw(at: CGPoint(x: pageWidth - dateStringSize.width - 60 - 50, y: 56), withAttributes: dateAttributes)

                let createdText = "Created with Bizzy Books"
                let createdTextSize = createdText.size(withAttributes: dateAttributes)
                createdText.draw(at: CGPoint(x: pageWidth - createdTextSize.width - 60 - 50, y: 80), withAttributes: dateAttributes)
                
                var projNumby = 1000
                
                // Find the project with the matching id
                if let matchingProject = projects.first(where: { $0.id == projectUID }) {
                    // If a matching project is found, print or use its projectNumber
                    projNumby = matchingProject.projectNumber
                }
                let projNumbyStr = "Project Number: " + String(projNumby)
                let projNumbyStrSize = projNumbyStr.size(withAttributes: dateAttributes)
                projNumbyStr.draw(at: CGPoint(x: pageWidth - projNumbyStrSize.width - 60 - 50, y: 68), withAttributes: dateAttributes)

                let projectContractText = "Project Contract"
                let projectContractAttributes = [NSAttributedString.Key.font: UIFont(name: "minionpro-bold", size: 20)!]
                let projectContractSize = projectContractText.size(withAttributes: projectContractAttributes)
                //let projectContractX = (pageWidth - projectContractSize.width) / 2
                projectContractText.draw(at: CGPoint(x: 170, y: 30), withAttributes: projectContractAttributes)
                
                let businessName = youBusinessEntity?.name ?? ""

                let infoAttributes = [NSAttributedString.Key.font: UIFont(name: "MinionPro-Regular", size: 10)!, NSAttributedString.Key.foregroundColor: UIColor.black]

                
                
                // Contractor Info
                let streetPre = youBusinessEntity?.street ?? ""
                let cityPre = youBusinessEntity?.city ?? ""
                let statePre = youBusinessEntity?.state ?? ""
                let zipPre = youBusinessEntity?.zip ?? ""
                let street = streetPre.trimmingCharacters(in: .whitespaces)
                let city = cityPre.trimmingCharacters(in: .whitespaces)
                let state = statePre.trimmingCharacters(in: .whitespaces)
                let zip = zipPre.trimmingCharacters(in: .whitespaces)

                let businessPhone = youBusinessEntity?.phone ?? ""
                let businessEmail = youBusinessEntity?.email ?? ""
                let businessPhoneEmail = "\(businessPhone) \(businessEmail)"
                
                // Start with the street part
                var businessAddress = ""

                // Check if street is not empty, append it with a semicolon
                if !street.isEmpty {
                    businessAddress += street + "; "
                }

                // Now construct the rest of the address on the same line
                // Join city and state with a comma only if both are present
                var cityState = [city, state].filter { !$0.isEmpty }.joined(separator: ", ")

                // Append ZIP directly after state, without a comma
                if !state.isEmpty && !zip.isEmpty {
                    cityState += " " + zip // Add a space before ZIP if state is also present
                } else if !zip.isEmpty {
                    cityState += zip // Just append ZIP if no state is present
                }

                // Append cityState to businessAddress, ensuring it's not empty
                if !cityState.isEmpty {
                    businessAddress += cityState
                }
                
                businessName.draw(at: CGPoint(x: 170, y: 56), withAttributes: infoAttributes)

                // Draw business phone, adjust `y` value for spacing
                businessPhoneEmail.draw(at: CGPoint(x: 170, y: 68), withAttributes: infoAttributes)

                // Draw business email, adjust `y` value for spacing
                businessAddress.draw(at: CGPoint(x: 170, y: 80), withAttributes: infoAttributes)


                if let bizzyBooksIcon = UIImage(named: "bizzyBeeImage") {
                    let iconRect = CGRect(x: pageRect.width - 100, y: 30, width: 60, height: 60) // Adjust size and position as needed
                    
                    // Save the current graphics state
                    context.cgContext.saveGState()
                    
                    // Flip the context coordinates
                    context.cgContext.translateBy(x: 0, y: pageRect.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                    
                    // Now the drawing coordinates are flipped, draw the image
                    // Adjust the y-position of the iconRect to account for the flipped coordinate system
                    let flippedIconRect = CGRect(x: iconRect.origin.x, y: pageRect.height - iconRect.origin.y - iconRect.height, width: iconRect.width, height: iconRect.height)
                    context.cgContext.draw(bizzyBooksIcon.cgImage!, in: flippedIconRect)
                    
                    // Restore the graphics state to normal
                    context.cgContext.restoreGState()
                }
                if let companyLogo = logoImage {
                    let logoWidth: CGFloat = 120
                    let logoHeight: CGFloat = 60 // Adjust as needed to maintain aspect ratio
                    let logoXPosition: CGFloat = 40 // Left side
                    let logoYPosition: CGFloat = 30 // Top
                    
                    // Calculate the aspect ratio of the image to maintain it
                    let aspectRatio = companyLogo.size.width / companyLogo.size.height
                    let adjustedLogoHeight = logoWidth / aspectRatio // Adjust height based on actual aspect ratio
                    
                    // Define the rectangle for the image
                    let logoRect = CGRect(x: logoXPosition, y: logoYPosition, width: logoWidth, height: adjustedLogoHeight)
                    
                    // Draw the image
                    if let cgImage = companyLogo.cgImage {
                        context.cgContext.saveGState()
                        context.cgContext.translateBy(x: 0, y: pageRect.height)
                        context.cgContext.scaleBy(x: 1.0, y: -1.0)
                        let flippedLogoRect = CGRect(x: logoRect.origin.x, y: pageRect.height - logoRect.origin.y - adjustedLogoHeight, width: logoWidth, height: adjustedLogoHeight)
                        context.cgContext.draw(cgImage, in: flippedLogoRect)
                        context.cgContext.restoreGState()
                    }
                }
                let lineYPosition: CGFloat = 100  // Y position of the line
                let lineWidth: CGFloat = 1.0  // Line thickness
                let lineColor: UIColor = .black  // Line color
                let margin: CGFloat = 40.0  // Margin on either side
                
                context.cgContext.setStrokeColor(lineColor.cgColor)
                context.cgContext.setLineWidth(lineWidth)
                // Adjust the start and end points to account for the margin
                context.cgContext.move(to: CGPoint(x: margin, y: lineYPosition))
                context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: lineYPosition))
                context.cgContext.strokePath()
                
                var customerBlockNameLiteral = "Customer:"
                var customerBlockName = ""
                var customerBlockSiteStreet = ""
                var customerBlockSiteCityStateZip = ""
                if let matchingProject = projects.first(where: { $0.id == projectUID }) {
                    // If a matching project is found, print or use its projectNumber
                    customerBlockName = matchingProject.customerName
                    customerBlockSiteStreet = matchingProject.jobsiteStreet
                    customerBlockSiteCityStateZip = "\(matchingProject.jobsiteCity.trimmingCharacters(in: .whitespaces)), \(matchingProject.jobsiteState) \(matchingProject.jobsiteZip)"
                }
                
                // Drawing the customer information
                let customerLiteralAttributedString = NSAttributedString(string: customerBlockNameLiteral, attributes: attributesBold)
                customerLiteralAttributedString.draw(at: CGPoint(x: leftMargin, y: currentYPosition))
                currentYPosition += customerLiteralAttributedString.size().height + tinySpacing

                let customerNameAttributedString = NSAttributedString(string: customerBlockName, attributes: infoAttributes)
                customerNameAttributedString.draw(at: CGPoint(x: leftMargin, y: currentYPosition))
                currentYPosition += customerNameAttributedString.size().height + tinySpacing

                let customerStreetAttributedString = NSAttributedString(string: customerBlockSiteStreet, attributes: infoAttributes)
                customerStreetAttributedString.draw(at: CGPoint(x: leftMargin, y: currentYPosition))
                currentYPosition += customerStreetAttributedString.size().height + tinySpacing

                let customerCityStateZipAttributedString = NSAttributedString(string: customerBlockSiteCityStateZip, attributes: infoAttributes)
                customerCityStateZipAttributedString.draw(at: CGPoint(x: leftMargin, y: currentYPosition))
                currentYPosition += customerCityStateZipAttributedString.size().height + itemSpacing

                
                for tailoredScope in tailoredScopes {
                    // Drawing the title string with name, price, and quantity
                    let priceInDollars = Double(tailoredScope.priceEa) / 100.0
                    let formattedPrice = formatter.string(from: NSNumber(value: priceInDollars)) ?? "$0.00"

                    let titleString = "\(tailoredScope.name) \(formattedPrice)"
                    let titleAttributedString = NSAttributedString(string: titleString, attributes: attributesBold)
                    titleAttributedString.draw(at: CGPoint(x: leftMargin, y: currentYPosition))
                    currentYPosition += titleAttributedString.size().height + smallSpacing

                    // Preparing and drawing the description string with wrapping
                    let descString = tailoredScope.desc
                    let descAttributedString = NSAttributedString(string: descString, attributes: attributesRegular)
                    let descDrawingRect = CGRect(x: leftMargin, y: currentYPosition, width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
                    let descBoundingRect = descAttributedString.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                    
                    // Ensure the drawing operation respects the calculated bounding rectangle
                    descAttributedString.draw(with: descDrawingRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                    currentYPosition += descBoundingRect.height + itemSpacing
                }
                
                var bindyText = ""
                if let matchingProject = projects.first(where: { $0.id == projectUID }) {
                    // If a matching project is found, print or use its projectNumber
                    bindyText = matchingProject.binderText
                }
                // Preparing the binderText string with wrapping, similar to the description
                let bindyAttributedString = NSAttributedString(string: bindyText, attributes: attributesRegular)
                let bindyDrawingRect = CGRect(x: leftMargin, y: currentYPosition, width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
                let bindyBoundingRect = bindyAttributedString.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

                // Draw the binderText respecting the calculated bounding rectangle
                bindyAttributedString.draw(with: bindyDrawingRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                currentYPosition += bindyBoundingRect.height + itemSpacing
                
                // Calculate positions for the text labels
                let contractorText = "Contractor signature/date:"
                let customerText = "Customer signature/date:"
                // Define the signature box dimensions
                let signatureBoxHeight: CGFloat = 50 // Height of the signature boxes
                let boxWidth: CGFloat = (maxWidth / 2) - 20 // Half the maxWidth minus some margin

                // Calculate the y position for the text to appear above the boxes
                let textYPosition = currentYPosition // Adjust as needed to position the text above the boxes

                // Draw the "Contractor:" label
                contractorText.draw(at: CGPoint(x: leftMargin, y: textYPosition), withAttributes: attributesBold)

                // Draw the "Customer:" label, adjusting the x position to align with the customer box
                customerText.draw(at: CGPoint(x: leftMargin + boxWidth + 20, y: textYPosition), withAttributes: attributesBold)
                currentYPosition += itemSpacing

                // Contractor Signature Box
                let contractorSignatureBoxRect = CGRect(x: leftMargin, y: currentYPosition, width: boxWidth, height: signatureBoxHeight)

                // Customer Signature Box (placed to the right of the contractor's box with some spacing)
                let customerSignatureBoxRect = CGRect(x: leftMargin + boxWidth + 20, y: currentYPosition, width: boxWidth, height: signatureBoxHeight) // 20 is double the spacing for margin

                // Drawing the rectangle for contractor's signature box
                if let context = UIGraphicsGetCurrentContext() {
                    context.setStrokeColor(UIColor.black.cgColor) // Set the outline color
                    context.setLineWidth(2) // Set the line width
                    
                    // Draw the contractor's rectangle outline
                    context.stroke(contractorSignatureBoxRect)
                    
                    // Draw the customer's rectangle outline
                    context.stroke(customerSignatureBoxRect)
                }

                // Update currentYPosition for content below the signature boxes
                currentYPosition += signatureBoxHeight + 10 // Adjust based on your layout needs
                
                var underSigContractor = businessName
                underSigContractor.draw(at: CGPoint(x: leftMargin, y: currentYPosition), withAttributes: infoAttributes)
                var underSigCustomer = customerBlockName
                underSigCustomer.draw(at: CGPoint(x: leftMargin + boxWidth + 20, y: currentYPosition), withAttributes: infoAttributes)
                
            case .invoice:
                let text = "Invoice Details for \(projectUID)"
                text.draw(at: CGPoint(x: 20, y: 50), withAttributes: titleAttributes)
                // Add more specific drawing code for invoice document
                
            case .receipt:
                let text = "Receipt Details for \(projectUID)"
                text.draw(at: CGPoint(x: 20, y: 50), withAttributes: titleAttributes)
                // Add more specific drawing code for receipt document
                
            case .warranty:
                let text = "Warranty Details for \(projectUID)"
                text.draw(at: CGPoint(x: 20, y: 50), withAttributes: titleAttributes)
                // Add more specific drawing code for warranty document
            }
            
            // Use similar logic to add more content based on the document type
        }
        isGeneratingPDF = false
        return data
    }

    
    func savePDFDataToTemporaryFile(_ data: Data) throws -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString + ".pdf")
        try data.write(to: temporaryFileURL)
        return temporaryFileURL
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

