//
//  SplashView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI
import UIKit

struct SplashView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var goHome = false
    @State private var showAuth = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Use UIKit color for iOS background
                Color(UIColor.systemBackground).ignoresSafeArea()

                VStack(spacing: 12) {
                    Text("First-Stride")
                        .font(.largeTitle).bold()
                    ProgressView()
                }
            }
            .navigationDestination(isPresented: $goHome) {
                AppShell().environmentObject(auth)
            }
            .onAppear {
                // give auth listener a moment to fire
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    routeBasedOnAuth()
                }
            }
            .onChange(of: auth.user) { _, _ in
                routeBasedOnAuth()
            }
            .fullScreenCover(isPresented: $showAuth) {
                AuthView().environmentObject(auth)
            }
        }
    }

    private func routeBasedOnAuth() {
        if auth.user != nil {
            showAuth = false
            goHome = true
        } else {
            goHome = false
            showAuth = true
        }
    }
}
