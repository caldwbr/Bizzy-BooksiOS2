//  AddWhomView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/1/24.
//

import SwiftUI

struct AddWhomView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var model: Model
    @State private var contactsPermissionGranted = false
    @State private var searchName = ""
    @State private var fieldIsSearchEnabled = true
    
    var body: some View {
        Form {
            Section() {
                Text("Add Whom Entity")
                    .font(.largeTitle)
            }
            Button(action: {
                searchName = ""
                model.clearFields()
            }, label: {
                Text("Clear")
            })
            Section() {
                HStack {
                    Button(action: {
                         fieldIsSearchEnabled.toggle()
                    }, label: {
                        Image(systemName: fieldIsSearchEnabled ? "phone.circle.fill" : "phone.circle")
                    })
                    .padding()
                    .accentColor(Color.BizzyColor.whatGreen)
                    
                    TextField("Name", text: $searchName)
                        .onChange(of: searchName) { oldName, newName in
                            model.fieldName = newName
                            
                            if (!newName.isEmpty) {
                                model.searchContacts(name: newName) { matchingContacts in
                                    model.suggestedContacts = matchingContacts ?? []
                                }
                            }
                            else {
                                model.clearFields()
                            }
                        }
                }
            }

            
            /* Search list when type in searchField. */
            if fieldIsSearchEnabled && !model.suggestedContacts.isEmpty {
                Section() {
                    List(model.suggestedContacts, id: \.identifier) { contact in
                        Text(contact.givenName + " " + contact.familyName)
                            .onTapGesture {
                                model.fillInContactDetails(for: contact)
                                // fieldIsSearchEnabled = false
                                
                                searchName = contact.givenName + " " + contact.familyName
                                
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
                    model.saveWhomEntity()
                    model.showWhomSearchView = false
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Save Whom")
                })
                .disabled(model.fieldName.isEmpty)
                .font(.largeTitle)
                .padding()
            }
        }
        .navigationBarTitle("Add Whom Entity")
        .onAppear{
            model.clearFields()
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
