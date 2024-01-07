//
//  AddVehicleView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import SwiftUI

struct AddVehicleView: View {
    @State private var vehicle: Vehicle? = nil
    @State private var vehicleName = ""
    @State private var vehicleUID: String? = nil
    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var color = ""
    @State private var picd = ""
    @State private var vin = ""
    @State private var licPlateNo = ""

    var body: some View {
        Form {
            Section(header: Text("Add Vehicle: Required Fields")) {
                TextField("Year", text: $year)
                TextField("Make", text: $make)
                TextField("Model", text: $model)
            }
            
            Section(header: Text("Optional Fields")) {
                TextField("Color", text: $color)
                TextField("Placed in commission date", text: $picd)
                TextField("Vehicle identification number (VIN)", text: $vin)
                TextField("License plate number", text: $licPlateNo)
            }
            
            Section {
                Button("Save", action: saveVehicle) //parentheses?
                    .disabled(year.isEmpty || make.isEmpty || model.isEmpty)
            }
            
            
        }
    }

    func saveVehicle() {
        // Implement the Firebase update or create logic here
        //Lotsa GUARD lests... or is the disabled save logic enuf?
        //Create project UUID() to make Project and then upload to Firebase]
        //timestamp creation!
        //Remember last four need to be set to nil if string == "" prior to sending to database
    }
}
