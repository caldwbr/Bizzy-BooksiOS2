//
//  AddProjectView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import SwiftUI
import FirebaseDatabase

struct AddProjectView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var model: Model
    @State private var projectName = ""
    @State private var projectNotes = ""
    @State private var customer: Entity? = nil
    @State private var suggestedCustomers: [Entity] = []
    @State private var projectCustomerName = ""
    @State private var projectCustomerNameUID = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var ssn = ""
    @State private var ein = ""
    @State private var showingAddCustomerView = false
    @State private var showingSuggestions = true
    
    var body: some View {
        Form {
            Section {
                TextField("Project Name", text: $projectName)
                TextField("Project Notes", text: $projectNotes)
                nameFieldForCustomer
                ifStatementAndSuggestions
                mainFields
                saveProjectButton
            }
        }
    }
    
    @MainActor
    var nameFieldForCustomer: some View {
        Group {
            HStack {
                TextField("Customer Name", text: $projectCustomerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: projectCustomerName) { oldName, newName in
                        if (!newName.isEmpty && projectCustomerNameUID.isEmpty) {
                            showingSuggestions = true
                            model.searchEntities(entityName: projectCustomerName) { matchingEntities in
                                model.suggestedEntities = matchingEntities ?? []
                            }
                        }
                        else if (newName.isEmpty) {
                            showingSuggestions = false
                        }
                    }
                
                Button(action: {
                    showingAddCustomerView = true
                }) {
                    Image(systemName: "plus")
                }
                .padding()
                .sheet(isPresented: $showingAddCustomerView) {
                    AddCustomerView(model: model, projectCustomerName: $projectCustomerName, projectCustomerNameUID: $projectCustomerNameUID, email: $email, phone: $phone, street: $street, city: $city, state: $state, zip: $zip, ssn: $ssn, ein: $ein)
                }
            }
        }
    }
    
    @MainActor
    var ifStatementAndSuggestions: some View {
        Group {
            if showingSuggestions {
                Section() {
                    List(model.suggestedEntities, id: \.id) { entity in
                        Text(entity.name)
                            .onTapGesture {
                                customer = entity
                                projectCustomerName = entity.name
                                projectCustomerNameUID = entity.id
                                email = entity.email ?? ""
                                phone = entity.phone ?? ""
                                street = entity.street ?? ""
                                city = entity.city ?? ""
                                state = entity.state ?? ""
                                zip = entity.zip ?? ""
                                ssn = entity.ssn ?? ""
                                ein = entity.ein ?? ""
                                showingSuggestions = false
                            }
                    }
                }
            }
            Text("").frame(width: 1, height: 1)
        }
    }

    var mainFields: some View {
        Group {
            VStack {
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
                TextField("Street", text: $street)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Zip", text: $zip)
                TextField("SSN", text: $ssn)
                TextField("EIN", text: $ein)
            }
        }
    }
    
    @MainActor
    var saveProjectButton: some View {
        Button(action: {
            let newProject = Project(name: projectName, notes: projectNotes, customerName: projectCustomerName, customerUID: projectCustomerNameUID, jobsiteStreet: street, jobsiteCity: city, jobsiteState: state, jobsiteZip: zip, customerSSN: ssn, customerEIN: ein)
            model.selectedProject = newProject.name
            model.selectedProjectUID = newProject.id
            model.selectedWho = newProject.customerName
            model.selectedWhoUID = newProject.customerUID
            let newProjectDict = newProject.toDictionary() // Convert the Project to a dictionary
            Database.database().reference().child("users").child(model.uid).child("projects").child(newProject.id).setValue(newProjectDict) // Save the Project to Firebase
            model.showProjectSearchView = false
            presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Save Project")
        })
        .disabled(projectName.isEmpty || projectCustomerName.isEmpty || projectCustomerNameUID.isEmpty)
    }
}
