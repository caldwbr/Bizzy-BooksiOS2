//
//  AddVehicleView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import SwiftUI
import FirebaseDatabase

struct AddVehicleView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var model: Model
    @State private var vehicle: Vehicle? = nil
    @State private var vehicleName = ""
    @State private var vehicleUID: String? = nil
    @State private var year = ""
    @State private var make = ""
    @State private var vehicleModel = ""
    @State private var color = ""
    @State private var picd = ""
    @State private var vin = ""
    @State private var licPlateNo = ""

    var body: some View {
        Form {
            Section(header: Text("Add Vehicle: Required Fields")) {
                TextField("Year", text: $year)
                TextField("Make", text: $make)
                TextField("Model", text: $vehicleModel)
            }
            
            Section(header: Text("Optional Fields")) {
                TextField("Color", text: $color)
                TextField("Placed in commission date", text: $picd)
                TextField("Vehicle identification number (VIN)", text: $vin)
                TextField("License plate number", text: $licPlateNo)
            }
            
            Section {
                Button(action: {
                    let newVehicle = Vehicle(
                        year: year,
                        make: make,
                        model: vehicleModel,
                        color: color,
                        picd: picd,
                        vin: vin,
                        licPlateNo: licPlateNo
                    )
                    model.selectedVehicle = newVehicle.name
                    model.selectedVehicleUID = newVehicle.id
                    let newVehicleDict = newVehicle.toDictionary() // Convert the Vehicle to a dictionary
                    Database.database().reference().child("users").child(model.uid).child("vehicles").child(newVehicle.id).setValue(newVehicleDict) // Save the Vehicle to Firebase
                    model.showVehicleSearchView = false
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Save Vehicle")
                })
                .disabled(year.isEmpty || make.isEmpty || vehicleModel.isEmpty)
            }
            
            
        }
    }
}
