//
//  ProfileView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    var signOutAction: (() -> Void)? = nil

    @State private var showingSignOutConfirm = false
    @State private var isSigningOut = false
    @State private var signOutError: String?

    var body: some View {
        VStack(spacing: 12) {
            if let u = Auth.auth().currentUser {
                Text("User ID:")
                Text(u.uid).font(.footnote).textSelection(.enabled)
                if let email = u.email { Text(email) }
                if u.isAnonymous { Text("Signed in as Guest").foregroundStyle(.secondary) }

                Spacer()

                if let error = signOutError {
                    Text(error).foregroundColor(.red).multilineTextAlignment(.center).padding(.horizontal)
                }

                Button(role: .destructive) {
                    showingSignOutConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground).opacity(0.06))
                    .cornerRadius(8)
                }
                .disabled(isSigningOut)
                .padding(.horizontal)
                .confirmationDialog("Are you sure you want to sign out?", isPresented: $showingSignOutConfirm, titleVisibility: .visible) {
                    Button("Sign Out", role: .destructive) {
                        performSignOut()
                    }
                    Button("Cancel", role: .cancel) { }
                }

                if isSigningOut {
                    ProgressView("Signing out...").padding(.top)
                }
            } else {
                Text("Not signed in")
                Spacer()
            }
        }
        .padding()
    }

    private func performSignOut() {
        isSigningOut = true
        signOutError = nil

        // If a closure was provided by the parent, call it so parent handles sign-out.
        if let action = signOutAction {
            action()
            finishSignOut()
            return
        }

        // Otherwise, fall back to Firebase sign out directly.
        do {
            try Auth.auth().signOut()
            finishSignOut()
        } catch {
            signOutError = error.localizedDescription
            isSigningOut = false
        }
    }

    private func finishSignOut() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isSigningOut = false
        }
    }
}
