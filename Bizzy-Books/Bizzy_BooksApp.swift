//
//  Bizzy_BooksApp.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 11/22/23.
//

import SwiftUI
import FirebaseCore
import Firebase
import FirebaseAuth
import FirebaseDatabaseUI
import Combine
import FirebaseAuthUI
import FirebaseEmailAuthUI

//NSObject, ..Responder..
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UserDefaults.standard.set(false, forKey: "AppleKeyboards_HasUsedEmojiKeyboard")
        FirebaseApp.configure()
        
        return true
    }
    
}

@main
struct Bizzy_BooksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var model = Model()
    var body: some Scene {
        WindowGroup {
            AuthenticatedView() {
                Image(systemName: "number.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color(.systemPink))
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .clipped()
                    .padding(4)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                Text("Welcome to Bizzy Books!")
                    .font(.title)
                Text("Please log in.")
            } content: {
                MainScreenView()
                Spacer()
            }
            .environment(model)
        }
    }
}
