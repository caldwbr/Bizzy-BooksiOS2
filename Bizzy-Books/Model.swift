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
    var userEntity: Entity? = nil  // Replace YourEntityType with your actual data model.
    var uid: String = ""
    var userRef: DatabaseReference? = nil
    var itemsRef: DatabaseReference? = nil
    var entitiesRef: DatabaseReference? = nil
    var projectsRef: DatabaseReference? = nil
    var vehiclesRef: DatabaseReference? = nil
    var selectedCustomerName = ""
    var selectedCustomerNameUID = ""
    var youEntity: Entity? = nil
    var youBusinessEntity: YouBusinessEntity? = nil
    
    func configureFirebaseReferences() {
        uid = Auth.auth().currentUser?.uid ?? ""
        userRef = Database.database().reference().child("users").child(uid)
        itemsRef = Database.database().reference().child("users").child(uid).child("items")
        entitiesRef = Database.database().reference().child("users").child(uid).child("entities")
        projectsRef = Database.database().reference().child("users").child(uid).child("projects")
        vehiclesRef = Database.database().reference().child("users").child(uid).child("vehicles")
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
    
    func loadDataAndConcatenate() {
        loadItems()
        loadProjects()
        loadVehicles()
        loadEntities()
        
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
    
    var trialName = "Brad" // Assuming this is part of your class properties
    
    // Other properties and functions...
    
    var docuType: CustomerDocument = .contract
    
    func generateTaxPDFReport(forYear year: Int) -> Data? {
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
        
        return data
    }
    
    func generateCustomerPDFReport(forProjectUID projectUID: String) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "MyApp",
            kCGPDFContextAuthor: "app user",
            kCGPDFContextTitle: "\(docuType.displayName) for Project \(projectUID)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            
            // Header specific to document type and project
            let header = "\(docuType.displayName) Document for Project ID: \(projectUID)"
            header.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
            
            // Now, switch over the document type to customize the content
            switch docuType {
            case .contract:
                let text = "Contract Details for \(projectUID)"
                text.draw(at: CGPoint(x: 20, y: 50), withAttributes: titleAttributes)
                // Add more specific drawing code for contract document
                
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

