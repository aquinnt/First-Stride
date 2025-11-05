//
//  DashboardView.swift
//  FirstStride
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

struct DashboardView: View {
    // Calendar + date state
    @State private var displayDate: Date = Date()
    @State private var selectedDate: Date? = Date()
    private let calendar = Calendar.current

    // Dot/badge state (days with workouts)
    @State private var workoutDays = Set<DateComponents>()     // normalized Y/M/D keys
    private let dayUnits: Set<Calendar.Component> = [.year, .month, .day]

    // Sheet presentation
    @State private var showingEditor = false
    @State private var editorDate = Date()

    // Firebase auth listener
    @State private var authListener: AuthStateDidChangeListenerHandle?

    // App lifecycle
    @Environment(\.scenePhase) private var scenePhase

    // ---- Config: adjust if your schema differs ----
    private let workoutsCollectionID = "workouts"   // top-level collection (matches WorkoutsView)
    private let userIdField = "userId"              // field containing the owner's uid
    private let dateField = "date"                  // field that stores the workout time (Firestore Timestamp)
    private let enableDebugLogging = true          // set true to see prints in Xcode console
    // ----------------------------------------------

    var body: some View {
        VStack(spacing: 12) {
            header
            calendarGrid
            Spacer(minLength: 0)
        }
        .padding()

        // Load once view appears (will be a no-op if user isn't ready; listener below covers that)
        .onAppear {
            if enableDebugLogging { print("[Dashboard] onAppear") }
            attachAuthListenerIfNeeded()
            reloadDotsForCurrentMonth()
        }

        // Detach the auth listener when leaving
        .onDisappear {
            if let h = authListener {
                Auth.auth().removeStateDidChangeListener(h)
                authListener = nil
                if enableDebugLogging { print("[Dashboard] Removed auth listener") }
            }
        }

        // Reload when app becomes active (e.g., after relaunch / foreground)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                if enableDebugLogging { print("[Dashboard] App became active → reload") }
                reloadDotsForCurrentMonth()
            }
        }

        // When the visible month changes, reload dots from Firestore (iOS 17+ syntax)
        .onChange(of: displayDate) {
            if enableDebugLogging { print("[Dashboard] displayDate changed → reload") }
            reloadDotsForCurrentMonth()
        }

        // Live update: when an editor saves, mark the date immediately
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.workoutSaved)) { note in
            if let savedDate = note.object as? Date {
                if enableDebugLogging { print("[Dashboard] Received workoutSaved for \(savedDate)") }
                markWorkout(on: savedDate)
            }
        }

        // Present editor
        .sheet(isPresented: $showingEditor) {
            WorkoutEditorView(date: editorDate) {
                showingEditor = false
            }
        }
    }
}

// MARK: - UI
private extension DashboardView {
    var header: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            Spacer()
            Text(monthTitle(for: displayDate))
                .font(.headline)
            Spacer()
            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right").font(.headline)
            }
        }
    }

    var weekdayRow: some View {
        let symbols = calendar.shortWeekdaySymbols
        return HStack {
            ForEach(0..<7, id: \.self) { i in
                Text(symbols[(i + calendar.firstWeekday - 1) % 7])
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var calendarGrid: some View {
        VStack(spacing: 6) {
            weekdayRow
            let days = monthDays(for: displayDate)
            let rows = days.chunked(into: 7)
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(rows[r], id: \.self) { date in
                        dayCell(for: date)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
        }
    }

    func dayCell(for date: Date) -> some View {
        let isWithinMonth = calendar.isDate(date, equalTo: displayDate, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

        return Button {
            selectedDate = date
            if isWithinMonth {
                editorDate = date
                showingEditor = true
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle().fill(Color.accentColor).frame(width: 36, height: 36)
                } else if isToday {
                    Circle().stroke(Color.accentColor, lineWidth: 1.5).frame(width: 36, height: 36)
                }

                Text("\(calendar.component(.day, from: date))")
                    .font(.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isWithinMonth ? (isSelected ? .white : .primary) : .secondary)

                // Dot badge for saved workout
                if hasWorkout(on: date) {
                    Circle()
                        .frame(width: 6, height: 6)
                        .offset(y: 14) // under the day number
                        .foregroundColor(isSelected ? .white : .accentColor)
                        .accessibilityLabel("Workout scheduled")
                }
            }
            .frame(height: 44)
            .opacity(isWithinMonth ? 1.0 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isWithinMonth)
    }
}

// MARK: - Firestore loading (persisted dots)
private extension DashboardView {
    /// Attach an Auth state listener so we reload once Firebase restores the session on cold launch.
    func attachAuthListenerIfNeeded() {
        guard authListener == nil else { return }
        authListener = Auth.auth().addStateDidChangeListener { _, user in
            if enableDebugLogging { print("[Dashboard] Auth state changed. user = \(user?.uid ?? "nil")") }
            if user != nil {
                reloadDotsForCurrentMonth()
            }
        }
        if enableDebugLogging { print("[Dashboard] Added auth listener") }
    }

    /// Triggers an async reload of dots for the current visible month.
    func reloadDotsForCurrentMonth() {
        Task { await loadWorkoutDots(for: displayDate) }
    }

    /// Loads workouts for the given month and marks dots accordingly.
    /// Top-level collection (matches WorkoutsView).
    func loadWorkoutDots(for month: Date) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            if enableDebugLogging { print("[Dashboard] No signed-in user; skipping load.") }
            return
        }

        // Month range [monthStart, nextMonth)
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
            let nextMonth  = calendar.date(byAdding: .month, value: 1, to: monthStart)
        else { return }

        do {
            let db = Firestore.firestore()

            let snap = try await db.collection(workoutsCollectionID)
                .whereField(userIdField, isEqualTo: uid)
                .whereField(dateField, isGreaterThanOrEqualTo: monthStart)
                .whereField(dateField, isLessThan: nextMonth)
                .order(by: "date", descending: false)   // ← match the ASC index
                .getDocuments()

            let dates: [Date] = snap.documents.compactMap { doc in
                (doc.get(dateField) as? Timestamp)?.dateValue()
            }

            if enableDebugLogging {
                let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd HH:mm"
                print("[Dashboard] Loaded \(dates.count) workouts between \(fmt.string(from: monthStart)) and \(fmt.string(from: nextMonth))")
            }

            await MainActor.run {
                workoutDays.removeAll()
                for d in dates { markWorkout(on: d) }
            }
        } catch {
            // If you see an index error, create a composite index on (userId ASC, date ASC).
            print("[Dashboard] Failed to load workouts for month: \(error)")
        }
    }
}

// MARK: - Date helpers & dot bookkeeping
private extension DashboardView {
    func shiftMonth(by delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: displayDate) {
            displayDate = newDate
        }
    }

    func monthTitle(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: date)
    }

    func monthDays(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start))
        else { return [] }

        // Start on the calendar's week start for a full grid
        let firstWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstOfMonth)
        ) ?? firstOfMonth

        // 6 weeks (42 cells) covers all months
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: firstWeekStart) }
    }

    func dayKey(for date: Date) -> DateComponents {
        calendar.dateComponents(dayUnits, from: date)
    }

    func hasWorkout(on date: Date) -> Bool {
        workoutDays.contains(dayKey(for: date))
    }

    func markWorkout(on: Date) {
        workoutDays.insert(dayKey(for: on))
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}

// MARK: - Tiny utility
fileprivate extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
