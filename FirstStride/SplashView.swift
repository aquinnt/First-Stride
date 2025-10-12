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
                //use this to change brightness or red
                Color(red: 1.0, green:0.3, blue: 0.3)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // added redefined logo to this screen alongside a formatted name
                    Image("whitelogo")
                        .resizable()
                        .scaledToFit()
                        
                        .padding()
                    //formatted name 
                    Text("First-Stride")
                       // .kerning(5)//playing with different fonts
                        .font(.custom("Copperplate", size: 40)).bold()
                        .foregroundColor(.white)
                  
                        .padding()
                    ProgressView()
                };Spacer()
            }
            .fullScreenCover(isPresented: $goHome) {
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

#Preview {
    SplashView()
}
