//
//  ContentView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        SplashView()
            .environmentObject(auth)
    }
}

#Preview {
    ContentView()
}
