//
//  AddProjectView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import SwiftUI

struct AddProjectView: View {
    @State private var projectName = ""
    @State private var customer: Entity
    @State private var customerName = ""
    @State private var customerUID: String? = nil
    @State private var suggestedCustomers: [Entity] = [Entity(id: "yo", name: "S T C")]
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""

    var body: some View {
        Form {
            Section(header: Text("Add Project")) {
                TextField("Name", text: $customerName)
                    .onChange(of: customerName) { newName, _ in
                        suggestedCustomers = searchCustomers(for: newName)
                    }
                ForEach(suggestedCustomers, id: \.id) { customer in
                    Text(customer.name)
                        .onTapGesture {
                            fillInCustomerDetails(for: customer)
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
                Button("Save", action: saveProject) //parentheses?
                    .disabled(projectName.isEmpty || customerUID == nil)
            }
        }
    }
    
    func searchCustomers(for query: String) -> [Entity] {
        var matchingCustomers: [Entity] = []
        
        if customer.name.contains(query.lowercased()) {
            matchingCustomers.append(customer)
        }
        return matchingCustomers
    }
    
    func fillInCustomerDetails(for customer: Entity) {
        self.customerName = customer.name
        self.customerUID = customer.id
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

    func saveProject() {
        // Implement the Firebase update or create logic here
        //Lotsa GUARD lests... or is the disabled save logic enuf?
        //Create project UUID() to make Project and then upload to Firebase
        //Create timestamp!
    }
}
