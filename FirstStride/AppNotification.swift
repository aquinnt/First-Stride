//
//  AppNotification.swift
//  FirstStride
//
//  Created by Matthew Eskola on 11/5/25.
//


import Foundation

/// Central place for app-wide notification names.
enum AppNotification {
    /// Posted when a workout is saved in WorkoutEditorView.
    static let workoutSaved = Notification.Name("WorkoutSaved")
}
