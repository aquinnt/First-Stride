//
//  ResourcesView.swift
//  FirstStride
//
//  Created by Matthew Eskola on 11/30/25.
//


import SwiftUI

struct BasicWorkout: Identifiable {
    let id = UUID()
    let name: String
    let instructions: String
    let bodyPart: String
}

struct ResourcesView: View {
    private let workouts: [BasicWorkout] = [
        BasicWorkout(
            name: "Push-Ups",
            instructions: "Start in a plank position with hands under shoulders. Lower your chest to the floor, keeping elbows at about 45°. Push back up to starting position.",
            bodyPart: "Chest, Shoulders, Triceps"
        ),
        BasicWorkout(
            name: "Squats",
            instructions: "Stand with feet shoulder-width apart. Lower hips back and down as if sitting in a chair, keeping knees behind toes. Return to standing.",
            bodyPart: "Quads, Glutes, Hamstrings"
        ),
        BasicWorkout(
            name: "Plank",
            instructions: "Hold a push-up position with forearms on the ground. Keep your body straight from head to heels, engaging your core.",
            bodyPart: "Core, Abs, Lower Back"
        ),
        BasicWorkout(
            name: "Bicep Curls",
            instructions: "Hold dumbbells at your sides with palms facing forward. Curl weights up while keeping elbows close to your torso. Lower slowly.",
            bodyPart: "Biceps"
        ),
        BasicWorkout(
            name: "Lunges",
            instructions: "Step forward with one leg and lower hips until both knees are bent at 90°. Push back to standing and alternate legs.",
            bodyPart: "Quads, Glutes, Hamstrings"
        ),
        BasicWorkout(
            name: "Shoulder Press",
            instructions: "Hold dumbbells at shoulder height with palms forward. Press weights overhead until arms are fully extended, then lower back down.",
            bodyPart: "Shoulders, Triceps"
        )
    ]

    var body: some View {
        NavigationStack {
            List(workouts) { workout in
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.name)
                        .font(.headline)
                    Text(workout.instructions)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Works: \(workout.bodyPart)")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Resources")
        }
    }
}
