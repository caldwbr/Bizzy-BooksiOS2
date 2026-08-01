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

/// Tap anywhere outside a text field to dismiss the keyboard — app-wide,
/// including sheets. The recognizer never cancels touches and recognizes
/// alongside every other gesture, so buttons and fields behave normally.
@MainActor
final class KeyboardDismisser: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismisser()
    private var installed = false

    func installIfNeeded() {
        guard !installed else { return }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        guard let window = windows.first(where: { $0.isKeyWindow }) ?? windows.first else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
        installed = true
    }

    @objc private func dismissKeyboard() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.endEditing(true) }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
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
