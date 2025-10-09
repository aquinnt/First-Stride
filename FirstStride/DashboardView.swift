//
//  Dashboard.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI

// MARK: - Helpers
fileprivate extension DateFormatter {
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
}

struct DashboardView: View {
    @State private var displayDate = Date()
    @State private var selectedDate: Date? = Date()

    // Single sheet enum now exposes only workout editor/popup
    private enum ActiveSheet: Identifiable {
        case workoutPopup(date: Date)
        case workoutEditor(date: Date)

        var id: Int {
            switch self {
            case .workoutPopup: return 0
            case .workoutEditor: return 1
            }
        }
    }
    @State private var activeSheet: ActiveSheet? = nil

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    
    var body: some View {
        VStack(spacing: 16) {
            header
            calendarCard
            dailySummary
            Spacer()
        }
        .padding()
        .sheet(item: $activeSheet) { item in
            switch item {
            case .workoutPopup(let date):
                WorkoutPopupView(
                    date: date,
                    onCreate: {
                        activeSheet = .workoutEditor(date: date)
                    },
                    onLog: {
                        activeSheet = .workoutEditor(date: date)
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
            case .workoutEditor(let date):
                WorkoutEditorView(date: date) {
                    // Dismiss after save/cancel if needed
                    activeSheet = nil
                }
            }
        }
    }

    // MARK: Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to First-Stride 🏃‍♀️")
                    .font(.headline)
                Text("Your dashboard")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            Spacer()
            Button(action: {
                withAnimation {
                    displayDate = Date()
                    selectedDate = Date()
                }
            }) {
                Text("Today")
            }
        }
    }

    // MARK: Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 12) {
            monthNavigation
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(monthGridDates(), id: \.self) { date in
                    dayCell(for: date)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 6, y: 2)
    }

    private var monthNavigation: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.body)
            }
            Spacer()
            Text(DateFormatter.monthYear.string(from: displayDate))
                .font(.headline)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.body)
            }
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols(), id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let isWithinMonth = calendar.isDate(date, equalTo: displayDate, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate != nil ? calendar.isDate(selectedDate!, inSameDayAs: date) : false

        return Button {
            selectedDate = date
            if isWithinMonth {
                activeSheet = .workoutPopup(date: date)
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout)
                    .foregroundColor(isWithinMonth ? (isSelected ? .white : .primary) : .secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .disabled(!isWithinMonth)
        .opacity(isWithinMonth ? 1.0 : 0.5)
    }

    // MARK: Daily Summary
    private var dailySummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Summary")
                    .font(.headline)
                Spacer()
                if let sel = selectedDate {
                    Text(DateFormatter.shortDate.string(from: sel))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No date selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            HStack(spacing: 12) {
                metricBlock(title: "Workouts", value: "1")
                metricBlock(title: "Steps", value: "4,200")
                metricBlock(title: "Calories", value: "480 kcal")
            }
        }
        .padding()
        .background(Group {
            if #available(iOS 17.0, *) {
                Color.clear.background(.background.secondary)
            } else {
                Color(uiColor: .secondarySystemGroupedBackground)
            }
        })
        .cornerRadius(12)
    }

    private func metricBlock(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Helpers
    private func changeMonth(by offset: Int) {
        if let new = calendar.date(byAdding: .month, value: offset, to: displayDate) {
            displayDate = new
            selectedDate = nil
        }
    }

    private func weekdaySymbols() -> [String] {
        var symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        if first == 0 { return symbols }
        return Array(symbols[first...] + symbols[..<first])
    }

    private func monthGridDates() -> [Date] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate)) else { return [] }
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        guard let firstVisible = calendar.date(byAdding: .day, value: -offset, to: firstOfMonth) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: firstVisible) }
    }
}

// MARK: Popup View
struct WorkoutPopupView: View {
    let date: Date
    var onCreate: () -> Void
    var onLog: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("What would you like to do?")
                    .font(.title3)
                    .bold()
                Text(DateFormatter.shortDate.string(from: date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    Button(action: onCreate) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Workout")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }


                    Button(role: .cancel, action: onCancel) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// MARK: Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .preferredColorScheme(.light)
        DashboardView()
            .preferredColorScheme(.dark)
    }
}

//<<<<<<< HEAD



//=======
//>>>>>>> 6531ae07e8ff9ddbdc671ef464e4a5c1518cdfb9
