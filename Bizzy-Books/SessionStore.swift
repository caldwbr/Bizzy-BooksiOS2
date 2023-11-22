//
//  SessionStore.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 11/22/23.
//

import Foundation
import Firebase
import Combine

class SessionStore: ObservableObject {
    @Published var session: User?

    func listen() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.session = user
            } else {
                self.session = nil
            }
        }
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser != nil {
                    // User is logged in
                    // You can add any necessary logic here if needed
                } else {
                    // User is not logged in
                    // You can add any necessary logic here if needed
                }
    }

    func signIn(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password, completion: completion)
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
