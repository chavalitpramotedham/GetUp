//
//  CopyTaskPopupView.swift
//  GetUp
//
//  Created by ByteDance on 9/12/24.
//

import SwiftUI
import Combine
import Foundation

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct CopyTaskPopupView: View {
    @Binding var showPopup: Bool
    @Binding var copyTargetDates: [Date]
    
    @State private var currentDate: Date = Calendar.current.startOfDay(for: Date()) // Start of today
//    @State private var selectedDates: [Date] = []
    private let calendar = Calendar.current
    
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    
    var body: some View {
        VStack {
            monthNavigation
            daysOfWeekHeader
            daysGrid
            
            HStack{
                Button("Cancel") {
                    onCancel?()
                    withAnimation {
                        showPopup = false
                    }
                }
                .foregroundStyle(.white)
                .font(.title3)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth:.infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        . fill(Color.gray)
                )
                
                Button("Copy (\(copyTargetDates.count))") {
                    // Handle save action here
                    onSave?()
                    withAnimation {
                        showPopup = false
                    }
                }
                .foregroundStyle(.white)
                .font(.title3)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth:.infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.green)
                )
                .disabled(copyTargetDates.isEmpty) // Disable if newTaskName is empty
                .opacity(copyTargetDates.isEmpty ? 0.3 : 1) // Adjust opacity for disabled state
            }
        }
        .padding()
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .transition(.scale) // Popup scale animation
    }
    
    private var monthNavigation: some View {
        HStack {
            Button(action: { withAnimation {goToPreviousMonth() }}) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.2)))
            }
            Spacer()
            Text(monthYearString())
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button(action: { withAnimation {goToNextMonth() }}) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.2)))
            }
        }
        .padding(.horizontal)
    }

    private var daysOfWeekHeader: some View {
        HStack {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.black.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
    
    private var daysGrid: some View {
        let days = generateDaysInMonth()
        let rows = days.chunked(into: 7) // Split days into weeks (rows)
        
        return VStack(spacing: 2){
            ForEach(rows.indices, id: \.self) { rowIndex in
                let week = rows[rowIndex]
                HStack(spacing: 10) {
                    ForEach(week.indices, id: \.self) { dayIndex in
                        if let date = week[dayIndex] {
                            dayCircle(for: date)
                        } else {
                            emptyDayCircle
                        }
                    }
                }
                .padding(5)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 0) // Inner shadow effect
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var emptyDayCircle: some View {
        Circle()
            .fill(Color.clear)
            .frame(width: 36, height: 36)
    }
    
    private func dayCircle(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isSelected = copyTargetDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
        let isToday = calendar.isDate(date, inSameDayAs: Date()) // Check if the day is today
        
        return ZStack {
            Circle()
                .strokeBorder(isToday ? Color.black : Color.gray, lineWidth: isToday ? 2 : 1)
                .fill(isSelected ? Color.black : Color.white.opacity(0.9))
                .frame(width: 36, height: 36)
                .overlay(
                    Text("\(day)")
                        .font(.body)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundColor(isToday ? Color.green : isSelected ? Color.white : Color.black)
                )
        }
        .onTapGesture {
            toggleDateSelection(date)
        }
    }
    
    
    // MARK: - Helper Functions
    
    private func toggleDateSelection(_ date: Date) {
        if let index = copyTargetDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            copyTargetDates.remove(at: index)
            triggerHapticFeedback()
        } else {
            copyTargetDates.append(date)
            triggerHapticFeedback()
        }
    }
    
    private func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    private func generateDaysInMonth() -> [Date?] {
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let range = calendar.range(of: .day, in: .month, for: currentDate) else {
            return []
        }
        
        var days: [Date?] = []
        
        // Add trailing days from the previous month
        let weekdayOffset = calendar.component(.weekday, from: firstDayOfMonth) - 1
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate),
           let lastDayOfPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.last {
            let lastDateOfPreviousMonth = calendar.date(byAdding: .day, value: lastDayOfPreviousMonth - 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth))!)
            for i in (0..<weekdayOffset).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i - 1, to: firstDayOfMonth) {
                    days.append(date)
                }
            }
        }
        
        // Add actual dates for the current month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Add trailing days from the next month
        let totalDisplayedDays = days.count
        let remainingDays = 7 - (totalDisplayedDays % 7)
        if remainingDays < 7, let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            for i in 0..<remainingDays {
                if let date = calendar.date(byAdding: .day, value: i, to: calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!) {
                    days.append(date)
                }
            }
        }
        
        return days
    }
    
    private func goToPreviousMonth() {
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = previousMonth
        }
    }
    
    private func goToNextMonth() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = nextMonth
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
