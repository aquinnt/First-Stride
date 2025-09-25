//
//  Dashboard.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Welcome to First-Stride 🏃‍♀️")
                .font(.headline)
            Text("This is your dashboard.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

