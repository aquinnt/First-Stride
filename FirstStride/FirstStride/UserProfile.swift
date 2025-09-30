//
//  UserProfile.swift
//  FirstStride
//
//  Created by douglas miranda on 9/28/25.
//
import Foundation

//users profile saved to firebase
struct UserProfile: Codable, Equatable, Sendable{
    var uid: String //firebase auth id
    var name: String //display name
    var age: Int? // optional age, can edit later
    var weightKg: Double? // same as age
    var heightCm: Double? //same as age
    var email: String? //comes from firebase auth
    var createdAt: Date
    var updatedAt: Date 
}
