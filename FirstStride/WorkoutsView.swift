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
            NavigationView {
                NavigationLink(destination: RoutinePopup()){
                    Text("Routines")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(5)
        }
            Button("Add") {
                Task {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    let w = Workout(userId: uid, date: .now, type: wrk, durationMinutes: dur, distanceKm: dist, timed: tw, weightLbs: wgt)
                    do {
                        try await store.addWorkout(w)
                        status = "Saved!"
                        try await load()
                    } catch {
                        status = "Error: \(error.localizedDescription)"
                    }
                    
                }
                
            }
            
            Toggle("Timed Workout?", systemImage: "clock", isOn: $tw)
            
            TextField("Workout", text: $wrk)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack{
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
                VStack{
                    TextField("Weight (lbs)", value: $wgt, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Text("Weight (lbs)")
                    
                }
                
            }

            
            
            
            
            
            
            
            Text(status).font(.footnote).foregroundStyle(.secondary)
            
            List(workouts) { w in
                VStack(alignment: .leading) {
                    if Calendar.current.isDateInToday(w.date) {
                        
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
                        if let d = w.weightLbs {
                            Text("\(String(format: "%.2f", d)) Lbs").font(.subheadline)
                        }
                        Text(w.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
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
                Color.red
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 12){
                    
                    Text("DESIGN YOUR ROUTINE")
                    
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

