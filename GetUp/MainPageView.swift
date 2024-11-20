//
//  MainPageView.swift
//  GetUp
//
//  Created by ByteDance on 15/11/24.
//

import SwiftUI
import Foundation
import Combine

import FirebaseCore
import FirebaseFirestore

var numPastFutureDates: Int = 90

class TaskManager: ObservableObject {
    private var rawTaskList: [TaskObject] = getRawTastList()
    @Published var taskListsByDate: [Date: [TaskObject]]?
    
    @Published var pastDates: [Date] = getPastDays(numPastFutureDates)
    @Published var todayDates: [Date] = getToday()
    @Published var futureDates: [Date] = getFutureDays(numPastFutureDates)
    @Published var combinedDates: [Date]?
    
    private var firestoreManager = FirestoreManager()
    
    init() {
        
        self.combinedDates = pastDates + todayDates + futureDates
        
        fetchTasks()
        
//        firestoreManager.fetchTasks { [weak self] tasks, error in
//            if let error = error {
//                print("Error fetching tasks: \(error.localizedDescription)")
//            } else if let tasks = tasks {
//                DispatchQueue.main.async {
//                    print("Successfully fetched tasks!")
//                    print(tasks)
//                    self?.rawTaskList = tasks // Update the list on the main thread
//                    
//                    if let combinedDates = self?.combinedDates {
//                        self?.taskListsByDate = createTaskListsByDate(tasks: self?.rawTaskList ?? [], dateList: combinedDates)
//                    }
//                }
//            }
//        }
    }
    
    func fetchTasks() {
        firestoreManager.fetchTasks { [weak self] fetchedTasks, error in
            if let error = error {
                print("Error fetching tasks: \(error.localizedDescription)")
            } else if let fetchedTasks = fetchedTasks {
                DispatchQueue.main.async {
                    self?.rawTaskList = fetchedTasks
                    
                    self?.taskListsByDate = createTaskListsByDate(tasks: self?.rawTaskList ?? [], dateList: self?.combinedDates ?? [])
                }
            }
        }
    }

    // Method to update `taskListsByDate` after modifying `selectedTaskList`
    func updateTaskList(for date: Date, with tasks: [TaskObject]) {
        taskListsByDate?[date] = tasks
        rawTaskList = taskListsByDate?.flatMap { $0.value } ?? []
    }
    
    func saveTaskToDB(_ task: TaskObject) {
        firestoreManager.saveTask(task) { error in
            if let error = error {
                print("Error saving task: \(error.localizedDescription)")
            } else {
                print("Task successfully saved!")
            }
        }
    }
    
    func updateTaskToDB(_ task: TaskObject){
        firestoreManager.updateTask(task) { error in
            if let error = error {
                print("Error updating task: \(error.localizedDescription)")
            } else {
                print("Task successfully updated!")
            }
        }
    }
    
    func removeTaskFromDB(_ task: TaskObject){
        firestoreManager.deleteTask(task) { error in
            if let error = error {
                print("Error deleting task: \(error.localizedDescription)")
            } else {
                print("Task successfully deleted!")
            }
        }
    }
}

class ScrollViewProxyHolder: ObservableObject {
    var proxy: ScrollViewProxy?
}

// Function to get Dummy Data

func getTaskListByDate(_ date: Date) -> [TaskObject] {
    let numTasks = Int.random(in:5...20)
    var taskList: [TaskObject] = []
    
    let keys = Array(userDB.keys)
    
    for i in 1...numTasks {
        
        var randomParticipantStatusDict: [String: Bool] = [:]
        
        // Shuffle the keys and take the desired number of keys
        let selectedKeys = keys.shuffled().prefix(Int.random(in:0...1))
        
        // Assign a random Bool to each selected key
        for key in selectedKeys {
            randomParticipantStatusDict[key] = Bool.random()
        }
        
        let task = TaskObject(
            name: "Task \(i)",
            description: "long text long text long text long text long text long text long text long text long text long text long text long text",
            colorIndex: Int.random(in:0...(colorDict.count-1)),
            taskDate: randomTimeOnDate(date),
            timerSet: Bool.random(),
            creatorID: currentUserID,
            participantsStatus: randomParticipantStatusDict
        )
        taskList.append(task)
    }
    
    return taskList
}



struct MainPageView: View {
    
//    @State private var selectedCardIndex: Int
//    @State private var selectedDate: Date
//    @State private var selectedTaskList: [TaskObject]
    
    @StateObject private var taskManager: TaskManager
    @StateObject private var proxyHolder = ScrollViewProxyHolder()
    
    @State private var selectedBottomTab: Int
    
    init() {
        
        let manager = TaskManager()
        _taskManager = StateObject(wrappedValue: manager)
        _selectedBottomTab = State(initialValue: startingScreenIndex)
        
    }
    
