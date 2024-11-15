//
//  HabitListView.swift
//  GetUp
//
//  Created by ByteDance on 13/11/24.
//

import SwiftUI
import Foundation
import Combine

let colorDict: [Int: Color] = [
    0: Color.gray,
    1: Color.pink,
    2: Color.orange,
    3: Color.yellow,
    4: Color.blue
]

class TaskManager: ObservableObject {
    @Published var taskListsByDate: [Date: [TaskObject]]
    
    init(dates: [Date]) {
        // Initialize `taskListsByDate` with sample data for each date
        self.taskListsByDate = Dictionary(uniqueKeysWithValues: dates.map {
            ($0, getTaskListByDate($0))
        })
    }

    // Method to update `taskListsByDate` after modifying `selectedTaskList`
    func updateTaskList(for date: Date, with tasks: [TaskObject]) {
        taskListsByDate[date] = tasks
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
    @Published var timer: String

    init(index: Int = -1, name: String = "Task", description: String = "Description", colorIndex: Int = 0,isDone: Bool = false, timer: String = "00:00") {
        self.index = index
        self.name = name
        self.description = description
        self.colorIndex = colorIndex
        self.isDone = isDone
        self.timer = timer
    }
    
    static func == (lhs: TaskObject, rhs: TaskObject) -> Bool {
        lhs.id == rhs.id &&
        lhs.index == rhs.index &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.colorIndex == rhs.colorIndex &&
        lhs.isDone == rhs.isDone &&
        lhs.timer == rhs.timer
    }
}

struct HabitListView: View {
    
    var userName = "Chava"
    
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    var numDays = 8
    
    var pastDates: [Date] = getPastDays(30)
    var todayDates: [Date] = getToday()
    var futureDates: [Date] = getFutureDays(7)
    
    var combinedDates: [Date]
    
//    let taskListsByDate: [Date:[TaskObject]]
    
//    @State private var taskListsByDate: [Date: [TaskObject]]
    @State private var selectedCardIndex: Int
    @State private var selectedDate: Date
    @State private var selectedTaskList: [TaskObject]
    
    @StateObject private var taskManager: TaskManager
    @StateObject private var proxyHolder = ScrollViewProxyHolder()
    
