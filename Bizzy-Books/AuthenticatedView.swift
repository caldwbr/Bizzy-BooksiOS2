//
// AuthenticatedView.swift
// Favourites
//
// Created by Peter Friese on 08.07.2022
// Copyright © 2022 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

//extension AuthenticatedView where Unauthenticated == EmptyView {
//    init(@ViewBuilder content: @escaping () -> Content) {
//        self.unauthenticated = nil
//        self.content = content
//    }
//}

@MainActor
struct AuthenticatedView<Content, Unauthenticated>: View where Content: View, Unauthenticated: View {
    @Environment(Model.self) var model
    @State private var presentingLoginScreen = false
    @State private var presentingProfileScreen = false
    
    @ViewBuilder var unauthenticated: () -> Unauthenticated?
    @ViewBuilder var content: () -> Content
    
//    public init(unauthenticated: Unauthenticated?, @ViewBuilder content: @escaping () -> Content) {
//        self.unauthenticated = unauthenticated
//        self.content = content
//    }
    
//    public init(@ViewBuilder unauthenticated: @escaping () -> Unauthenticated, @ViewBuilder content: @escaping () -> Content) {
//        self.unauthenticated = unauthenticated()
//        self.content = content
//    }
//    
    
    var body: some View {
        Group {
            switch model.authenticationState {
            case .unauthenticated, .authenticating:
                VStack {
                    
                    unauthenticated()
                    
                    
                    Button("Tap here to log in") {
                        model.reset()
                        presentingLoginScreen.toggle()
                    }
                }
                .sheet(isPresented: $presentingLoginScreen) {
                    AuthenticationView(model: model)
                }
            case .authenticated:
                VStack {
                    content()
                    Text("You're logged in as \(model.displayName).")
                    Button("Tap here to view your profile") {
                        presentingProfileScreen.toggle()
                    }
                }
                .sheet(isPresented: $presentingProfileScreen) {
                    NavigationView {
                        UserProfileView(model: model)
                    }
                }
            }
        }
        .onAppear(perform: {
            model.registerAuthStateHandler()

//            model.flow
//                .combineLatest(model.authEmail, model.authPassword, model.authConfirmPassword)
//                .map { flow, authEmail, authPassword, authConfirmPassword in
//                    flow == flow.login
//                    ? !(authEmail.isEmpty || authPassword.isEmpty)
//                    : !(authEmail.isEmpty || authPassword.isEmpty || authConfirmPassword.isEmpty)
//                }
//                .assign(to: &model.isValid)
        })
        .onChange(of: [model.flow, model.authEmail, model.authPassword, model.authConfirmPassword] as [AnyHashable]) {
            updateAuthState()
        }
    
    }
    
    private func updateAuthState() {
        model.isValid = model.flow == .login
        ? !(model.authEmail.isEmpty || model.authPassword.isEmpty)
        : !(model.authEmail.isEmpty || model.authPassword.isEmpty || model.authConfirmPassword.isEmpty)
    }
}
