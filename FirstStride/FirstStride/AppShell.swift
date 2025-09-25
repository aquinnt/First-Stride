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
    case profile   = "Profile"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .workouts:  return "figure.run"
        case .profile:   return "person.crop.circle"
        }
    }
}

struct AppShell: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showMenu = false
    @State private var current: AppPage = .dashboard

    var body: some View {
        ZStack {
            // Side menu
            if showMenu {
                SideMenu(current: $current, onSignOut: {
                    auth.signOut()
                })
                .transition(.move(edge: .leading))
            }

            // Main content with a top bar
            NavigationStack {
                Group {
                    switch current {
                    case .dashboard: DashboardView()
                    case .workouts:  WorkoutsView()
                    case .profile:   ProfileView()
                    }
                }
                .navigationTitle(current.rawValue)
                .toolbar {
                    // iOS uses .topBarLeading; macOS uses .navigation
                    #if os(iOS)
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut) { showMenu.toggle() }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                    #elseif os(macOS)
                    ToolbarItem(placement: .navigation) {
                        Button {
                            withAnimation(.easeInOut) { showMenu.toggle() }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                    #endif
                }
            }
            .offset(x: showMenu ? 240 : 0)
            .disabled(showMenu)
            .animation(.easeInOut, value: showMenu)
        }
    }
}

private struct SideMenu: View {
    @Binding var current: AppPage
    var onSignOut: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("First-Stride")
                .font(.title2).bold()
                .padding(.bottom, 8)

            ForEach(AppPage.allCases) { page in
                Button {
                    withAnimation(.easeInOut) { current = page }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: page.icon)
                        Text(page.rawValue)
                    }
                    .padding(.vertical, 8)
                }
            }

            Divider().padding(.vertical, 8)

            Button(role: .destructive) {
                onSignOut()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: 240, alignment: .leading)
        .background(.ultraThickMaterial)
        .ignoresSafeArea(edges: .vertical)
        .shadow(radius: 8)
    }
}
