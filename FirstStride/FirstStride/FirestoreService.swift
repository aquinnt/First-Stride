//
//  FirestoreService.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import Foundation
import FirebaseFirestore

struct Workout: Identifiable {
    var id: String = UUID().uuidString
    var userId: String
    var date: Date
    var type: String
    var durationMinutes: Int
    var distanceKm: Double?
}

final class FirestoreService {
    private let db = Firestore.firestore()

    func addWorkout(_ w: Workout) async throws {
        let data: [String: Any?] = [
            "id": w.id,
            "userId": w.userId,
            "date": w.date,                  // Date is OK; Firestore stores as Timestamp
            "type": w.type,
            "durationMinutes": w.durationMinutes,
            "distanceKm": w.distanceKm
        ]
        try await db.collection("workouts").document(w.id).setData(data.compactMapValues { $0 })
    }

    func recentWorkouts(for uid: String, limit: Int = 20) async throws -> [Workout] {
        let snap = try await db.collection("workouts")
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
}
