//
//  Dashboard.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI

struct DashboardView: View {
    @State private var displayDate = Date()
    @State private var selectedDate: Date? = Date()
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
            Button(action: { withAnimation { displayDate = Date() } }) {
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
            Text(monthYearString(for: displayDate))
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
                    Text(shortDateString(for: sel))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No date selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            // Replace this with your real metrics (steps, calories, workouts)
            HStack(spacing: 12) {
                metricBlock(title: "Workouts", value: "1")
                metricBlock(title: "Steps", value: "4,200")
                metricBlock(title: "Calories", value: "480 kcal")
            }
        }
        .padding()
        .background(Group {
            if #available(iOS 17.0, *) {
                // uses new BackgroundStyle instance property
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
        }
    }

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private func shortDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func weekdaySymbols() -> [String] {
        var symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private func monthGridDates() -> [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayDate),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate))
        else { return [] }

        let firstWeekdayOfMonth = calendar.component(.weekday, from: firstOfMonth)
        let prefixDays = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7

        // previous month's tail
        var dates: [Date] = []
        if prefixDays > 0 {
            if let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayDate),
               let prevRange = calendar.range(of: .day, in: .month, for: prevMonth),
               let prevMonthLastDay = calendar.date(from: calendar.dateComponents([.year, .month], from: prevMonth))
            {
                let startDay = prevRange.count - prefixDays + 1
                for d in startDay...prevRange.count {
                    if let date = calendar.date(byAdding: .day, value: d - 1, to: prevMonthLastDay) {
                        dates.append(date)
                    }
                }
            }
        }

        // current month
        for d in monthRange {
            if let date = calendar.date(byAdding: .day, value: d - 1, to: firstOfMonth) {
                dates.append(date)
            }
        }

        // suffix to fill 6 rows (7 * 6 = 42 cells)
        while dates.count < 42 {
            if let next = calendar.date(byAdding: .day, value: dates.count - prefixDays, to: firstOfMonth) {
                dates.append(next)
            } else { break }
        }

        return dates
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



