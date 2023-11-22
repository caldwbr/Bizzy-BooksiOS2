//
//  Bizzy_BooksApp.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 11/22/23.
//

import SwiftUI
import FirebaseCore
import Firebase
import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct Bizzy_BooksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session = SessionStore()
    var body: some Scene {
        WindowGroup {
            MainScreenView()
                .environmentObject(session)
                .onAppear {
                    session.listen()
                }
        }
    }
}
