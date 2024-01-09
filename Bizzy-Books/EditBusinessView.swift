//
//  EditBusinessView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 11/22/23.
//

import SwiftUI
import FirebaseDatabase

struct EditBusinessView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var model: Model
    
    @State private var uBizName: String = ""
    @State private var uBizEmail: String = ""
    @State private var uBizPhone: String = ""
    @State private var uBizStreet: String = ""
    @State private var uBizCity: String = ""
    @State private var uBizState: String = ""
    @State private var uBizZip: String = ""
    @State private var uBizSSN: String = ""
    @State private var uBizEIN: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Business Information")) {
                TextField("Business Name", text: $uBizName)
                TextField("Email", text: $uBizEmail)
                TextField("Phone", text: $uBizPhone)
                TextField("Street", text: $uBizStreet)
                TextField("City", text: $uBizCity)
                TextField("State", text: $uBizState)
                TextField("Zip", text: $uBizZip)
                TextField("SSN", text: $uBizSSN)
                TextField("EIN", text: $uBizEIN)
            }
            
            Section {
                Button(action: {
                    let tryThreeBizEnt = YouBusinessEntity(name: uBizName, email: uBizEmail, phone: uBizPhone, street: uBizStreet, city: uBizCity, state: uBizState, zip: uBizZip, ein: uBizEIN, ssn: uBizSSN)
                    model.youBusinessEntity = tryThreeBizEnt
                    let youBusinessEntityDict = tryThreeBizEnt.toDictionary()
                    Database.database().reference().child("users").child(model.uid).child("youbusinessentity").setValue(youBusinessEntityDict)
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Save Business")
                })
                .disabled(uBizName.isEmpty)
            }
            
        }
        .onAppear(perform: {
            importBizData()
            print("sup")
            print(uBizEmail)
        })
        .navigationBarTitle("Edit Business")
    }
    
    @MainActor
    func importBizData() {
        if let yeYou = model.youBusinessEntity {
            uBizName = yeYou.name
            uBizEmail = yeYou.email ?? ""
            uBizPhone = yeYou.phone ?? ""
            uBizStreet = yeYou.street ?? ""
            uBizCity = yeYou.city ?? ""
            uBizState = yeYou.state ?? ""
            uBizZip = yeYou.zip ?? ""
            uBizEIN = yeYou.ein ?? ""
            uBizSSN = yeYou.ssn ?? ""
        }
    }
}