    init() {
        self.combinedDates = pastDates + todayDates + futureDates
        
        let manager = TaskManager(dates: combinedDates)
        _taskManager = StateObject(wrappedValue: manager)
        
//        
//        _taskListsByDate = State(initialValue: Dictionary(uniqueKeysWithValues: combinedDates.map { date in
//            (date, getTaskListByDate(date))
//        }))

        _selectedCardIndex = State(initialValue: pastDates.count) // Assuming today is at index 30
        _selectedDate = State(initialValue: combinedDates[pastDates.count])
        _selectedTaskList = State(initialValue: [])
        
//        self.taskListsByDate = Dictionary(uniqueKeysWithValues: combinedDates.map { date in
//            (date, getTaskListByDate(date))
//        })
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
            
            VStack(alignment: .leading, spacing: 15) {
                // Title
                
                HStack(alignment: .bottom){
                    VStack(alignment: .leading, spacing:5){
                        Text("Hi, "+userName+"...")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(.black)
                        
                        Text("It's time to GET UP!!! 🫨🥵")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity,alignment: .leading)
                    
                    Button (
                        action: {
                            Task { resetSelection() }
                        },
                        label:{
                            VStack(alignment: .center, spacing:5){
                                Image(systemName: "clock.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    
                                Text("Today")
                                    .font(.system(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    . fill(Color.black.opacity(0.2))
                            )
                        }
                    )
                }
                .padding(.bottom,10)
                
                
                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing:10){
                                
                                ForEach(Array(pastDates.enumerated()), id: \.element) { index, date in
                                    
                                    if let tasks = taskManager.taskListsByDate[date] {
                                        let totalTasks = tasks.count
                                        let completedTasks = tasks.filter { $0.isDone }.count
                                        
                                        CalendarDayView(isSelected: selectedCardIndex == index,
                                                    onSelect:{
                                                        makeSelection(index)
                                                    },
                                                    isPast: true, isFuture: false, date: date,
                                                    totalTasks: totalTasks,
                                                    completedTasks: completedTasks,
                                                    id: index)
                                            .id(index)
                                    }
                                    
                                    
                                }
                                
                                ForEach(Array(todayDates.enumerated()), id: \.element) { index, date in
                                    
                                    if let tasks = taskManager.taskListsByDate[date] {
                                        let totalTasks = tasks.count
                                        let completedTasks = tasks.filter { $0.isDone }.count
                                        
                                        CalendarDayView(isSelected: selectedCardIndex == pastDates.count + index,
                                                    onSelect:{
                                                        makeSelection(pastDates.count + index)
                                                    },
                                                    isPast: false, isFuture: false, date: date,
                                                    totalTasks: totalTasks,
                                                    completedTasks: completedTasks,
                                                    id: pastDates.count + index)
                                            .id(pastDates.count + index)
                                    }
                                }
                                
                                ForEach(Array(futureDates.enumerated()), id: \.element) { index, date in
                                    
                                    if let tasks = taskManager.taskListsByDate[date] {
                                        let totalTasks = tasks.count
                                        let completedTasks = tasks.filter { $0.isDone }.count
                                        
                                        CalendarDayView(isSelected: selectedCardIndex == pastDates.count + 1 + index,
                                                    onSelect:{
                                                        makeSelection(pastDates.count + 1 + index)
                                                    },
                                                    isPast: false, isFuture: true, date: date,
                                                    totalTasks: totalTasks,
                                                    completedTasks: 0,
                                                    id: pastDates.count + 1 + index)
                                            .id(pastDates.count + 1 + index)
                                    }
                                }
                            }
                            .padding([.leading],30)
                            .frame(alignment:.trailing)
                    }
                    .padding(.horizontal,-30)
                    .onAppear {
                        if proxyHolder.proxy == nil {
                            proxyHolder.proxy = proxy
                            // Initial scroll to the center item
                            proxy.scrollTo(pastDates.count, anchor: .center)
                            resetSelection()
                        }
                    }
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
                    .padding(.horizontal,-15)
            }
            .padding([.leading, .trailing], 30)
            .padding([.top], 80)
            .padding([.bottom], 100)
            .frame(maxWidth: screenWidth, maxHeight: .infinity)
            
            FloatingNavBar()
                .frame(maxWidth: screenWidth)
        }
        .frame(maxWidth: screenWidth, maxHeight: screenHeight)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
    
    private func resetSelection() {
        guard let proxy = proxyHolder.proxy else { return }
        selectedCardIndex = pastDates.count
        selectedDate = combinedDates[selectedCardIndex]
        withAnimation {
            proxy.scrollTo(pastDates.count, anchor: .center)
        }
        
        if let taskList = taskManager.taskListsByDate[selectedDate]{
            selectedTaskList = taskList
        }
    }
    
    private func makeSelection(_ index: Int) {
        guard let proxy = proxyHolder.proxy else { return }
        selectedCardIndex = index
        selectedDate = combinedDates[selectedCardIndex]
        withAnimation {
            proxy.scrollTo(index, anchor: .center)
        }
        
        if let taskList = taskManager.taskListsByDate[selectedDate]{
            selectedTaskList = taskList
        }
    }
    
    private func updateTaskStatus(_ index: Int){
        if let taskList = taskManager.taskListsByDate[combinedDates[selectedCardIndex]]{
            taskList[index].isDone.toggle()
        }
    }
}

// Functions to get Past, Present, Future days

func getPastDays(_ numberOfDays: Int) -> [Date] {
    var dates: [Date] = []
    let calendar = Calendar.current
    
    // Generate dates from 30 days ago to today
    for dayOffset in (1..<30).reversed() {
        if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
            dates.append(date)
        }
    }
    
    return dates
}

func getToday() -> [Date] {
    return [Date()]
}

// Function to get the next 7 days
func getFutureDays(_ numberOfDays: Int) -> [Date] {
    var dates: [Date] = []
    let calendar = Calendar.current
    
    for dayOffset in 1...7 { // Start from 1 to exclude today
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) {
            dates.append(date) // Append to add in chronological order
        }
    }
    
    return dates
}

// Function to get Dummy Data

func getTaskListByDate(_ date: Date) -> [TaskObject] {
    let numTasks = Int.random(in:1...10)
    var taskList: [TaskObject] = []
    
    for i in 1...numTasks {
        let task = TaskObject(
            index: i,
            name: "Task \(i)",
            description: "long text long text long text long text long text long text long text long text long text long text long text long text",
            colorIndex: Int.random(in:0...4),
            isDone: Bool.random(),
            timer: "08:30"
        )
        taskList.append(task)
    }
    
    return taskList
}                                
                                
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HabitListView()
    }
}
