//  AddWhoView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/1/24.
//

import SwiftUI
import Contacts

struct AddWhoView: View {
    @State private var name = ""
    @State private var suggestedContacts = [CNContact]()
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var contactsPermissionGranted = false

    var body: some View {
        Form {
            Section(header: Text("Add Entity")) {
                TextField("Name", text: $name)
                    .onChange(of: name) { newName, _ in
                        suggestedContacts = searchContacts(for: newName)
                    }
                ForEach(suggestedContacts, id: \.identifier) { contact in
                    Text(contact.givenName + " " + contact.familyName)
                        .onTapGesture {
                            fillInContactDetails(for: contact)
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
                Button("Save", action: saveWho) //parentheses?
                    .disabled(name.isEmpty)
            }
        }
        .navigationBarTitle("Add Entity")
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
    
    func searchContacts(for query: String) -> [CNContact] {
        var matchingContacts = [CNContact]()

        // Create a contact store object
        let store = CNContactStore()
        
        // Specify the keys you want to fetch (e.g., name)
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]

        // Create a fetch request
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)

        // Try to fetch contacts
        do {
            try store.enumerateContacts(with: fetchRequest) { (contact, stop) in
                // Check if the contact's name contains the query string
                if contact.givenName.lowercased().contains(query.lowercased()) ||
                    contact.familyName.lowercased().contains(query.lowercased()) {
                    matchingContacts.append(contact)
                }
            }
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
        
        return matchingContacts
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

    func saveWho() {
        // Implement the Firebase update or create logic here
    }
}