    var body: some View {
        ZStack{
            Image("welcome_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0), Color.white.opacity(0.8),Color.white.opacity(0.9),Color.white.opacity(0.99)]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
            
            Group {
                switch selectedBottomTab {
                case 0:
                    HabitListView(taskManager: taskManager)
                case 1:
                    CalendarView(taskManager: taskManager)
                case 2:
                    Text("Social Tab")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case 3:
                    UserSelectionView()
                        .padding(.horizontal,30)

                default:
                    Text("Invalid Tab")
                }
            }
            
            FloatingNavBar(selectedTab: $selectedBottomTab)
                .frame(maxWidth: screenWidth)
        }
        .frame(maxWidth: screenWidth, maxHeight: screenHeight)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

// Get Raw Data
func getRawTastList() -> [TaskObject]{
    let pastDates: [Date] = getPastDays(numPastFutureDates)
    let todayDates: [Date] = getToday()
    let futureDates: [Date] = getFutureDays(numPastFutureDates)
    
    let combinedDates = pastDates + todayDates + futureDates
    
    let taskListsByDate = Dictionary(uniqueKeysWithValues: combinedDates.map { ($0, getTaskListByDate($0)) })
    
    return taskListsByDate.values.flatMap { $0 }
}

// Parsing data into TaskListByDate
func createTaskListsByDate(tasks: [TaskObject], dateList: [Date]) -> [Date: [TaskObject]]? {
    // Initialize the result dictionary with empty arrays for each date in the dateList
    var taskListsByDate: [Date: [TaskObject]] = [:]
    let calendar = Calendar.current
    
    // Ensure only valid dates in dateList are included
    for date in dateList {
        let startOfDay = calendar.startOfDay(for: date)
        taskListsByDate[startOfDay] = []
    }
    
    // Iterate through tasks and add them to the appropriate date in the dictionary
    for task in tasks {
        if let taskDate = task.taskDate {
            let startOfDay = calendar.startOfDay(for: taskDate)
            if taskListsByDate.keys.contains(startOfDay) {
                taskListsByDate[startOfDay]?.append(task)
            }
        }
    }
    
    return taskListsByDate.isEmpty ? nil : taskListsByDate
}

// Functions to get Past, Present, Future days

func getPastDays(_ numberOfDays: Int) -> [Date] {
    var dates: [Date] = []
    let calendar = Calendar.current
    
    // Generate dates from 30 days ago to today
    for dayOffset in (1..<numberOfDays).reversed() {
        if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
            dates.append(startOfDay(for: date))
        }
    }
    
    return dates
}

func getToday() -> [Date] {
    return [startOfDay(for: Date())]
}

// Function to get the next 7 days
func getFutureDays(_ numberOfDays: Int) -> [Date] {
    var dates: [Date] = []
    let calendar = Calendar.current
    
    for dayOffset in 1...numberOfDays { // Start from 1 to exclude today
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) {
            dates.append(startOfDay(for: date))
        }
    }
    
    return dates
}

func startOfDay(for date: Date) -> Date {
    return Calendar.current.startOfDay(for: date)
}

func currentTimeOfDate(for date: Date) -> Date{
    let calendar = Calendar.current
    let now = Date() // Current date and time
    
    // Extract the time components (hour, minute, second) from the current time
    let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
    
    // Combine the time components with the given date
    return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                         minute: timeComponents.minute ?? 0,
                         second: timeComponents.second ?? 0,
                         of: date) ?? date
}

func randomTimeOnDate(_ date: Date) -> Date {
    let calendar = Calendar.current
    
    // Get the start of the day (midnight) for the given date
    let startOfDay = calendar.startOfDay(for: date)
    
    // Calculate the range of seconds in the day (24 hours)
    let secondsInDay = 24 * 60 * 60
    let randomSeconds = Int.random(in: 0..<secondsInDay)
    
    // Add the random seconds to the start of the day
    return calendar.date(byAdding: .second, value: randomSeconds, to: startOfDay) ?? startOfDay
}

func formatDateTo24HourTime(date: Date?) -> String {
    if let validatedDate = date{
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // 12-hour format with AM/PM
        formatter.timeZone = TimeZone.current // Optional: Ensures it's in the local time zone
        return formatter.string(from: validatedDate)
    }
    else{
        return "-"
    }
}

func getDisplayColorByCompletion(totalTasks: Int, completedTasks: Int) -> Color {
    
    if totalTasks > 0{
        let percentageCompleted: CGFloat = CGFloat(completedTasks) / CGFloat(totalTasks)
        
        if percentageCompleted < 0.3 {
            return Color.red
        } else if percentageCompleted < 0.6 {
            return Color.orange
        } else if percentageCompleted < 0.9 {
            return Color.yellow
        } else {
            return Color.green
        }
        
    } else{
        return Color.gray
    }
}

func getOtherUIDs(from dict: [String: Bool]) -> [String] {
    return dict.keys.filter { $0 != currentUserID }
}

func getOtherUsername(from uid: String) -> String{
    return userDB[uid]?["userName"]?[0] ?? ""
}

#Preview{
    MainPageView()
}
                                
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainPageView()
//    }
//}
