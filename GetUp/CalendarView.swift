//
//  CalendarView.swift
//  GetUp
//
//  Created by ByteDance on 15/11/24.
//

import SwiftUI
import Foundation

struct CalendarView: View {
    @State private var currentDate = Calendar.current.startOfDay(for: Date()) // Start of today
    @State private var selectedDate = Calendar.current.startOfDay(for: Date()) // Start of today
    
    @State private var selectedTaskList: [TaskObject] = []
    @State private var showPopup: Bool = false
    
    private let calendar = Calendar.current
    @ObservedObject var taskManager: TaskManager

    init(taskManager: TaskManager) {
        self.taskManager = taskManager
    }

    var body: some View {
        ZStack{
            ZStack{
                VStack(alignment: .leading, spacing: 15) {
                    calendarPageHeader
                    calendarView
                        .padding(.horizontal,-15)
                    
                    Button (
                        action: {
                            withAnimation {
                                showPopup = true
                            }
                        },
                        label:{
                            HStack{
                                Image(systemName: "checklist")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("View Tasks")
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
                    
                    Spacer()
                }
                .padding([.leading, .trailing], 30)
                .padding([.top], 80)
                .padding([.bottom], 100)
                .frame(maxWidth: screenWidth, maxHeight: .infinity)
                .onAppear(){
                    selectToday()
                }
            }
            .blur(radius: showPopup ? 3 : 0)
            
            if showPopup {
                Color.white.opacity(0.95)
                    .ignoresSafeArea() // Dimmed background
                
                VStack (alignment:.center,spacing:20){
                    VStack (alignment:.center,spacing:10){
                        Text(dateToDayMonthString(selectedDate))
                            .font(.title2)
                            .fontWeight(.heavy)
                        Text("To Do List")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    TaskListView(taskList: $selectedTaskList,
                                 taskManager: taskManager,
                                 selectedDate: selectedDate)
                        .onChange(of: selectedTaskList) { newTasks in
                            // Update TaskManager with modified task list
                            taskManager.updateTaskList(for: selectedDate, with: newTasks)
                        }
                        .onReceive(selectedTaskList.publisher.flatMap { $0.objectWillChange }) { _ in
                            taskManager.updateTaskList(for: selectedDate, with: selectedTaskList)
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
    }

    // MARK: - Subviews

    private var calendarPageHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(userName)'s Calendar")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                
                Text("You're doing GREAT!! 🥳")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { selectToday() }) {
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
            Button(action: { goToPreviousMonth() }) {
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
            Button(action: { goToNextMonth() }) {
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
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(days.indices, id: \.self) { index in
                if let day = days[index] {
                    dayCircle(for: day)
                } else {
                    emptyDayCircle
                }
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
        
        if let tasksListByDate = taskManager.taskListsByDate{
            if let tasks = tasksListByDate[date] {
                let totalTasks = tasks.count
                let completedTasks = tasks.filter { $0.isDone }.count
                
                let percentageCompleted: CGFloat = CGFloat(completedTasks)/CGFloat(totalTasks)
                let printPercentageCompleted: Int = Int(percentageCompleted*100)
                let numTasksLeft: Int = totalTasks - completedTasks
                
                let displayColor: Color = getDisplayColorByCompletion(for: percentageCompleted)
                
                return ZStack{
                    Circle()
                        .strokeBorder(displayColor, lineWidth: selectedDateMatches(day) ? 2 : 1)
                        .background(
                            Circle()
                                .fill(selectedDateMatches(day) ? Color.black : Color.white.opacity(0.9))
                        )
                        .overlay(
                            Text("\(day)")
                                .font(.body)
                                .fontWeight(selectedDate == date ? .heavy : .regular)
                                .foregroundColor(selectedDate == date ? Color.white : Color.black)
                        )
                        .frame(width: 36, height: 36)
                }
                .onTapGesture {
                    selectDate(date)
                }
            }
        }
        
        return ZStack{
            Circle()
                .strokeBorder(Color.gray, lineWidth: 1)
                .background(
                    Circle()
                        .fill(selectedDateMatches(day) ? Color.black : Color.white.opacity(1))
                )
                .overlay(
                    Text("\(day)")
                        .font(.body)
                        .fontWeight(selectedDate == date ? .heavy : .regular)
                        .foregroundColor(selectedDate == date ? Color.white : Color.black)
                )
                .frame(width: 36, height: 36)
        }
        .onTapGesture {
            selectDate(date)
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
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
            return []
        }

        var days: [Date?] = []
        
        // Add empty slots for alignment (before the first day of the month)
        let weekdayOffset = calendar.component(.weekday, from: firstDayOfMonth)
        days.append(contentsOf: Array(repeating: nil, count: weekdayOffset - 1))
        
        // Add the actual dates
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func goToPreviousMonth() {
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = setToFirstDay(of: previousMonth)
            selectedDate = currentDate
        }
    }

    private func goToNextMonth() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = setToFirstDay(of: nextMonth)
            selectedDate = currentDate
        }
    }

    private func selectedDateMatches(_ day: Int) -> Bool {
        let selectedDay = calendar.component(.day, from: selectedDate)
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        return selectedDay == day && selectedMonth == currentMonth
    }
    
    private func selectDate(_ date:Date){
        selectedDate = date // Directly assign the full `Date`
        
        if let tasksListByDate = taskManager.taskListsByDate{
            if let taskList = tasksListByDate[selectedDate] {
                selectedTaskList = taskList
            } else{
                selectedTaskList = []
            }
        }
    }
    
    private func selectToday() {
        currentDate = startOfDay(for: Date())
        selectedDate = currentDate
        
        if let tasksListByDate = taskManager.taskListsByDate{
            if let taskList = tasksListByDate[selectedDate] {
                selectedTaskList = taskList
            } else{
                selectedTaskList = []
            }
        }
    }

    private func setToFirstDay(of date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private func startOfDay(for date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
}

#Preview {
    CalendarView(taskManager: TaskManager())
}
