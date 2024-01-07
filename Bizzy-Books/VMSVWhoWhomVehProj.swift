//
//  VMSVWhoWhomVehProj.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import Foundation
import SwiftUI
import Observation

struct WhoSearchView: View {
    @Bindable var model: Model
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @State private var showingAddWhoView = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue, _ in
                            model.whoSearchEntities(query: newValue)
                        }

                    Button(action: {
                        showingAddWhoView = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .sheet(isPresented: $showingAddWhoView) {
                        AddWhoView() // Make sure this view can update the list of entities
                    }
                }

                List(model.filteredWhoEntities, id: \.id) { entity in // Assuming Entity conforms to Identifiable
                    Text(entity.name)
                        .onTapGesture {
                            model.selectedWho = entity.name
                            self.searchQuery = entity.name
                            model.selectedWhoUID = entity.id
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(model.selectedWhoUID.isEmpty)
                .padding()
            }
            .navigationBarTitle("Who")
        }
    }
}

struct WhomSearchView: View {
    @Bindable var model: Model
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @State private var showingAddWhomView = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue, _ in
                            model.whomSearchEntities(query: newValue)
                        }

                    Button(action: {
                        showingAddWhomView = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .sheet(isPresented: $showingAddWhomView) {
                        AddWhomView() // Make sure this view can update the list of entities
                    }
                }

                List(model.filteredWhomEntities, id: \.id) { entity in // Assuming Entity conforms to Identifiable
                    Text(entity.name)
                        .onTapGesture {
                            model.selectedWhom = entity.name
                            self.searchQuery = entity.name
                            model.selectedWhomUID = entity.id
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(model.selectedWhomUID.isEmpty)
                .padding()
            }
            .navigationBarTitle("Who")
        }
    }
}

struct VehicleSearchView: View {
    @Bindable var model: Model
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @State private var showingAddVehicleView = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue, _ in
                            model.searchVehicles(query: newValue)
                        }

                    Button(action: {
                        showingAddVehicleView = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .sheet(isPresented: $showingAddVehicleView) {
                        AddVehicleView() // Make sure this view can update the list of entities
                    }
                }

                List(model.filteredVehicles, id: \.id) { vehicle in // Assuming Entity conforms to Identifiable
                    Text(vehicle.name)
                        .onTapGesture {
                            model.selectedVehicle = vehicle.name
                            self.searchQuery = vehicle.name
                            model.selectedVehicleUID = vehicle.id
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(model.selectedVehicleUID.isEmpty)
                .padding()
            }
            .navigationBarTitle("Vehicle")
        }
    }
}



struct ProjectSearchView: View {
    @Bindable var model: Model
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @State private var showingAddProjectView = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue, _ in
                            model.searchProjects(query: newValue)
                        }

                    Button(action: {
                        showingAddProjectView = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .sheet(isPresented: $showingAddProjectView) {
                        AddProjectView() // Make sure this view can update the list of entities
                    }
                }

                List(model.filteredProjects, id: \.id) { project in // Assuming Entity conforms to Identifiable
                    Text(project.name)
                        .onTapGesture {
                            model.selectedProject = project.name
                            self.searchQuery = project.name
                            model.selectedProjectUID = project.id
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(model.selectedProjectUID.isEmpty)
                .padding()
            }
            .navigationBarTitle("Project")
        }
    }
}
