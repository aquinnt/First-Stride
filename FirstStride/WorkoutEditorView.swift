//
//  WorkoutEditorView.swift
//  FirstStride
//
//  Created by Matthew Eskola on 10/8/25.
//

import SwiftUI
import FirebaseAuth

struct WorkoutEditorView: View {
    // Input
    let initialDate: Date
    var onFinished: (() -> Void)? = nil

    // Local editable state (pre-filled with sensible defaults)
    @State private var date: Date
    @State private var type: String = ""
    @State private var duration: Int = 10
    @State private var distance: Double = 1.0
    @State private var timed: Bool = true

    // Status + service
    @State private var status: String = ""
    private let store = FirestoreService()

    // Init binds initialDate into @State
    init(date: Date, onFinished: (() -> Void)? = nil) {
        self.initialDate = date
        self.onFinished = onFinished
        _date = State(initialValue: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("When")) {
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Workout")) {
                    TextField("Type (e.g., Run, Strength)", text: $type)
                    Toggle(isOn: $timed) {
                        Label("Timed Workout", systemImage: "clock")
                    }
                    HStack {
                        Text(timed ? "Duration (min)" : "Sets")
                        Spacer()
                        Stepper("\(duration)", value: $duration, in: 1...241, step: timed ? 1 : 1)
                            .frame(width: 141)
                    }
                    HStack {
                        Text(timed ? "Distance (km)" : "Reps")
                        Spacer()
                        Stepper(String(format: "%.1f", distance), value: $distance, in: 1...1001, step: timed ? 0.5 : 1)
                            .frame(width: 141)
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Button("Save") { Task { await save() } }
                            .buttonStyle(.borderedProminent)
                        Spacer()
                    }

                    HStack {
                        Spacer()
                        Button("Cancel") { onFinished?() }
                            .buttonStyle(.bordered)
                        Spacer()
                    }
                }

                if !status.isEmpty {
                    Section {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onFinished?() }
                }
            }
        }
    }

    // MARK: Save logic
    private func save() async {
        status = "Saving..."
        guard let uid = Auth.auth().currentUser?.uid else {
            status = "Not signed in"
            return
        }

        let w = Workout(userId: uid,
                        date: date,
                        type: type.isEmpty ? "Workout" : type,
                        durationMinutes: duration,
                        distanceKm: distance,
                        timed: timed)

        do {
            try await store.addWorkout(w)
            status = "Saved"
            onFinished?()
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }
}
