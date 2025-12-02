//
//  StatsView.swift
//  FirstStride
//
//  Created by Matthew Eskola on 10/6/25.
//  Updated by Rene Ramirez on 10/14/25
//
import SwiftUI
import FirebaseAuth
import Charts

@ViewBuilder
func statCard<Content: View>(
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


struct WeightData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct StatsView: View {
    // MARK: - State
    @State private var workouts: [Workout] = []
    @State private var userProfile: UserProfile?
    @State private var totalWorkoutTime = 0
    @State private var todayWorkout: String = "—"
    @State private var maxWeight: Double = 0
    @State private var totalRestDays = 0
    @State private var statusMessage: String = ""
    @State private var weightHistory: [WeightData] = []
    //Brvnson - Variables for sets and reps
    @State private var reps: Double = 0
    @State private var sets: Int = 0
    @State private var currentStreak: Int = 0
    @State private var longestStreak: Int = 0   // optional


    private let store = FirestoreService()

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                statCard(title: "Streak", icon: "flame.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(" Current Streak: \(currentStreak) days")

                        // Optional longest streak:
                        Text(" Longest Streak: \(longestStreak) days")
                    }
                    .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: Weight Progress Chart
                    statCard(title: "Weight Progress", icon: "chart.line.uptrend.xyaxis") {
                        if !weightHistory.isEmpty {
                            Chart(weightHistory) { entry in
                                LineMark(
                                    x: .value("Date", entry.date, unit: .day),
                                    y: .value("Weight (kg)", entry.weight)
                                )
                                .interpolationMethod(.monotone)
                                .symbol(Circle())
                            }
                            .frame(height: 220)
                        } else {
                            VStack(alignment: .leading) {
                                Text("No weight data available yet.")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200, alignment: .center)
                            }
                        }
                    }
                    
                    // MARK: Daily Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Stats")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total Workout Time: \(totalWorkoutTime) min")
                            Text("Today Workout: \(todayWorkout)")
                            Text("Max Weight Hit: \(String(format: "%.1f", maxWeight)) kg")
                            Text("Total Rest Days: \(totalRestDays)")
                            //rep, sets, and weights lifted stats - Brvnson
                            Text("Total Sets Completed: \(sets)")
                            Text("Total Reps Completed: \(String(format: "%.1f", reps))")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .shadow(radius: 1)
                        )
                    }
            
                }
                .padding(.top, 18)
                .task { await loadData() }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Data Loading
    private func loadData() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            statusMessage = "Not signed in."
            return
        }

        do {
            // Fetch Firestore data
            workouts = try await store.recentWorkouts(for: uid)
            userProfile = try? await store.getUserProfile(uid: uid)
            

            if let w = userProfile?.weightKg {
                weightHistory = [
                    WeightData(date: Calendar.current.date(byAdding: .day, value: -21, to: .now)!, weight: w - 3),
                    WeightData(date: Calendar.current.date(byAdding: .day, value: -14, to: .now)!, weight: w - 1.5),
                    WeightData(date: Calendar.current.date(byAdding: .day, value: -7, to: .now)!, weight: w - 0.5),
                    WeightData(date: .now, weight: w)
                ]
            }
            
            calculateStats()
            setAndRepStats()
            calculateStreak()

            statusMessage = "Stats updated."
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Stat Calculations
    private func calculateStats() {
        let today = Calendar.current.startOfDay(for: Date())
        let todaysWorkouts = workouts.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }

        totalWorkoutTime = todaysWorkouts.reduce(0) { $0 + $1.durationMinutes }
        todayWorkout = todaysWorkouts.last?.type ?? "—"
        maxWeight = userProfile?.weightKg ?? 0
        
        // Rest days this week
        let uniqueDays = Set(workouts.map {
            Calendar.current.startOfDay(for: $0.date)
        })
        totalRestDays = 7 - min(7, uniqueDays.count)
    }
    
    //Brvnson - Set and Rep stats
    private func setAndRepStats() {
    

        let today = Calendar.current.startOfDay(for: Date())
        let todaysWorkouts = workouts.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        
        sets = todaysWorkouts.reduce(0) {if $1.timed == false {return $0 + $1.durationMinutes} else {return $0}}
        reps = todaysWorkouts.reduce(0) {if $1.timed == false {return $0 + (($1.distanceKm ?? 0.0) * Double($1.durationMinutes))} else {return $0}}
    }
    // MARK: - Daily Streak Calculation
    private func calculateStreak() {
        // Make sure workouts are sorted newest → oldest
        let sortedDates = workouts
            .map { Calendar.current.startOfDay(for: $0.date) }
            .sorted(by: >)

        guard !sortedDates.isEmpty else {
            currentStreak = 0
            return
        }

        var streak = 0
        var dayPointer = Calendar.current.startOfDay(for: Date()) // start at today

        for day in sortedDates {
            if Calendar.current.isDate(day, inSameDayAs: dayPointer) {
                // Match → streak continues
                streak += 1

                // Move pointer to previous day
                dayPointer = Calendar.current.date(byAdding: .day, value: -1, to: dayPointer)!

            } else if day < dayPointer {
                // Missed a day → streak ends
                break
            }
        }

        currentStreak = streak

        // optional streak tracking
        longestStreak = max(longestStreak, streak)
    }
    

}



