//
//  VMSVWhoWhomVehProj.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import Foundation
import SwiftUI
import Observation

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
                        .onChange(of: searchQuery) { oldValue, newValue in
                            model.whomSearchEntities(query: newValue)
                        }

                    Button(action: {
                        showingAddWhomView = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .sheet(isPresented: $showingAddWhomView) {
                        AddWhomView(model: model) // Make sure this view can update the list of entities
                    }
                }

                List(model.filteredWhomEntities, id: \.id) { entity in // Assuming Entity conforms to Identifiable
                    Text(entity.name)
                        .onTapGesture {
                            model.selectedWhom = entity.name
                            self.searchQuery = entity.name
                            if entity.key == model.uid {
                                model.selectedWhomUID = entity.key
                            } else {
                                model.selectedWhomUID = entity.id
                            }
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    model.showWhomSearchView = false
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(model.selectedWhomUID.isEmpty)
                .padding()
            }
            .navigationBarTitle("Whom")
        }
        .padding(.horizontal)
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
                        .onChange(of: searchQuery) { oldValue, newValue in
                            model.searchVehicles(query: newValue)
                        }

                    Button(action: {
                        showingAddVehicleView = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .sheet(isPresented: $showingAddVehicleView) {
                        AddVehicleView(model: model) // Make sure this view can update the list of entities
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
                    model.showVehicleSearchView = false
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(model.selectedVehicleUID.isEmpty)
                .padding()
            }
            .navigationBarTitle("Vehicle")
        }
        .padding(.horizontal)
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
                        .onChange(of: searchQuery) { oldValue, newValue in
                            model.searchProjects(query: newValue)
                        }

                    Button(action: {
                        showingAddProjectView = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .sheet(isPresented: $showingAddProjectView) {
                        AddProjectView(model: model) // Make sure this view can update the list of entities
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
                    model.showProjectSearchView = false
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(model.selectedProjectUID.isEmpty)
                .padding()
            }
            .navigationBarTitle("Project")
        }
        .padding(.horizontal)
    }
}
