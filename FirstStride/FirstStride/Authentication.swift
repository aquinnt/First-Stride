//
//  Authentication.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import Foundation
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var email = ""
    @Published var password = ""

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        // Save the handle
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    deinit {
        // Remove listener when view model is destroyed
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signUp() async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("Signed up as \(result.user.uid)")
        } catch {
            print("Error signing up: \(error.localizedDescription)")
        }
    }

    func signIn() async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("Signed in as \(result.user.uid)")
        } catch {
            print("Error signing in: \(error.localizedDescription)")
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        user = nil
    }
}

