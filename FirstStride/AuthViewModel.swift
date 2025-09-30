//
//  Authentication.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var email: String = ""
    @Published var password: String = ""
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    
    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func signUp() async {
        do {
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            print("Sign up error:", error.localizedDescription)
        }
    }

    func signIn() async {
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            print("Sign in error:", error.localizedDescription)
        }
    }

    func signInAnonymously() async {
        do {
            _ = try await Auth.auth().signInAnonymously()
        } catch {
            print("Anon sign-in error:", error.localizedDescription)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        user = nil
    }
}
