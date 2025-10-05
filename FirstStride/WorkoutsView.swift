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
    @State private var wrk: String = ""
    @State private var dur: Int = 0
    @State private var dist: Double = 0.0
    @State private var tw: Bool = false
    let store = FirestoreService()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Add Sample Workout") {
                    Task {
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        let w = Workout(userId: uid, date: .now, type: "Run", durationMinutes: 30, distanceKm: 5.0, timed: true)
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
            Toggle("Timed Workout?", systemImage: "clock", isOn: $tw)
            
            HStack{
                TextField("Workout", text: $wrk)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                VStack{
                    TextField("Duration/Sets", value: $dur, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    if tw == true{
                        Text("Duration (min)")
                    }
                    else{
                        Text("Sets")
                    }
                }
                VStack{
                    TextField("Distance/Reps", value: $dist, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    if tw == true{
                        Text("Distance (km)")
                    }
                    else{
                        Text("Reps")
                    }
                }
                Button("Add") {
                    Task {
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        let w = Workout(userId: uid, date: .now, type: wrk, durationMinutes: dur, distanceKm: dist, timed: tw)
                        do {
                            try await store.addWorkout(w)
                            status = "Saved!"
                            try await load()
                        } catch {
                            status = "Error: \(error.localizedDescription)"
                        }
                        
                    }
                    
                }
                    
                    
                
            }
            

            Text(status).font(.footnote).foregroundStyle(.secondary)

            List(workouts) { w in
                    VStack(alignment: .leading) {
                        if w.timed == true{
                            Text("\(w.type) • \(w.durationMinutes) min")
                                .font(.headline)
                        }
                        else{
                            Text("\(w.type) • \(w.durationMinutes) Sets")
                                .font(.headline)
                        }
                        if let d = w.distanceKm {
                            if w.timed == true{
                                Text("\(String(format: "%.2f", d)) km").font(.subheadline)
                            }
                            else{
                                Text("\(String(format: "%.2f", d)) Reps").font(.subheadline)
                            }
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

