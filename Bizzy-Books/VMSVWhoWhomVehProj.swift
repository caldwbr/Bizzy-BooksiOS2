//
//  VMSVWhoWhomVehProj.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import Foundation
import SwiftUI

struct WhoSearchView: View {
    @Binding var selectedWho: String
    @Binding var selectedWhoUID: String?
    @Environment(\.presentationMode) var presentationMode
    var onSelection: (String, String) -> Void
    @State private var searchQuery = ""
    @State private var showingAddWhoView = false
    @ObservedObject var whoViewModel: WhoViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue, _ in
                            whoViewModel.searchEntities(query: newValue)
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

                List(whoViewModel.filteredWhoEntities, id: \.id) { entity in // Assuming Entity conforms to Identifiable
                    Text(entity.name)
                        .onTapGesture {
                            self.selectedWho = entity.name
                            self.searchQuery = entity.name
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    presentationMode.wrappedValue.dismiss()
                    onSelection(selectedWho, selectedWhoUID!)
                }
                .disabled(selectedWho == nil)
                .padding()
            }
            .navigationBarTitle("Who")
        }
    }
}

class WhoViewModel: ObservableObject {
    @Published var whoEntities: [Entity] = []
    @Published var filteredWhoEntities: [Entity] = []
    
    init() {
        loadWhoEntities()
    }

    private func loadWhoEntities() {
        // Load your entities here
        // For example:
        whoEntities = [
            Entity(name: "Entity 1"),
            Entity(name: "Entity 2"),
            Entity(name: "Entity 3")
        ]
        filteredWhoEntities = whoEntities
    }
    
    func searchEntities(query: String) {
        if query.isEmpty {
            filteredWhoEntities = whoEntities
        } else {
            filteredWhoEntities = whoEntities.filter { entity in
                entity.name.lowercased().contains(query.lowercased())
            }
        }
    }
}

class WhomViewModel: ObservableObject {
    @Published var whomEntities: [Entity] = []
    @Published var filteredWhomEntities: [Entity] = []
    
    init() {
        loadWhomEntities()
    }

    private func loadWhomEntities() {
        // Load your entities here
        // For example:
        whomEntities = [
            Entity(name: "Entity 1"),
            Entity(name: "Entity 2"),
            Entity(name: "Entity 3")
        ]
        filteredWhomEntities = whomEntities
    }
    
    func searchEntities(query: String) {
        if query.isEmpty {
            filteredWhomEntities = whomEntities
        } else {
            filteredWhomEntities = whomEntities.filter { entity in
                entity.name.lowercased().contains(query.lowercased())
            }
        }
    }
}

struct WhomSearchView: View {
    @Binding var selectedWhom: String
    @Binding var selectedWhomUID: String?
    @Environment(\.presentationMode) var presentationMode
    var onSelection: (String, String) -> Void
    @State private var searchQuery = ""
    @State private var showingAddWhomView = false
    @ObservedObject var whomViewModel: WhomViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue, _ in
                            whomViewModel.searchEntities(query: newValue)
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

                List(whomViewModel.filteredWhomEntities, id: \.id) { entity in // Assuming Entity conforms to Identifiable
                    Text(entity.name)
                        .onTapGesture {
                            self.selectedWhom = entity.name
                            self.searchQuery = entity.name
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    presentationMode.wrappedValue.dismiss()
                    onSelection(selectedWhom, selectedWhomUID!)
                }
                .disabled(selectedWhomUID == nil)
                .padding()
            }
            .navigationBarTitle("Who")
        }
    }
}

class VehicleViewModel: ObservableObject {
    @Published var vehicles: [Entity] = []
    @Published var filteredVehicles: [Entity] = []
    
    init() {
        loadVehicles()
    }

    private func loadVehicles() {
        // Load your entities here
        // For example:
        vehicles = [
            Entity(name: "Entity 1"),
            Entity(name: "Entity 2"),
            Entity(name: "Entity 3")
        ]
        filteredVehicles = vehicles
    }
    
    func searchVehicles(query: String) {
        if query.isEmpty {
            filteredVehicles = vehicles
        } else {
            filteredVehicles = vehicles.filter { vehicle in
                vehicle.name.lowercased().contains(query.lowercased())
            }
        }
    }
}

struct VehicleSearchView: View {
    @Binding var selectedVehicle: String
    @Binding var selectedVehicleUID: String?
    @Environment(\.presentationMode) var presentationMode
    var onSelection: (String, String) -> Void
    @State private var searchQuery = ""
    @State private var showingAddVehicleView = false
    @ObservedObject var vehicleViewModel: VehicleViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue, _ in
                            vehicleViewModel.searchVehicles(query: newValue)
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

                List(vehicleViewModel.filteredVehicles, id: \.id) { vehicle in // Assuming Entity conforms to Identifiable
                    Text(vehicle.name)
                        .onTapGesture {
                            self.selectedVehicle = vehicle.name
                            self.searchQuery = vehicle.name
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    presentationMode.wrappedValue.dismiss()
                    onSelection(selectedVehicle, selectedVehicleUID!)
                }
                .disabled(selectedVehicleUID == nil)
                .padding()
            }
            .navigationBarTitle("Vehicle")
        }
    }
}

class ProjectViewModel: ObservableObject {
    @Published var projects: [Entity] = []
    @Published var filteredProjects: [Entity] = []
    
    init() {
        loadProjects()
    }

    private func loadProjects() {
        // Load your entities here
        // For example:
        projects = [
            Entity(name: "Entity 1"),
            Entity(name: "Entity 2"),
            Entity(name: "Entity 3")
        ]
        filteredProjects = projects
    }
    
    func searchProjects(query: String) {
        if query.isEmpty {
            filteredProjects = projects
        } else {
            filteredProjects = projects.filter { project in
                project.name.lowercased().contains(query.lowercased())
            }
        }
    }
}

struct ProjectSearchView: View {
    @Binding var selectedProject: String
    @Binding var selectedProjectUID: String?
    @Environment(\.presentationMode) var presentationMode
    var onSelection: (String, String) -> Void
    @State private var searchQuery = ""
    @State private var showingAddProjectView = false
    @ObservedObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue, _ in
                            projectViewModel.searchProjects(query: newValue)
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

                List(projectViewModel.filteredProjects, id: \.id) { project in // Assuming Entity conforms to Identifiable
                    Text(project.name)
                        .onTapGesture {
                            self.selectedProject = project.name
                            self.searchQuery = project.name
                        }
                }
                .listStyle(PlainListStyle())
                
                Button("Select") {
                    presentationMode.wrappedValue.dismiss()
                    onSelection(selectedProject, selectedProjectUID!)
                }
                .disabled(selectedProjectUID == nil)
                .padding()
            }
            .navigationBarTitle("Project")
        }
    }
}
