//
//  AddCustomerView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/7/24.
//

import SwiftUI
import Contacts
import FirebaseDatabase

struct AddCustomerView: View {
    @Bindable var model: Model
    @State private var name = ""
    @State private var suggestedContacts = [CNContact]()
    @State private var businessName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var ein = ""
    @State private var ssn = ""
    @State private var contactsPermissionGranted = false
    
    var body: some View {
        Form {
            Section(header: Text("Add Customer Entity")) {
                TextField("Name", text: $name)
                    .onChange(of: name) { newName, _ in
                        searchContacts(for: newName) { matchingContacts in
                            suggestedContacts = matchingContacts
                        }
                    }
                ForEach(suggestedContacts, id: \.identifier) { contact in
                    Text(contact.givenName + " " + contact.familyName)
                        .onTapGesture {
                            fillInContactDetails(for: contact)
                        }
                }
                TextField("Business Name", text: $businessName)
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
                TextField("Street", text: $street)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Zip", text: $zip)
                TextField("EIN", text: $ein)
                TextField("SSN", text: $ssn)
            }

            Section {
                Button(action: {
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
                    model.selectedWho = newEntity.name
                    model.selectedWhoUID = newEntity.id
                    model.customerName = newEntity.name
                    model.customerUID = newEntity.id
                    let newEntityDict = newEntity.toDictionary() // Convert the Entity to a dictionary
                    Database.database().reference().child("users").child(model.uid).child("entities").child(newEntity.id).setValue(newEntityDict) // Save the Entity to Firebase
                }, label: {
                    Text("Save Customer")
                })
                .disabled(name.isEmpty)
                .font(.largeTitle)
                .padding()
            }
        }
        .navigationBarTitle("Add Customer")
        .onAppear{
            requestContactsPermission { granted in
                contactsPermissionGranted = granted
                if granted {
                    // Permission was granted, you can now access contacts
                } else {
                    // Handle the case where permission was not granted
                }
            }
        }
    }
    
    func requestContactsPermission(completion: @escaping (Bool) -> Void) {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func searchContacts(for query: String, completion: @escaping ([CNContact]) -> Void) {
        // Create a background queue for contact processing
        DispatchQueue.global(qos: .background).async {
            var matchingContacts: [CNContact] = []
            
            // Create a contact store object
            let store = CNContactStore()
            
            // Specify the keys you want to fetch (e.g., name)
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
            
            // Create a fetch request
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            do {
                try store.enumerateContacts(with: fetchRequest) { (contact, stop) in
                    // Check if the contact's name contains the query string
                    if contact.givenName.lowercased().contains(query.lowercased()) ||
                       contact.familyName.lowercased().contains(query.lowercased()) {
                        matchingContacts.append(contact)
                    }
                }

                // Return the matching contacts on the main thread
                DispatchQueue.main.async {
                    completion(matchingContacts)
                }
            } catch {
                // Handle any errors that may occur during contact fetching
                print("Failed to fetch contacts: \(error)")
                
                // Return an empty result on the main thread in case of an error
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    func fillInContactDetails(for contact: CNContact) {
        let store = CNContactStore()
        let keys = [CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactPostalAddressesKey] as [CNKeyDescriptor]
        let predicate = CNContact.predicateForContacts(matchingName: name)
        
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
            if let firstContact = contacts.first {
                self.name = contact.givenName + " " + contact.familyName
                self.email = firstContact.emailAddresses.first?.value as String? ?? ""
                self.phone = firstContact.phoneNumbers.first?.value.stringValue ?? ""
                
                // Fetching and setting address details
                if let postalAddress = firstContact.postalAddresses.first?.value {
                    self.street = "\(postalAddress.street)"
                    self.city = "\(postalAddress.city)"
                    self.state = "\(postalAddress.state)"
                    self.zip = "\(postalAddress.postalCode)"
                }
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }
    
}

