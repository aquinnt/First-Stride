//
//  FirestoreService.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//  continued by Doug 0n 9/28
import Foundation
import FirebaseAuth
import FirebaseFirestore


// workoput model with all neccesarry field
struct Workout: Identifiable {
    var id: String = UUID().uuidString //created firebase id for storing
    var userId: String// these are data stored with the id
    var date: Date
    var type: String
    var durationMinutes: Int
    var distanceKm: Double?
}

final class FirestoreService {
    //reference to firestore
    private let db = Firestore.firestore()

    //computed property for user collection reference
    private var usersCol: CollectionReference {
        db.collection("users")
    }

    //computed property for workouts collection reference
    private var workoutsCol: CollectionReference {
        db.collection("workouts")
    }



    //saves a workout to firestore
    func addWorkout(_ w: Workout) async throws {
        let data: [String: Any?] = [
            "id": w.id,
            "userId": w.userId,
            "date": w.date, // stored as Timestamp automatically
            "type": w.type,
            "durationMinutes": w.durationMinutes,
            "distanceKm": w.distanceKm
        ]
        try await workoutsCol.document(w.id).setData(data.compactMapValues { $0 })
    }

    //loads most recent workouts for a user
    func recentWorkouts(for uid: String, limit: Int = 20) async throws -> [Workout] {
        let snap = try await workoutsCol
            .whereField("userId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snap.documents.map { doc in
            let d = doc.data()
            return Workout(
                id: d["id"] as? String ?? doc.documentID,
                userId: d["userId"] as? String ?? "",
                date: (d["date"] as? Timestamp)?.dateValue() ?? Date(),
                type: d["type"] as? String ?? "",
                durationMinutes: d["durationMinutes"] as? Int ?? 0,
                distanceKm: d["distanceKm"] as? Double
            )
        }
    }


    //writes and overwrites a user's profile document at users id
    func setUserProfile(_ profile: UserProfile) async throws {
        let data = try Firestore.Encoder().encode(profile)
        try await usersCol.document(profile.uid).setData(data, merge: true)
    }

    //reads the user's profile, if one is present
    func getUserProfile(uid: String) async throws -> UserProfile? {
        let doc = try await usersCol.document(uid).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        return try Firestore.Decoder().decode(UserProfile.self, from: data)
        // this returns the user profile or nill if none
    }
}
