//  AddWhoView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/1/24.
//

import SwiftUI

struct AddWhoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var model: Model
    @State private var contactsPermissionGranted = false

    var body: some View {
        Form {
            Section() {
                Text("Add Who Entity")
                    .font(.largeTitle)
            }
            Section() {
                HStack {
                    Image(systemName: "magnifyingglass") // Magnifying glass icon
                        .foregroundColor(.gray)
                    
                    Toggle(isOn: $model.fieldIsSearchEnabled) {
                    }
                    
                    TextField("Name", text: $model.fieldName)
                        .onChange(of: model.fieldName) { newName, _ in
                            model.searchContacts(name: newName) { matchingContacts in
                                model.suggestedContacts = matchingContacts ?? []
                            }
                        }
                    Button(action: {
                        model.clearFields()
                    }, label: {
                        Text("Clear")
                    })
                }
            }
            if model.fieldIsSearchEnabled && !model.suggestedContacts.isEmpty {
                Section() {
                    List(model.suggestedContacts, id: \.identifier) { contact in
                        Text(contact.givenName + " " + contact.familyName)
                            .onTapGesture {
                                model.fillInContactDetails(for: contact)
                                model.fieldIsSearchEnabled = false
                            }
                    }
                }
            }

            Section() {
                TextField("Business Name", text: $model.fieldBusinessName)
                TextField("Email", text: $model.fieldEmail)
                TextField("Phone", text: $model.fieldPhone)
                TextField("Street", text: $model.fieldStreet)
                TextField("City", text: $model.fieldCity)
                TextField("State", text: $model.fieldState)
                TextField("Zip", text: $model.fieldZip)
                TextField("EIN", text: $model.fieldEIN)
                TextField("SSN", text: $model.fieldSSN)
            }

            Section {
                Button(action: {
                    model.saveWhoEntity()
                    model.showWhoSearchView = false
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Save Who")
                })
                .disabled(model.fieldName.isEmpty)
                .font(.largeTitle)
                .padding()
            }
        }
        .navigationBarTitle("Add Entity")
        .onAppear{
            model.requestContactsPermission { granted in
                contactsPermissionGranted = granted
                if granted {
                    // Permission was granted, you can now access contacts
                } else {
                    // Handle the case where permission was not granted
                }
            }
        }
    }
}
