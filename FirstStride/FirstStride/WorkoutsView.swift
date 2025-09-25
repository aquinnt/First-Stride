//
//  WorkoutsView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI
import FirebaseAuth

struct WorkoutsView: View {
    @State private var status = ""
    @State private var workouts: [Workout] = []
    let store = FirestoreService()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Add Sample Workout") {
                    Task {
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        let w = Workout(userId: uid, date: .now, type: "Run", durationMinutes: 30, distanceKm: 5.0)
                        do {
                            try await store.addWorkout(w)
                            status = "Saved!"
                            try await load()
                        } catch {
                            status = "Error: \(error.localizedDescription)"
                        }
                    }
                }
                Button("Refresh") {
                    Task { try? await load() }
                }
            }

            Text(status).font(.footnote).foregroundStyle(.secondary)

            List(workouts) { w in
                VStack(alignment: .leading) {
                    Text("\(w.type) • \(w.durationMinutes) min")
                        .font(.headline)
                    if let d = w.distanceKm {
                        Text("\(String(format: "%.2f", d)) km").font(.subheadline)
                    }
                    Text(w.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .task { try? await load() }
    }

    private func load() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        workouts = try await store.recentWorkouts(for: uid)
    }
}

