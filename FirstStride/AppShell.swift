//
//  AppShell.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI
import FirebaseAuth

enum AppPage: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case workouts  = "Workouts"
    case stats     = "Stats"
    case profile   = "Profile"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .workouts:  return "figure.run"
        case .stats:     return "chart.bar.fill"
        case .profile:   return "person.crop.circle"
        }
    }
}

struct AppShell: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var current: AppPage = .dashboard

    var body: some View {
        TabView(selection: $current) {
            NavigationStack {
                DashboardView()
                    .navigationTitle(AppPage.dashboard.rawValue)
            }
            .tabItem {
                Image(systemName: AppPage.dashboard.icon)
                Text(AppPage.dashboard.rawValue)
            }
            .tag(AppPage.dashboard)

            NavigationStack {
                WorkoutsView()
                    .navigationTitle(AppPage.workouts.rawValue)
            }
            .tabItem {
                Image(systemName: AppPage.workouts.icon)
                Text(AppPage.workouts.rawValue)
            }
            .tag(AppPage.workouts)

            NavigationStack {
                StatsView()
                    .navigationTitle(AppPage.stats.rawValue)
            }
            .tabItem {
                Image(systemName: AppPage.stats.icon)
                Text(AppPage.stats.rawValue)
            }
            .tag(AppPage.stats)

            NavigationStack {
                ProfileView(signOutAction: {
                    auth.signOut()
                })
                .navigationTitle(AppPage.profile.rawValue)
            }
            .tabItem {
                Image(systemName: AppPage.profile.icon)
                Text(AppPage.profile.rawValue)
            }
            .tag(AppPage.profile)
        }
        .accentColor(.primary)
    }
}
