//
//  AddProjectView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import SwiftUI
import FirebaseDatabase

struct AddProjectView: View {
    @Bindable var model: Model
    @State private var projectName = ""
    @State private var projectNotes = ""
    @State private var customer: Entity? = nil
    @State private var suggestedCustomers: [Entity] = []
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var showingAddCustomerView = false

    var body: some View {
        Form {
            Section(header: Text("Add Project")) {
                TextField("Project Name", text: $projectName)
                TextField("Project Notes", text: $projectNotes)
                HStack {
                    TextField("Name", text: $model.customerName)
                        .onChange(of: model.customerName) { newName, _ in
                            suggestedCustomers = searchCustomers(for: newName)
                        }
                    ForEach(suggestedCustomers, id: \.id) { customer in
                        Text(customer.name)
                            .onTapGesture {
                                fillInCustomerDetails(for: customer)
                            }
                    }
                    Button(action: {
                        showingAddCustomerView = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .sheet(isPresented: $showingAddCustomerView) {
                        AddCustomerView(model: model)
                    }
                }
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
                TextField("Street", text: $street)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Zip", text: $zip)
            }
            
            Section {
                Button(action: {
                    let newProject = Project(
                        name: projectName,
                        notes: projectNotes,
                        customerName: model.customerName,
                        customerUID: model.customerUID,
                        jobsiteStreet: street,
                        jobsiteCity: city,
                        jobsiteState: state,
                        jobsiteZip: zip
                    )
                    model.selectedProject = newProject.name
                    model.selectedProjectUID = newProject.id
                    model.selectedWho = newProject.customerName
                    model.selectedWhoUID = newProject.customerUID
                    let newProjectDict = newProject.toDictionary() // Convert the Project to a dictionary
                    Database.database().reference().child("users").child(model.uid).child("projects").child(newProject.id).setValue(newProjectDict) // Save the Project to Firebase
                }, label: {
                    Text("Save Project")
                })
                .disabled(projectName.isEmpty || model.customerName.isEmpty || model.customerUID.isEmpty)
            }
        }
    }
    
    func searchCustomers(for query: String) -> [Entity] {
        var matchingCustomers: [Entity] = []
        
        if ((customer?.name.contains(query.lowercased())) != nil) {
            matchingCustomers.append(customer!)
        }
        return matchingCustomers
    }
    
    @MainActor
    func fillInCustomerDetails(for customer: Entity) {
        model.customerName = customer.name
        model.customerUID = customer.id
        if let jobsiteStreet = customer.street {
            self.street = jobsiteStreet
        }
        if let jobsiteCity = customer.city {
            self.city = jobsiteCity
        }
        if let jobsiteState = customer.state {
            self.state = jobsiteState
        }
        if let jobsiteZip = customer.zip {
            self.zip = jobsiteZip
        }
    }
}
