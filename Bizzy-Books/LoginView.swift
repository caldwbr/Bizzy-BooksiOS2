//
// LoginView.swift
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
import Combine
//import FirebaseAnalyticsSwift

private enum FocusableField: Hashable {
  case email
  case password
}

struct LoginView: View {
    @Bindable var model: Model
  @Environment(\.dismiss) var dismiss

  @FocusState private var focus: FocusableField?

  private func signInWithEmailPassword() {
    Task {
      if await model.signInWithEmailPassword() == true {
        dismiss()
      }
    }
  }

  var body: some View {
    VStack {
      Image("Login")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(minHeight: 300, maxHeight: 400)
      Text("Login")
        .font(.largeTitle)
        .fontWeight(.bold)
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack {
        Image(systemName: "at")
        TextField("Email", text: $model.authEmail)
          .textInputAutocapitalization(.never)
          .disableAutocorrection(true)
          .focused($focus, equals: .email)
          .submitLabel(.next)
          .onSubmit {
            self.focus = .password
          }
      }
      .padding(.vertical, 6)
      .background(Divider(), alignment: .bottom)
      .padding(.bottom, 4)

      HStack {
        Image(systemName: "lock")
        SecureField("Password", text: $model.authPassword)
          .focused($focus, equals: .password)
          .submitLabel(.go)
          .onSubmit {
            signInWithEmailPassword()
          }
      }
      .padding(.vertical, 6)
      .background(Divider(), alignment: .bottom)
      .padding(.bottom, 8)

      if !model.errorMessage.isEmpty {
        VStack {
          Text(model.errorMessage)
            .foregroundColor(Color(UIColor.systemRed))
        }
      }

      Button(action: signInWithEmailPassword) {
        if model.authenticationState != .authenticating {
          Text("Login")
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        else {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
      }
      .disabled(!model.isValid)
      .frame(maxWidth: .infinity)
      .buttonStyle(.borderedProminent)

      HStack {
        Text("Don't have an account yet?")
        Button(action: { model.switchFlow() }) {
          Text("Sign up")
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
      }
      .padding([.top, .bottom], 50)

    }
    .listStyle(.plain)
    .padding()
  }
}


