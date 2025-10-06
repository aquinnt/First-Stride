//
//  StatsView.swift
//  FirstStride
//
//  Created by Matthew Eskola on 10/6/25.
//


import SwiftUI

struct StatsView: View {
    var body: some View {
        VStack {
            Text("Stats")
                .font(.title)
                .padding(.bottom)
            Text("Your activity and metrics will appear here.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}
