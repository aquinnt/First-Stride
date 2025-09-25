//
//  AuthView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Welcome to First-Stride")
                    .font(.title2).bold()

                TextField("Email", text: $auth.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $auth.password)
                    .textFieldStyle(.roundedBorder)

                Button("Sign In") {
                    Task {
                        await auth.signIn()
                        if auth.user != nil { dismiss() }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Create Account") {
                    Task {
                        await auth.signUp()
                        if auth.user != nil { dismiss() }
                    }
                }

                Button("Continue as Guest") {
                    Task {
                        await auth.signInAnonymously()
                        if auth.user != nil { dismiss() }
                    }
                }
                .padding(.top, 4)

                if let errorMsg {
                    Text(errorMsg).foregroundColor(.red).font(.footnote)
                }

                Spacer()
            }
            .padding()
        }
    }
}

