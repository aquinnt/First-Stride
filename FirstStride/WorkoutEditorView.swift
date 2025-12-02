//
//  WorkoutEditorView.swift
//  FirstStride
//

import SwiftUI
import FirebaseAuth

struct WorkoutEditorView: View {
    // Input
    let initialDate: Date
    var onFinished: (() -> Void)? = nil
    
    // Local editable state
    @State private var date: Date
    @State private var type: String = ""
    @State private var duration: Int = 10
    @State private var distance: Double = 1.0
    @State private var timed: Bool = true
    @State private var Workouts: [Workout] = []
    @State public var WID: String = ""
    @State public var edit: Bool = false
    
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
                        Stepper("\(duration)", value: $duration, in: 1...241, step: 1)
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
                        Button("Cancel") { onFinished?(); edit = false }
                            .buttonStyle(.bordered)
                        Spacer()
                    }
                }
                
                Section {
                    VStack {
                        Spacer()

                        ForEach(
                            Workouts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                        ) { W in
                            Button {
                                WID = W.id
                                type = W.type
                                duration = W.durationMinutes
                                distance = W.distanceKm ?? 0.0
                                timed = W.timed ?? false
                                edit = true
                            } label: {

                                // --- DISPLAY WORKOUT INFO ---
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Workout title
                                        Text(W.type)
                                            .font(.headline)

                                        // TIMED WORKOUTS (duration + distance km)
                                        if W.timed == true {
                                            Text("\(W.durationMinutes) min")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            if let d = W.distanceKm {
                                                Text("\(String(format: "%.1f", d)) km")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }

                                        // NON-TIMED (sets × reps)
                                        } else {
                                            let reps = Int(W.distanceKm ?? 0.0)
                                            Text("\(W.durationMinutes) sets × \(reps) reps")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(5)
                            }
                            .buttonStyle(.plain)
                        }

                    }
                    .task { try? await load() }
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
    
    //Loads previous workouts to check for workouts on selected date - Brvnson
    private func load() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Workouts = try await store.allWorkouts(for: uid)
    }
    
    // MARK: Save logic
    private func save() async {
        status = "Saving..."
        guard let uid = Auth.auth().currentUser?.uid else {
            status = "Not signed in"
            return
        }
        
        //Saves info under same workout if editing existing workout - Brvnson
        if(edit == false){
            let w = Workout(userId: uid,
                            date: date,
                            type: type.isEmpty ? "Workout" : type,
                            durationMinutes: duration,
                            distanceKm: distance,
                            timed: timed)
            
            do {
                try await store.addWorkout(w)
                status = "Saved"
                
                // 🔔 Notify dashboard of the saved date
                NotificationCenter.default.post(name: AppNotification.workoutSaved, object: date)
                
                onFinished?()
            } catch {
                status = "Error: \(error.localizedDescription)"
            }
        }
        else{
            let w = Workout(id: WID,
                            userId: uid,
                            date: date,
                            type: type.isEmpty ? "Workout" : type,
                            durationMinutes: duration,
                            distanceKm: distance,
                            timed: timed)
            
            do {
                try await store.addWorkout(w)
                status = "Saved"
                
                // 🔔 Notify dashboard of the saved date
                NotificationCenter.default.post(name: AppNotification.workoutSaved, object: date)
                
                onFinished?()
            } catch {
                status = "Error: \(error.localizedDescription)"
            }
        }
    }
}
