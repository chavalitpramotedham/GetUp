//
//  CalendarView.swift
//  GetUp
//
//  Created by ByteDance on 15/11/24.
//

import SwiftUI
import Foundation

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct CalendarView: View {
    @State private var currentDate: Date = Calendar.current.startOfDay(for: Date()) // Start of today
    @State private var selectedDates: [Date] = [Calendar.current.startOfDay(for: Date())] // Start of today
    @State private var currentDateIndexInSelectedDates: Int = 0
    
    @State private var selectedTaskList: [TaskObject] = []
    @State private var showPopup: Bool = false
    
    @State private var selectedTab: CalendarSummaryTab = .daily
    
    private let calendar = Calendar.current
    @ObservedObject var taskManager: TaskManager
    
    enum CalendarSummaryTab {
        case daily, weekly
    }

    init(taskManager: TaskManager) {
        self.taskManager = taskManager
    }
    
    private var myTaskList: [TaskObject] {
        selectedTaskList.filter { task in
            task.participantsStatus.keys.contains(currentUserID)
        }
    }

    var body: some View {
        ZStack{
            ZStack{
                VStack(alignment: .leading, spacing: 15) {
                    calendarPageHeader
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack (spacing:20){
                            calendarView
                            
                            VStack (spacing:30){
                                HStack(spacing:15){
                                    DailyOrWeeklySelector(selectedTab: $selectedTab)
                                    
                                    Button (
                                        action: {
                                            withAnimation {
                                                showPopup = true
                                            }
                                        },
                                        label:{
                                            HStack{
                                                Image(systemName: "checklist")
                                                    .font(.system(size: 16))
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                            .padding(15)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.black)
                                            )
                                            
                                        }
                                    )
                                }
                                
                                CalendarSummary(taskManager: TaskManager(), totalTaskList: myTaskList)
                                
                            }
                            .padding()
                            .padding(.bottom,10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                            )
                            
                            Spacer()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal,-15)
                }
                .padding([.leading, .trailing], 30)
                .padding([.top], 80)
                .padding([.bottom], 100)
                .frame(maxWidth: screenWidth, maxHeight: .infinity)
                .onAppear(){
                    selectToday()
                }
                .refreshable {
                    taskManager.refresh() // Fetch tasks when pulled down
                }
                
            }
            .blur(radius: showPopup ? 3 : 0)
            
            if showPopup {
                Color.white.opacity(0.95)
                    .ignoresSafeArea() // Dimmed background
                
                VStack (alignment:.center,spacing:20){
                    VStack (alignment:.center,spacing:10){
                        if selectedDates.count > 1{
                            Text("Week of \(dateToDayMonthString(selectedDates[0]))")
                                .font(.title2)
                                .fontWeight(.heavy)
                        } else {
                            Text(dateToDayMonthString(selectedDates[0]))
                                .font(.title2)
                                .fontWeight(.heavy)
                        }
                        
                        Text("To Do List")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    TaskListView(taskList: $selectedTaskList,
                                 taskManager: taskManager,
                                 selectedDates: selectedDates)
                        .onChange(of: selectedTaskList) { newTasks in
                            // Update TaskManager with modified task list
                            taskManager.updateTaskList(for: selectedDates[selectedDates.count-1], with: newTasks)
                        }
                        .onReceive(selectedTaskList.publisher.flatMap { $0.objectWillChange }) { _ in
                            taskManager.updateTaskList(for: selectedDates[selectedDates.count-1], with: selectedTaskList)
                        }
                    
                    Button (
                        action: {
                            withAnimation {
                                showPopup = false
                            }
                        },
                        label:{
                            HStack{
                                Text("Done")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black)
                                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                            )
                        }
                    )
                    .padding(.horizontal,-15)
                    .frame(maxWidth: .infinity)
                    
                }
                .padding()
                .padding(.vertical,100)
                .frame(maxWidth: screenWidth, maxHeight:screenHeight)
                
                
            }
        }
        .onChange(of: selectedTab) { newValue in
            withAnimation{
                selectDate(currentDate)
            }
        }
    }

    // MARK: - Subviews

    private var calendarPageHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(currentUserName)'s Calendar")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                
                Text("You're doing GREAT!! 🥳")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { withAnimation {selectToday()} }) {
                todayButtonContent
            }
        }
        .padding(.bottom, 10)
    }

    private var todayButtonContent: some View {
        VStack(alignment: .center, spacing: 5) {
            Image(systemName: "clock.fill")
                .font(.title3)
                .foregroundColor(.white)
                
            Text("Today")
                .font(.system(size: 10))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.2)))
    }
    
    private var calendarView: some View {
        VStack(alignment:.center,spacing:10){
            monthNavigation
            daysOfWeekHeader
            daysGrid
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button(action: { withAnimation {goToPreviousMonth() }}) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.4)))
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
                    .background(Circle().fill(Color.black.opacity(0.4)))
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
        
        return VStack(spacing: 2) {
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
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(selectedTab == .weekly && isDateInWeek(week, currentDate) ? Color.gray.opacity(0.25) : Color.clear)
                )
                .cornerRadius(8)
            }
        }
        .padding()
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
        let isInCurrentCalendarMonth = calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
        
        if let tasksListByDate = taskManager.taskListsByDate{
            if let tasks = tasksListByDate[date] {
                let totalTasks = tasks.count
                let completedTasks = tasks.filter { $0.participantsStatus[currentUserID] ?? false }.count
                
                let percentageCompleted: CGFloat = totalTasks > 0 ? CGFloat(completedTasks) / CGFloat(totalTasks) : 0
                let printPercentageCompleted: Int = totalTasks > 0 ? Int(percentageCompleted * 100) : 0
                let numTasksLeft: Int = totalTasks - completedTasks
                
                let displayColor: Color = getDisplayColorByCompletion(totalTasks: totalTasks, completedTasks: completedTasks)
                
                return ZStack{
                    Circle()
                        .strokeBorder(isInCurrentCalendarMonth ? displayColor : Color.clear, lineWidth: selectedDateMatches(day) ? 2 : 1)
                        .background(
                            Circle()
                                .fill(isInCurrentCalendarMonth ? (selectedDateMatches(day) ? Color.black : Color.white.opacity(0.9)) : Color.gray.opacity(0.2))
                        )
                        .overlay(
                            Text("\(day)")
                                .font(.body)
                                .fontWeight(isInCurrentCalendarMonth ? (currentDate == date ? .heavy : .regular) : .regular)
                                .foregroundColor(isInCurrentCalendarMonth ? (currentDate == date ? Color.white : Color.black) : Color.black)
                        )
                        .frame(width: 36, height: 36)
                }
                .onTapGesture {
                    if isInCurrentCalendarMonth {
                        withAnimation {
                            selectDate(date)
                        }
                    } else {
                        withAnimation {
                            if date < currentDate {
                                goToPreviousMonth()
                            } else {
                                goToNextMonth()
                            }
                            selectDate(date)
                        }
                    }
                }
            }
        }
        
        return ZStack{
            Circle()
                .strokeBorder(isInCurrentCalendarMonth ? Color.gray : Color.clear, lineWidth: selectedDateMatches(day) ? 2 : 1)
                .background(
                    Circle()
                        .fill(isInCurrentCalendarMonth ? (selectedDateMatches(day) ? Color.black : Color.white.opacity(0.9)) : Color.gray.opacity(0.2))
                )
                .overlay(
                    Text("\(day)")
                        .font(.body)
                        .fontWeight(isInCurrentCalendarMonth ? (currentDate == date ? .heavy : .regular) : .regular)
                        .foregroundColor(isInCurrentCalendarMonth ? (currentDate == date ? Color.white : Color.black) : Color.black)
                )
                .frame(width: 36, height: 36)
        }
        .onTapGesture {
            withAnimation {
                selectDate(date)
            }
        }
    }

    // Extracted text overlay for the circle to reduce complexity
    private func dayText(day: Int) -> some View {
        Text("\(day)")
            .font(.body)
            .fontWeight(selectedDateMatches(day) ? .heavy : .regular)
            .foregroundColor(selectedDateMatches(day) ? Color.white : Color.black)
    }

    // MARK: - Helper Functions
    
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
            selectDate(setToFirstDay(of: previousMonth))
        }
    }

    private func goToNextMonth() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            selectDate(setToFirstDay(of: nextMonth))
        }
    }

    private func selectedDateMatches(_ day: Int) -> Bool {
        let selectedDay = calendar.component(.day, from: currentDate)
        let selectedMonth = calendar.component(.month, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        return selectedDay == day && selectedMonth == currentMonth
    }
    
    private func isDateInWeek(_ week: [Date?], _ date: Date) -> Bool {
        for day in week {
            if let day = day, calendar.isDate(day, inSameDayAs: date) {
                return true
            }
        }
        return false
    }
    
    private func datesInWeek(for date: Date) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        let startOfWeek = weekInterval.start
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private func selectDate(_ date:Date){
        triggerHapticFeedback()
        currentDate = date
        
        if selectedTab == .daily {
            selectedDates = [date]
        } else if selectedTab == .weekly {
            selectedDates = datesInWeek(for: date)
        }
        
        selectedTaskList = []
                                
        for date in selectedDates {
            if let tasksListByDate = taskManager.taskListsByDate{
                if let taskList = tasksListByDate[date] {
                    selectedTaskList.append(contentsOf: taskList)
                }
            }
        }
    }
    
    private func selectToday() {
        triggerHapticFeedback()
        currentDate = startOfDay(for: Date())
        
        if selectedTab == .daily {
            selectedDates = [currentDate]
        } else if selectedTab == .weekly {
            selectedDates = datesInWeek(for: currentDate)
        }
        
        selectedTaskList = []
                                
        for date in selectedDates {
            if let tasksListByDate = taskManager.taskListsByDate{
                if let taskList = tasksListByDate[date] {
                    selectedTaskList.append(contentsOf: taskList)
                }
            }
        }
    }

    private func setToFirstDay(of date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}

struct DailyOrWeeklySelector: View {
    @Binding var selectedTab: CalendarView.CalendarSummaryTab
    
    var body: some View {
        HStack(alignment: .center){
            HStack(alignment:.center,spacing:10){
                Text("Daily")
                    .font(.system(size: 16))
                    .fontWeight(selectedTab == .daily ? .heavy : .semibold)
            }
            .padding(.vertical,10)
            .padding(.horizontal,15)
            .frame(maxWidth:.infinity, maxHeight:.infinity)

            .foregroundColor(selectedTab == .daily ? Color.white : Color.black)
            .background{
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedTab == .daily ? Color.black : Color.clear)
                    .stroke(selectedTab == .daily ? Color.gray.opacity(0.3) : Color.clear)
            }
            .onTapGesture {
                triggerHapticFeedback()
                selectedTab = .daily
            }
            
            HStack(alignment:.center,spacing:10){
                Text("Weekly")
                    .font(.system(size: 16))
                    .fontWeight(selectedTab == .weekly ? .heavy : .semibold)
            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .frame(maxWidth:.infinity, maxHeight:.infinity)
            .foregroundColor(selectedTab == .weekly ? Color.white : Color.black)
            .background{
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedTab == .weekly ? Color.black : Color.clear)
                    .stroke(selectedTab == .weekly ? Color.gray.opacity(0.3) : Color.clear)
            }
            .onTapGesture {
                triggerHapticFeedback()
                selectedTab = .weekly
            }
        }
        .padding(5)
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .background{
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
    }
}
