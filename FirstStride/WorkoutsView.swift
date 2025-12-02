//
//  WorkoutsView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI
import FirebaseAuth

// Reusable card style (matches profileCard)
@ViewBuilder
func workoutCardContainer<Content: View>(
    title: String,
    icon: String,
    @ViewBuilder content: () -> Content
) -> some View {

    VStack(alignment: .leading, spacing: 12) {

        HStack {
            Image(systemName: icon)
                .foregroundColor(.red)
                .font(.title2)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()
        }

        content()
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.systemGray6))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    )
    .padding(.horizontal)
}


struct WorkoutsView: View {
    @State private var status = ""
    @State private var workouts: [Workout] = []
    @State private var wrk: String = ""
    @State private var dur: Int = 0
    @State private var dist: Double = 0.0
    @State private var wgt: Double = 0.0
    @State private var tw: Bool = false
    @State public var showSheet: Bool = false
    @State public var showSheet2: Bool = false
    @State private var routines: [Routine] = []
    let store = FirestoreService()
    
    var body: some View {

        //Workout adding menu - Brvnson
        VStack(spacing: 12) {
            //Opens Menu for adding routines - Brvnson
            // Routines Button (clean + styled)
            ScrollView {
                VStack(spacing: 24) {
                    
                    // --- Routines Button Card ---
                    workoutCardContainer(title: "Routines", icon: "list.bullet.rectangle") {
                        
                        NavigationLink(destination: RoutinePopup()) {
                            HStack {
                                Label("Open Routines", systemImage: "arrow.right.circle")
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // --- Add Workout Card ---
                    workoutCardContainer(title: "Add Workout", icon: "plus.circle.fill") {
                        
                        Toggle("Timed Workout?", isOn: $tw)
                            .padding(.bottom, 8)
                        
                        TextField("Workout Type", text: $wrk)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            VStack(alignment: .leading) {
                                TextField("Duration / Sets", value: $dur, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text(tw ? "Duration (min)" : "Sets")
                                    .font(.caption)
                            }
                            
                            VStack(alignment: .leading) {
                                TextField("Distance / Reps", value: $dist, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text(tw ? "Distance (km)" : "Reps")
                                    .font(.caption)
                            }
                            
                            VStack(alignment: .leading) {
                                TextField("Weight (lbs)", value: $wgt, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("Weight")
                                    .font(.caption)
                            }
                        }
                        
                        Button {
                            Task {
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                let w = Workout(
                                    userId: uid,
                                    date: .now,
                                    type: wrk,
                                    durationMinutes: dur,
                                    distanceKm: dist,
                                    timed: tw,
                                    weightLbs: wgt
                                )
                                do {
                                    try await store.addWorkout(w)
                                    status = "Saved!"
                                    try await load()
                                } catch {
                                    status = "Error: \(error.localizedDescription)"
                                }
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Save Workout", systemImage: "checkmark.circle.fill")
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding(.top, 8)
                        
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    // --- Today's Workouts ---
                    workoutCardContainer(title: "Today's Workouts", icon: "clock") {
                        ForEach(workouts) { w in
                            if Calendar.current.isDateInToday(w.date) {
                                WorkoutCard(workout: w)
                                Divider()
                            }
                        }
                    }
                }
                .padding(.top, 18)  // Raises everything downward
            }
            .task { try? await load() }}

        .padding()
        .task { try? await load() }
    }
    
    //Sheet to add and view routines - Brvnson
    struct RoutinePopup: View{
        @Environment(\.presentationMode) var presentationMode
        
        @State private var status = ""
        @State private var workouts: [TWorkout] = []
        @State private var wrk: String = ""
        @State private var tempwrk: [String] = []
        @State private var set: Int = 0
        @State private var tempset: [Int] = []
        @State private var rep: Double = 0.0
        @State private var temprep: [Double] = []
        @State private var tw: Bool = false
        @State private var temptw: [Bool] = []
        @State private var routines: [Routine] = []
        @State private var rtn: String = ""
        @State private var mcl: [String] = []
        @State private var wx: [TWorkout] = []
        @State private var numwx: Int = 0
        @State private var tempmusc: String = ""
        @State private var tempmusx: [String] = []
        let store = FirestoreService()
        
        var body: some View{
            ZStack{
               
                VStack(alignment: .leading, spacing: 20){
                    
                    Text("Design Your Routine")
                        .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    Text("Name of Routine (e.g. Back Day)")
                    TextField("Name", text: $rtn)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Text("Workout")
                    TextField("Workout", text: $wrk)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Toggle("Timed Workout?", systemImage: "clock", isOn: $tw)
                    
                    HStack{
                        VStack{
                            TextField("Duration/Sets", value: $set, format: .number)
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
                            TextField("Distance/Reps", value: $rep, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            if tw == true{
                                Text("Distance (km)")
                            }
                            else{
                                Text("Reps")
                            }
                        }
                        VStack{
                            TextField("Muscle Group", text: $tempmusc)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            Text("Muscle/Muscle Group Worked")
                            
                        }
                        Button("Add") {
                            Task {
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                let w = TWorkout(userId: uid, type: wrk, durationMinutes: set, distanceKm: rep, timed: tw)
                                do {
                                    try await store.addTWorkout(w)
                                    status = "Saved!"
                                    wx.append(w)
                                    tempwrk.append(wrk)
                                    tempset.append(set)
                                    temprep.append(rep)
                                    temptw.append(tw)
                                    tempmusx.append(tempmusc)
                                    wrk = ""
                                    set = 0
                                    rep = 0.0
                                    tempmusc = ""
                                    numwx += 1
                                } catch {
                                    status = "Error: \(error.localizedDescription)"
                                }
                                
                            }
                            
                        }
                    }
                    HStack{
                        
                        Button("Save"){
                            Task{
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                let r = Routine(userId: uid, name: rtn, Muscles: tempmusx, type: tempwrk, durationMinutes: tempset, distanceKm: temprep, timed: temptw, numexercises: numwx)
                                do {
                                    try await store.addRoutine(r)
                                    status = "Saved!"
                                    routines.append(r)
                                    wx.removeAll()
                                    tempmusx.removeAll()
                                    tempwrk.removeAll()
                                    tempset.removeAll()
                                    temprep.removeAll()
                                    temptw.removeAll()
                                    rtn = ""
                                    numwx = 0
                                }
                            }
                        }
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("Cancel")
                                .foregroundColor(.black)
                                .padding(20)
                        })
                    }
                    List(routines){r in
                        Text(r.name).font(.headline)
                        ForEach(r.type, id: \.self){t in
                            Text("\(t) /").font(.caption)
                        }
                        
                    }
                    
                }
                .padding()
                .task {try? await loadr()}
            }
            
        }
        private func loadr() async throws {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            routines = try await store.recentRoutines(for: uid)
        }
        
    }
    
    private func load() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        workouts = try await store.recentWorkouts(for: uid)
    }
    
    
}

struct WorkoutCard: View {
    let workout: Workout

    var icon: String {
        if workout.type.lowercased().contains("run") { return "figure.run" }
        if workout.type.lowercased().contains("lift") { return "dumbbell" }
        if workout.timed == true { return "clock" }
        return "flame"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(workout.type)
                    .font(.headline)

                if workout.timed == true {
                    Text("⏱ \(workout.durationMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let d = workout.distanceKm {
                        Text("📍 \(String(format: "%.2f", d)) km")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Sets: \(workout.durationMinutes)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let r = workout.distanceKm {
                        Text("Reps: \(String(format: "%.0f", r))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if let w = workout.weightLbs {
                    Text("🏋️‍♂️ \(String(format: "%.1f", w)) lbs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.9))
        )
    }
}
