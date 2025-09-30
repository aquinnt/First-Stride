//
//  ProfileView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 12) {
            if let u = Auth.auth().currentUser {
                Text("User ID:")
                Text(u.uid).font(.footnote).textSelection(.enabled)
                if let email = u.email { Text(email) }
                if u.isAnonymous { Text("Signed in as Guest").foregroundStyle(.secondary) }
            } else {
                Text("Not signed in")
            }
            Spacer()
        }
        .padding()
    }
}

