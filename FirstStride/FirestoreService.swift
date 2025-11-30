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
    var timed: Bool?
    var weightLbs: Double?
}

// Copy of workout model with all neccesarry field
struct TWorkout: Identifiable {
    var id: String = UUID().uuidString //created firebase id for storing
    var userId: String// these are data stored with the id
    var type: String
    var durationMinutes: Int
    var distanceKm: Double?
    var timed: Bool?
}

//routine model - Brvnson
struct Routine: Identifiable {
    var id: String = UUID().uuidString
    var userId: String
    var name: String
    var Muscles: [String]
    var type: [String]
    var durationMinutes: [Int]
    var distanceKm: [Double]?
    var timed: [Bool?]?
    var numexercises: Int
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
    
    private var tworkoutsCol: CollectionReference {
        db.collection("Tworkouts")
    }
    
    private var routinesCol: CollectionReference {
        db.collection("routines")
    }



    //saves a workout to firestore
    func addWorkout(_ w: Workout) async throws {
        let data: [String: Any?] = [
            "id": w.id,
            "userId": w.userId,
            "date": w.date, // stored as Timestamp automatically
            "type": w.type,
            "durationMinutes": w.durationMinutes,
            "distanceKm": w.distanceKm,
            "timed" : w.timed,
            "weight" : w.weightLbs
        ]
        try await workoutsCol.document(w.id).setData(data.compactMapValues { $0 })
    }
    
    func addTWorkout(_ w: TWorkout) async throws {
        let data: [String: Any?] = [
            "id": w.id,
            "userId": w.userId,
            "type": w.type,
            "durationMinutes": w.durationMinutes,
            "distanceKm": w.distanceKm,
            "timed" : w.timed
        ]
        try await tworkoutsCol.document(w.id).setData(data.compactMapValues { $0 })
    }
    
    //saves routine to firestore
    func addRoutine(_ r: Routine) async throws {
        let data: [String: Any?] = [
            "id": r.id,
            "userId": r.userId,
            "name": r.name,
            "Muscles": r.Muscles,
            "type": r.type,
            "durationMinutes": r.durationMinutes,
            "distanceKm": r.distanceKm,
            "timed" : r.timed,
            "numexercises": r.numexercises
        ]
        try await routinesCol.document(r.id).setData(data.compactMapValues { $0 })
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
                distanceKm: d["distanceKm"] as? Double,
                timed: d["timed"] as? Bool ?? false,
                weightLbs: d["weightLbs"] as? Double
            )
        }
    }
    
    func allWorkouts(for uid: String, limit: Int = 10000) async throws -> [Workout] {
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
                distanceKm: d["distanceKm"] as? Double,
                timed: d["timed"] as? Bool ?? false,
                weightLbs: d["weightLbs"] as? Double
            )
        }
    }
    
    func dateWorkouts(for uid: String, date: Date) async throws -> [Workout] {
        let snap = try await workoutsCol
            .whereField("userId", isEqualTo: uid)
            .whereField("date", isEqualTo: date as NSDate)
            .getDocuments()
        
        return snap.documents.map { doc in
            let d = doc.data()
            return Workout(
                id: d["id"] as? String ?? doc.documentID,
                userId: d["userId"] as? String ?? "",
                date: (d["date"] as? Timestamp)?.dateValue() ?? Date(),
                type: d["type"] as? String ?? "",
                durationMinutes: d["durationMinutes"] as? Int ?? 0,
                distanceKm: d["distanceKm"] as? Double,
                timed: d["timed"] as? Bool ?? false,
                weightLbs: d["weightLbs"] as? Double
            )
        }
    }
    
    func recentRoutines(for uid: String, limit: Int = 20) async throws -> [Routine] {
        let snap = try await routinesCol
            .whereField("userId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snap.documents.map { doc in
            let d = doc.data()
            return Routine(
                id: d["id"] as? String ?? doc.documentID,
                userId: d["userId"] as? String ?? "",
                name: d["name"] as? String ?? "",
                Muscles: d["Muscles"] as? [String] ?? [],
                type: d["type"] as? [String] ?? [],
                durationMinutes: d["durationMinutes"] as? [Int] ?? [],
                distanceKm: d["distanceKm"] as? [Double],
                timed: d["timed"] as? [Bool] ?? [],
                numexercises: d["numexercises"] as? Int ?? 0
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
