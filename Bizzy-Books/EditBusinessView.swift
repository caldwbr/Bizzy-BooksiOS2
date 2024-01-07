//
//  EditBusinessView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 11/22/23.
//

import SwiftUI

struct EditBusinessView: View {
    @State private var businessName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""

    var body: some View {
        Form {
            Section(header: Text("Business Information")) {
                TextField("Business Name", text: $businessName)
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
                TextField("Street", text: $street)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Zip", text: $zip)
            }
            
            Section {
                Button("Save") {
                    // Implement the code to update or create the entity on Firebase
                    saveBusinessInformation()
                }
            }
        }
        .navigationBarTitle("Edit Business")
    }

    func saveBusinessInformation() {
        // Implement the Firebase update or create logic here
        // You'll need to use Firebase APIs to interact with your database
        // For example, you can use Firestore to store and retrieve data
        // You should also handle error cases and provide user feedback on the result
    }
}

