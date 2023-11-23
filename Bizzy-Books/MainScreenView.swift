//
//  ContentView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 11/22/23.
//

import Foundation
import SwiftUI
import Firebase

struct MainScreenView: View {
    @StateObject private var session = SessionStore()
    @State private var isFilterActive = false
    @State private var isEditing = false
    @State private var isEditingSheetPresented = false
    var body: some View {
        VStack {
            HeaderHStack(isFilterActive: $isFilterActive, session: session)
            FilterByHStack(isFilterActive: $isFilterActive)
            BodyScrollView(isFilterActive: $isFilterActive)
            FooterHStack(isFilterActive: $isFilterActive, isEditing: $isEditing, isEditingSheetPresented: $isEditingSheetPresented)
        }
    }
}

struct HeaderHStack: View {
    @Binding var isFilterActive: Bool
    @ObservedObject var session: SessionStore
    var body: some View {
        HStack {
            // Left circle containing user profile picture or Bizzy icon
            CircleAvatarView(imageName: "userProfileImage")
            
            Spacer()
            
            Text("Bizzy Books")
                .font(.title)
                .bold()
            
            Spacer()
            
            Button("Logout") {
                session.signOut()
            }
            
            Button("Settings") {
                openSettings()
            }
        }
        .padding()
        .background(Color.offWhiteGray)
    }
}

struct FilterByHStack: View {
    @Binding var isFilterActive: Bool
    var body: some View {
        HStack {
            // Add your filter UI elements here
        }
        .padding()
        .background(Color.offWhiteGray)
        .opacity(isFilterActive ? 1.0 : 0.0)
    }
}

struct BodyScrollView: View {
    @Binding var isFilterActive: Bool
    var body: some View {
        ScrollView {
            // Card views go here, generated dynamically
        }
    }
}

struct FooterHStack: View {
    @Binding var isFilterActive: Bool
    @Binding var isEditing: Bool
    @Binding var isEditingSheetPresented: Bool
    var body: some View {
        HStack {
            Button("Edit") {
                editBusiness()
                isEditing.toggle()
                isEditingSheetPresented = true
            }
            .padding()
            .sheet(isPresented: $isEditingSheetPresented) {
                EditBusinessView()
            }
            
            Spacer()
            
            Button(action: {
                filterBy()
                isFilterActive.toggle()
            }) {Image(systemName: "magnifyingglass").foregroundColor(.blue)}
            
            Spacer()
            
            NavigationLink(destination: DocumentGenerationView()) {
                Image(systemName: "book")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            NavigationLink(destination: AddNewItemView()) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
        .background(Color.offWhiteGray)
    }
}


struct CircleAvatarView: View {
    let imageName: String // Name of the user's profile picture or "bizzy_icon" for the default icon

    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: 40, height: 40) // Adjust the size as needed
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.blue, lineWidth: 2)) // Add a border if desired
    }
}

func openSettings() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:]) { success in
                    if success {
                        print("Opened Settings")
                    } else {
                        print("Failed to open Settings")
                    }
                }
            }
}

func editBusiness() {
    return
}

func filterBy() {
    return
}

// Define your DocumentGenerationView
struct DocumentGenerationView: View {
    var body: some View {
        // Your document generation view content here
        Text("Document Generation View")
    }
}

// Define your AddNewItemView
struct AddNewItemView: View {
    var body: some View {
        // Your add new item view content here
        Text("Add New Item View")
    }
}

extension Color {
    static let offWhiteGray = Color(red: 0.95, green: 0.95, blue: 0.95) // Customize the RGB values as needed
}

struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView().environmentObject(SessionStore())
    }
}

