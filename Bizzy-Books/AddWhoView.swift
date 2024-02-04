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
    @State private var searchName = ""
    @State private var fieldIsSearchEnabled = true
    
    var body: some View {
        Form {
            Section() {
                Text("Add Who Entity")
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
            model.clearFields()
//            model.requestContactsPermission { granted in
//                contactsPermissionGranted = granted
//                if granted {
//                    // Permission was granted, you can now access contacts
//                } else {
//                    // Handle the case where permission was not granted
//                }
//            }
        }
    }
}

/*
struct MagnifyingGlassStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button(action: {
                configuration.isOn.toggle()
            }, label: {
                Image(systemName: configuration.isOn ? "phone.circle" : "phone.circle.fill")
            })
            .padding()
            .accentColor(Color.BizzyColor.whatGreen)
            configuration.label
        }
    }
}

 This text field is for entering a new entity name. When toggle is on, it searches user's phone contacts to prepopulate all the fields. When toggle is off, it allows user to type all the fields and the name field without any suggestions popping up.
 
can you explain more here?
 
This screen is for adding a new entity. A lot of times, it is useful to search from my existing contacts on my phone. This functionality is working fine! BUT, sometimes, I want to add someone that isn't in my phone contacts, and I don't want that thing trying to connect to somebody on my phone contacts. So I want to toggle the functionality. And - even the name field is important for making a new contact from scratch without phone contact suggestions.
 The toggle button is turning on/off SUGGESTIONS.
 
 If I add new entity "Test",there is no carlo in your contact, ?
 then ?
 
 Sorry, After type 'Carlo' now, then? what do you want with togle on/off?
 Toggle is currently on: showing suggestions
 Toggle off: I want the suggestions to disappear
 So you should click togle on/off manually, right?
 I'm not sure. At least manually, but maybe programmatically too for when you click on a suggested name. Because if I click a suggestion, I want all the suggestions and the match to disappear (as they currently do), and automatically populate fields properly from that selection.
 
 Now I want to add 'Davi'. right?
There are no Davi in your contact list, lright?
 To add 'Davi' you should click toggle off, then suggestion list should be disapeeared. right?
 We should make toggle to clickable 'button
 
 */
