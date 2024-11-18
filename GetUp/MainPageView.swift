//
//  MainPageView.swift
//  GetUp
//
//  Created by ByteDance on 15/11/24.
//

import SwiftUI
import Foundation
import Combine

import SwiftUI
import Foundation
import Combine

let colorDict: [Int: Color] = [
    0: Color.gray,
    1: Color.mint,
    2: Color.purple,
    3: Color.pink,
    4: Color.orange
]

let nameDict: [Int: String] = [
    0: "GENERAL",
    1: "WORK",
    2: "EXERCISE",
    3: "LEARN",
    4: "SOCIAL"
]

// To be stored in DB

let userName = "Chava"
let uid = "123"

let userName2 = "Cheryl"
let uid2 = "456"

let userDict: [String:String] = [
    uid: userName,
    uid2: userName2
]

//

let startingScreenIndex = 0

let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

class TaskManager: ObservableObject {
    @Published var taskListsByDate: [Date: [TaskObject]]?
    
    @Published var pastDates: [Date] = getPastDays(30)
    @Published var todayDates: [Date] = getToday()
    @Published var futureDates: [Date] = getFutureDays(7)
    @Published var combinedDates: [Date]?
    
    init() {
        // Now that pastDates, todayDates, and futureDates are initialized, we can safely create combinedDates
        self.combinedDates = pastDates + todayDates + futureDates
        
        // After combinedDates is set, initialize taskListsByDate
        if let combinedDates = self.combinedDates {
            self.taskListsByDate = TaskManager.generateTaskLists(for: combinedDates)
        }
    }
    
    // Static function to generate task lists without needing `self`
    private static func generateTaskLists(for dates: [Date]) -> [Date: [TaskObject]] {
        return Dictionary(uniqueKeysWithValues: dates.map { ($0, getTaskListByDate($0)) })
    }

    // Method to update `taskListsByDate` after modifying `selectedTaskList`
    func updateTaskList(for date: Date, with tasks: [TaskObject]) {
        taskListsByDate?[date] = tasks
    }
}

class ScrollViewProxyHolder: ObservableObject {
    var proxy: ScrollViewProxy?
}

class TaskObject: ObservableObject, Identifiable, Equatable{
    @Published var index: Int
    @Published var name: String
    @Published var description: String
    @Published var colorIndex: Int
    @Published var isDone: Bool{
        didSet {
            objectWillChange.send() // Notify listeners
        }
    }
    @Published var timer: Date?
    @Published var creatorID: String
    @Published var participantsID: [String]

    init(index: Int = -1, name: String = "Task", description: String = "Description", colorIndex: Int = 0,isDone: Bool = false, timer: Date? = Date(), creatorID: String = uid, participantsID: [String] = [uid]) {
        self.index = index
        self.name = name
        self.description = description
        self.colorIndex = colorIndex
        self.isDone = isDone
        self.timer = timer ?? nil
        self.creatorID = creatorID
        self.participantsID = participantsID
    }
    
    static func == (lhs: TaskObject, rhs: TaskObject) -> Bool {
        lhs.id == rhs.id &&
        lhs.index == rhs.index &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.colorIndex == rhs.colorIndex &&
        lhs.isDone == rhs.isDone &&
        lhs.timer == rhs.timer &&
        lhs.creatorID == rhs.creatorID &&
        lhs.participantsID == rhs.participantsID
    }
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
                    Text("Profile View")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                default:
                    Text("Invalid Tab")
                }
            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            FloatingNavBar(selectedTab: $selectedBottomTab)
                .frame(maxWidth: screenWidth)
        }
        .frame(maxWidth: screenWidth, maxHeight: screenHeight)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

// Functions to get Past, Present, Future days

func getPastDays(_ numberOfDays: Int) -> [Date] {
    var dates: [Date] = []
    let calendar = Calendar.current
    
    // Generate dates from 30 days ago to today
    for dayOffset in (1..<30).reversed() {
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
    
    for dayOffset in 1...7 { // Start from 1 to exclude today
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) {
            dates.append(startOfDay(for: date))
        }
    }
    
    return dates
}

private func startOfDay(for date: Date) -> Date {
    return Calendar.current.startOfDay(for: date)
}

// Function to get Dummy Data

func getTaskListByDate(_ date: Date) -> [TaskObject] {
    let numTasks = Int.random(in:3...10)
    var taskList: [TaskObject] = []
    
    for i in 1...numTasks {
        let task = TaskObject(
            index: i,
            name: "Task \(i)",
            description: "long text long text long text long text long text long text long text long text long text long text long text long text",
            colorIndex: Int.random(in:0...(colorDict.count-1)),
            isDone: date > Calendar.current.startOfDay(for: Date()) ? false : Bool.random(),
            timer: randomTimeOnDate(date),
            creatorID: uid,
            participantsID: Int.random(in:0...1) > 0 ? [uid,uid2] : [uid]
        )
        taskList.append(task)
    }
    
    return taskList
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
        formatter.dateFormat = "HH:mm" // 24-hour format
        formatter.timeZone = TimeZone.current // Optional: Ensures it's in the local time zone
        return formatter.string(from: validatedDate)
    }
    else{
        return "-"
    }
}

func getDisplayColorByCompletion(for percentageCompleted: CGFloat) -> Color {
    if percentageCompleted < 0.3 {
        return Color.red
    } else if percentageCompleted < 0.6 {
        return Color.orange
    } else if percentageCompleted < 0.9 {
        return Color.yellow
    } else {
        return Color.green
    }
}

func getOtherUIDs(from array: [String]) -> [String] {
    return array.filter { !$0.contains(uid) }
}

func getOtherUsername(from uid: String) -> String{
    return userDict[uid] ?? ""
}

#Preview{
    MainPageView()
}
                                
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainPageView()
//    }
//}
