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
    @State public var showSheet: Bool = false
    @State public var showSheet2: Bool = false
    let store = FirestoreService()

    var body: some View {
        //Opens Menu for adding workouts - Brvnson
        Button(action: {
            showSheet.toggle()
        }, label: {
            Text("Add Workout")
                .foregroundStyle(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
        })
        .sheet(isPresented: $showSheet, content: {
            WorkoutPopup()
        })
        
        //Opens Menu for adding timed workout - Brvnson
        Button(action: {
            showSheet2.toggle()
        }, label: {
            Text("Add Timed Workout")
                .foregroundStyle(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
        })
        .sheet(isPresented: $showSheet2, content: {
            TimedWorkoutPopup()
        })
        
        //Old workout adding menu
        VStack(spacing: 12) {
                Button("Refresh") {
                    Task { try? await load() }
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
    
    //Sheet to add a set based workout
    struct WorkoutPopup: View{
        @Environment(\.presentationMode) var presentationMode
        
        @State private var status = ""
        @State private var workouts: [Workout] = []
        @State private var wrk: String = ""
        @State private var set: Int = 0
        @State private var rep: Double = 0.0
        @State private var tw: Bool = false
        let store = FirestoreService()
        
        var body: some View{
            ZStack{
                Color.red
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 12){
                    
                    Text("Workout")
                    TextField("Workout", text: $wrk)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    Text("Number of Sets")
                    TextField("Sets", value: $set, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Text("Number of Reps")
                    TextField("Reps", value: $rep, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    HStack{
                        Button("Add") {
                            Task {
                                presentationMode.wrappedValue.dismiss()
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                let w = Workout(userId: uid, date: .now, type: wrk, durationMinutes: set, distanceKm: rep, timed: false)
                                do {
                                    try await store.addWorkout(w)
                                    status = "Saved!"
                                } catch {
                                    status = "Error: \(error.localizedDescription)"
                                }
                                
                            }
                            
                        }
                        .foregroundColor(.green)
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                    Button(action: {
                            presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel")
                            .foregroundColor(.black)
                            .padding(20)
                    })
                    }
                }
            }
            
        }
    }

    //Sheet to add a time based workout
    struct TimedWorkoutPopup: View{
        @Environment(\.presentationMode) var presentationMode
        
        @State private var status = ""
        @State private var workouts: [Workout] = []
        @State private var wrk: String = ""
        @State private var dur: Int = 0
        @State private var dist: Double = 0.0
        @State private var tw: Bool = true
        let store = FirestoreService()
        
        var body: some View{
            ZStack{
                Color.red
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 12){
                    
                    Text("Workout")
                    TextField("Workout", text: $wrk)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    Text("Duration of Workout")
                    TextField("Duration", value: $dur, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Text("Distance of Workout")
                    TextField("Distance", value: $dist, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    HStack{
                        Button("Add") {
                            Task {
                                presentationMode.wrappedValue.dismiss()
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                let w = Workout(userId: uid, date: .now, type: wrk, durationMinutes: dur, distanceKm: dist, timed: true)
                                do {
                                    try await store.addWorkout(w)
                                    status = "Saved!"
                                } catch {
                                    status = "Error: \(error.localizedDescription)"
                                }
                                
                            }
                            
                        }
                        .foregroundColor(.green)
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                    Button(action: {
                            presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel")
                            .foregroundColor(.black)
                            .padding(20)
                    })
                    }
                }
            }
            
        }
    }
    
    
    private func load() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        workouts = try await store.recentWorkouts(for: uid)
    }
}

