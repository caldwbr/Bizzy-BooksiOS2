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
    //var db:

    func configureFirebaseReferences() {
        uid = Auth.auth().currentUser?.uid ?? ""
        userRef = Database.database().reference().child("users").child(uid)
        itemsRef = userRef!.child("items")
        entitiesRef = userRef!.child("entities")
        projectsRef = userRef!.child("projects")
        vehiclesRef = userRef!.child("vehicles")
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

        let youEntityRef = Database.database().reference().child("users").child(uid).child("entities").child(uid)
        let db = Database.database().reference()
        let example = db.child("users").child(uid)
        let entityish = example.child("entities")
        let meID = UUID().uuidString
        let meUsey: [String: Any] = ["name": "You", "id": meID]
        let me = Entity(name: "You").toDictionary()
        entityish.setValue(me)
        
        //entityish.setValue(meUsey)
        /*
        youEntityRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                // "you" entity already exists, retrieve it if needed.
            } else {
                // "you" entity does not exist, create it and upload to the Realtime Database.
                let newEntity = Entity(id: uid, name: "You")
                let newEntityData = newEntity.toDictionary

                youEntityRef.setValue(newEntityData) { error, _ in
                    if let error = error {
                        print("Error creating/updating entity: \(error)")
                    } else {
                        self.userEntity = newEntity
                    }
                }
            }
        } */
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
    
    func createItemFromScratch(
        latitude: Double,
        longitude: Double,
        itemType: ItemType,
        notes: String?,
        who: String,
        whoID: String,
        what: Int,
        whom: String,
        whomID: String,
        personalReasonInt: Int,
        taxReasonInt: Int,
        vehicleName: String?,
        vehicleID: String?,
        workersComp: Bool,
        projectName: String?,
        projectID: String?,
        howMany: Int?,
        odometer: Int?
    ) -> Item {
        // Create a new 'Item' with the provided parameters.
        let newItem = Item(
            latitude: latitude,
            longitude: longitude,
            itemType: itemType,
            notes: notes,
            who: who,
            whoID: whoID,
            what: what,
            whom: whom,
            whomID: whomID,
            personalReasonInt: personalReasonInt,
            taxReasonInt: taxReasonInt,
            vehicleName: vehicleName,
            vehicleID: vehicleID,
            workersComp: workersComp,
            projectName: projectName,
            projectID: projectID,
            howMany: howMany,
            odometer: odometer
        )

        // Return the newly created 'Item'.
        return newItem
    }
    
    func createEntityFromScratch(
        
        name: String,
        businessName: String?,
        street: String?,
        city: String?,
        state: String?,
        zip: String?,
        phone: String?,
        email: String?,
        ein: String?,
        ssn: String?
    ) -> Entity {
        // Create a new 'Entity' with the provided parameters.
        let newEntity = Entity(
            name: name,
            businessName: businessName,
            street: street,
            city: city,
            state: state,
            zip: zip,
            phone: phone,
            email: email,
            ein: ein,
            ssn: ssn
        )

        // Return the newly created 'Entity'.
        return newEntity
    }

    func createVehicleFromScratch(
        year: String,
        make: String,
        model: String,
        color: String?,
        picd: String?,
        vin: String?,
        licPlateNo: String?
    ) -> Vehicle {
        // Create a new 'Vehicle' with the provided parameters.
        let newVehicle = Vehicle(
            year: year,
            make: make,
            model: model,
            color: color,
            picd: picd,
            vin: vin,
            licPlateNo: licPlateNo
        )

        // Return the newly created 'Vehicle'.
        return newVehicle
    }

    func createProjectFromScratch(
        name: String,
        notes: String?,
        customer: Entity?,
        jobsiteStreet: String?,
        jobsiteCity: String?,
        jobsiteState: String?,
        jobsiteZip: String?
    ) -> Project {
        // Create a new 'Project' with the provided parameters.
        let newProject = Project(
            name: name,
            notes: notes,
            customer: customer,
            jobsiteStreet: jobsiteStreet,
            jobsiteCity: jobsiteCity,
            jobsiteState: jobsiteState,
            jobsiteZip: jobsiteZip
        )

        // Return the newly created 'Project'.
        return newProject
    }

    
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

