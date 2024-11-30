//
//  GetUpWidget.swift
//  GetUpWidget
//
//  Created by ByteDance on 27/11/24.
//

import WidgetKit
import SwiftUI
import Foundation
import FirebaseCore
import FirebaseFirestore

var currentDeviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
var currentUserID = ""
var currentUserImageURL: String = ""

// To be stored in DB
let userDB: [String:[String:[String]]] = [
    "123": [
        "userName": ["Chava"],
        "profilePicture": ["Chava"],
        "connections": ["456"]
    ],
    "456":
    [
        "userName": ["Cheryl"],
        "profilePicture": ["Cheryl"],
        "connections": ["123"]
    ]
]

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
    4: "ENJOY"
]

class TaskObjectForWidget: Identifiable {
    var taskID: String
    var colorIndex: Int
    var name: String
    var isDone: Bool
    var timerSet: Bool
    var taskDate: Date
    var participantsStatus : [String:Bool]
    
    init(taskID: String, colorIndex: Int, name: String, isDone: Bool, timerSet: Bool, taskDate: Date, participantsStatus: [String:Bool]) {
        self.taskID = taskID
        self.colorIndex = colorIndex
        self.name = name
        self.isDone = isDone
        self.timerSet = timerSet
        self.taskDate = taskDate
        self.participantsStatus = participantsStatus
    }
    
    // Initialize from Firestore Document
    convenience init?(from document: [String: Any]) {
        guard
            let taskID = document["taskID"] as? String,
            let name = document["name"] as? String,
            let colorIndex = document["colorIndex"] as? Int,
            let timerSet = document["timerSet"] as? Bool,
            let participantsStatus = document["participantsStatus"] as? [String: Bool],
            let taskDateTimestamp = document["taskDate"] as? Timestamp,
            let participantsStatus = document["participantsStatus"] as? [String: Bool]
        else {
            return nil // Return nil if required fields are missing
        }

        let isDone = participantsStatus[currentUserID] ?? false
        let taskDate = taskDateTimestamp.dateValue()

        self.init(
            taskID: taskID,
            colorIndex: colorIndex,
            name: name,
            isDone: isDone,
            timerSet: timerSet,
            taskDate: taskDate,
            participantsStatus: participantsStatus
        )
    }
}

class FirestoreManager {
    private let db = Firestore.firestore() // Firestore instance

    // Fetch all tasks
    func fetchTasks(completion: @escaping ([TaskObjectForWidget]?, Error?) -> Void) {
        db.collection("tasks").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error) // Return error if fetching fails
                return
            }

            // Parse documents into TaskObjectForWidget instances
            let tasks = snapshot?.documents.compactMap { doc in
                TaskObjectForWidget(from: doc.data())
            }
            completion(tasks, nil)
        }
    }
}

class TaskManager: ObservableObject {
    @Published var todayTaskList: [TaskObjectForWidget]?
    private var firestoreManager = FirestoreManager()

    init() {
        getLastLinkedUser()
        fetchTasks()
    }

    func fetchTasks() {
        firestoreManager.fetchTasks { [weak self] fetchedTasks, error in
            if let error = error {
                print("Error fetching tasks: \(error.localizedDescription)")
            } else if let fetchedTasks = fetchedTasks {
                DispatchQueue.main.async {
                    self?.todayTaskList = self?.getTodayTaskList(fetchedTasks)
                    print("Tasks fetched: \(fetchedTasks.count)")
                }
            }
        }
    }
    
    // Filter tasks for today
    func getTodayTaskList(_ tasks: [TaskObjectForWidget]) -> [TaskObjectForWidget] {
        let calendar = Calendar.current
        let today = Date()

        // Filter tasks for today
        let todayTasks = tasks.filter { task in
            calendar.isDate(task.taskDate, inSameDayAs: today)
        }
        
        let myTodayTasks = todayTasks.filter { task in
            task.participantsStatus.keys.contains(currentUserID)
        }

        // Sort the tasks
        return myTodayTasks.sorted { task1, task2 in
            // 1. Tasks with `timerSet == true` come first
            // 2. Among tasks with `timerSet == true`, sort by `taskDate` (earlier -> later)
            // 3. Tasks with `timerSet == false` come after
            if task1.timerSet && !task2.timerSet {
                return true
            } else if !task1.timerSet && task2.timerSet {
                return false
            } else {
                return task1.taskDate < task2.taskDate
            }
        }
    }
}

extension TaskManager {
    /// Calculate the completion percentage for each task category.
    var todayCompletionPercentage: Double {
        let totalTaskNum = todayTaskList?.count ?? 0
        let completedTasks = todayTaskList?.filter { $0.isDone }
        let completedTaskNum = completedTasks?.count ?? 0
        return totalTaskNum == 0 ? 0.0 : Double(completedTaskNum) / Double(totalTaskNum)
    }
    
    var todayRemainingTopTasks: [TaskObjectForWidget] {
        let remainingTaskList = todayTaskList?.filter { !$0.isDone }
        let topTasks = remainingTaskList?.prefix(3).map { $0 } ?? []
        return topTasks
    }
}

struct Provider: AppIntentTimelineProvider {
    private let taskManager = TaskManager() // Instance of TaskManager to fetch tasks

    func placeholder(in context: Context) -> SimpleEntry {
        // Placeholder data for the widget preview
        SimpleEntry(
            date: Date(),
            taskList: [],
            completionPercentage: 0.0,
            topTasks: []
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // Return a snapshot with sample data
        let sampleTasks = [
            TaskObjectForWidget(taskID: "1", colorIndex: 0, name: "Sample Task 1", isDone: true, timerSet: false, taskDate: Date(), participantsStatus: ["123":false]),
            TaskObjectForWidget(taskID: "2", colorIndex: 1, name: "Sample Task 2", isDone: false, timerSet: true, taskDate: Date(), participantsStatus: ["123":false]),
            TaskObjectForWidget(taskID: "3", colorIndex: 2, name: "Sample Task 3", isDone: false, timerSet: false, taskDate: Date(), participantsStatus: ["123":false]),
        ]
        
        let totalTaskNum = sampleTasks.count
        let completedTasks = sampleTasks.filter { $0.isDone }
        let completedTaskNum = completedTasks.count
        let completionPercentage = completedTaskNum == 0 ? 0.0 : Double(completedTaskNum) / Double(totalTaskNum)

        return SimpleEntry(
            date: Date(),
            taskList: sampleTasks,
            completionPercentage: completionPercentage,
            topTasks: Array(sampleTasks.prefix(3))
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Fetch today's tasks
        await fetchTasksAndGenerateEntry { entry in
            entries.append(entry)
        }

        // Return the timeline
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func fetchTasksAndGenerateEntry(completion: @escaping (SimpleEntry) -> Void) async {
        let taskManager = TaskManager()

        // Fetch tasks
        await withCheckedContinuation { continuation in
            taskManager.fetchTasks()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Small delay to ensure data is fetched
                continuation.resume()
            }
        }

        let todayTaskList = taskManager.todayTaskList ?? []
        let completionPercentage = taskManager.todayCompletionPercentage
        let topTasks = taskManager.todayRemainingTopTasks

        // Generate an entry
        let entry = SimpleEntry(
            date: Date(),
            taskList: todayTaskList,
            completionPercentage: completionPercentage,
            topTasks: topTasks
        )

        completion(entry)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let taskList : [TaskObjectForWidget]
    let completionPercentage: Double
    let topTasks: [TaskObjectForWidget]               // Top tasks to display
}

struct GetUpWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        
        let totalTasks = entry.taskList.count
        let completedTasks = entry.taskList.filter { $0.isDone }.count
        let displayColor: Color = getDisplayColorByCompletion(totalTasks: totalTasks, completedTasks: completedTasks)
        
        
        ZStack{
            Image("widget_bg")
                .resizable()
                .scaledToFill() // Ensures the image scales proportionally
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the widget's size
                .clipped() // Ensures no overflow occurs
                .ignoresSafeArea()

            // White overlay with 75% opacity
//            Color.white.opacity(0.75)
//                .ignoresSafeArea()
            
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(1), Color.white.opacity(0.95),
                                            Color.white.opacity(0.9),Color.white.opacity(0.8),
                                            Color.white.opacity(0.7),Color.white.opacity(0.7),
                                            Color.white.opacity(0.7),Color.white.opacity(0.7),
                                            Color.white.opacity(0.7),Color.white.opacity(0.7),
                                            Color.white.opacity(0.7),Color.white.opacity(0.7),
                                            Color.white.opacity(0.7),Color.white.opacity(0.7),
                                            Color.white.opacity(0.8),Color.white.opacity(0.9),
                                            Color.white.opacity(0.95),Color.white.opacity(1),]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
            
            HStack(alignment: .top, spacing: 15) {
                // Concentric Circle Summary
                WidgetConcentricCircleView(taskList: entry.taskList)
                    .frame(width: 120, height: 120) // Adjust size as needed
                    .background(
                        Circle()
                            .fill(Color.white)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 0)

                // Task List
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment:.center,spacing:10){
//                        if currentUserImageURL != "" {
//                            let url = URL(string: currentUserImageURL)
//                            
//                            AsyncImage(url: url) { image in
//                                image
//                                    .resizable()
//                                    .scaledToFill()
//                                    .scaleEffect(1.5)
//                                    .frame(width: 25, height: 25)
//                                    .clipShape(Circle()) // Make the image circular
//                                    .overlay(
//                                        Circle()
//                                            .stroke(Color.black, lineWidth: 0.5) // Add a black outline
//                                    )
//                                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
//                            } placeholder: {
//                                ZStack{
//                                    Circle()
//                                        .fill(Color.gray.opacity(0.6))
//                                        .stroke(Color.black, lineWidth: 0.5) // Add a black outline
//                                        .frame(width: 25, height: 25)
//                                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
//                                    
////                                    ProgressView()
//                                }
//                            }
//                        }
                        
                        VStack(alignment:.leading, spacing:3){
                            if entry.taskList.count == 0{
                                Text("No Tasks Yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                    .fontWeight(.bold)
                                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                            }else{
                                HStack(alignment: .bottom){
                                    Text("\(Int(entry.completionPercentage * 100))%")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                        .fontWeight(.heavy)
                                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                                    
                                    Spacer()
                                    
                                    Text("\(completedTasks)/\(totalTasks) Done")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .fontWeight(.semibold)
                                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                                }
                                .frame(maxWidth:.infinity)
                                
                            }
                            
                            ProgressView(value: entry.completionPercentage)
                                .progressViewStyle(LinearProgressViewStyle(tint: displayColor))
                                .scaleEffect(x: 1, y: 1, anchor: .center)
                                .frame(maxWidth:.infinity)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        }
                    }
                    
                    widgetTaskList
                    
                }
                .frame(maxWidth:.infinity)
            }

            .frame(maxWidth:.infinity,maxHeight: .infinity)
        }
    }
    
    
    private var widgetTaskList: some View {
        let totalTasks = entry.taskList.count
        let completedTasks = entry.taskList.filter { $0.isDone }.count
        let displayColor: Color = getDisplayColorByCompletion(totalTasks: totalTasks, completedTasks: completedTasks)
        
        return VStack(alignment:.leading,spacing:8){
            VStack(alignment:.leading,spacing:5){
                ForEach(entry.topTasks, id: \.taskID) { task in
                    WidgetTaskCardView(task: task)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 0)
                }
                
                if entry.topTasks.count < 3{
                    ForEach(0..<(3 - entry.topTasks.count), id: \.self) { _ in
                        EmptyWidgetTaskCardView()
                    }
                }
            }
            
            if (entry.topTasks.count < (totalTasks - completedTasks)){
                let otherNum = (totalTasks - completedTasks) - entry.topTasks.count
                Text("+\(otherNum) more")
                    .font(.system(size: 10))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
        }
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

struct WidgetTaskCardView: View {
    var task: TaskObjectForWidget
    
    var body: some View {
        HStack(alignment:.center,spacing:6) {
            Rectangle()
                .fill(colorDict[task.colorIndex] ?? .gray)
                .frame(width:6,height:20)
            
            HStack(alignment:.center) {
                Text(task.name)
                    .font(.system(size: 11))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.black)
                
                Spacer()
                
                if task.timerSet{
                    Text(formatDateTo24HourTime(date:task.taskDate))
                        .font(.system(size: 10))
                        .fontWeight(.regular)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.trailing,5)
            .frame(maxWidth:.infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

struct EmptyWidgetTaskCardView: View {
    
    var body: some View {
        HStack(alignment:.center,spacing:6) {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(width:6,height:20)
            
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.gray.opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

struct WidgetConcentricCircleView: View {
    var taskList: [TaskObjectForWidget]
    let circleThickness: CGFloat = 8.5

    var body: some View {
        let categories = taskCategories(taskList)

        ZStack {
            ForEach(categories.indices, id: \.self) { index in
                let category = categories[index]
                let totalTasks = category.totalTasks
                let progress = category.progress
                let color = category.color
                
                ZStack {
                    Circle()
                        .stroke(totalTasks > 0 ? color.opacity(0.3) : color.opacity(0.1), style: StrokeStyle(lineWidth: circleThickness, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: calculateSize(index), height: calculateSize(index))

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: circleThickness, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: calculateSize(index), height: calculateSize(index))
                }
            }
        }
        .padding()
    }

    private func calculateSize(_ index: Int) -> CGFloat {
        let baseSize: CGFloat = 110
        let spacing: CGFloat = 13.5
        return baseSize - CGFloat(index) * (circleThickness + spacing)
    }
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

/// Calculate task categories and their progress
func taskCategories(_ taskList: [TaskObjectForWidget]) -> [(name: String, color: Color, progress: CGFloat, totalTasks: Int, completedTasks: Int)] {
    var categories: [(name: String, color: Color, progress: CGFloat, totalTasks: Int, completedTasks: Int)] = []

    for (index, color) in colorDict.sorted(by: { $0.key < $1.key }) {
        let name = nameDict[index] ?? ""
        let tasksInCategory = taskList.filter { $0.colorIndex == index }
        let totalTasks = tasksInCategory.count
        let completedTasks = tasksInCategory.filter { $0.isDone }.count
        let progress: CGFloat = totalTasks > 0 ? CGFloat(completedTasks) / CGFloat(totalTasks) : 0

        categories.append((name: name, color: color, progress: progress, totalTasks: totalTasks, completedTasks: completedTasks))
    }

    return categories
}

func getLastLinkedUser(){
    let deviceRef = Firestore.firestore().collection("deviceToUsers").document(currentDeviceID)

    deviceRef.getDocument { document, error in
        if let error = error {
            print("Error fetching device document: \(error.localizedDescription)")
            return
        }
        
        guard let document = document, document.exists,
              let lastLinkedUID = document.data()?["lastLinkedUID"] as? String else {
            print("Document does not exist or lastLinkedUID is missing.")
            return
        }
        
        print("Retrieved lastLinkedUID: \(lastLinkedUID)")
        
        // Now fetch the user data based on this UID
        if !lastLinkedUID.isEmpty {
            currentUserID = lastLinkedUID

//            Task {
//                do {
//                    try await setUserData(lastLinkedUID) // Use the retrieved UID
//                } catch {
//                    print("Failed to set user data for lastLinkedUID \(lastLinkedUID): \(error.localizedDescription)")
//                }
//            }
        } else {
            print("No lastLinkedUID found.")
        }
    }
}

//func setUserData(_ uid: String) async throws {
//    do {
//        let data = try await fetchUserData(from: uid)
//
//        // Assign values to your variables
//        currentUserID = uid
//        currentUserImageURL = data["userImageURL"] as? String ?? ""
//
//        // Optional: Print to verify
//        print("User Data:")
//        print("ID: \(currentUserID)")
//        print("Image URL: \(currentUserImageURL)")
//    } catch {
//        print("Error fetching user data: \(error.localizedDescription)")
//        throw error // Rethrow the error if necessary
//    }
//}

//func fetchUserData(from uid: String) async throws -> [String: Any] {
//    let userRef = Firestore.firestore().collection("users").document(uid)
//
//    do {
//        let document = try await userRef.getDocument()
//        if let data = document.data() {
//            return data // Return the document data
//        } else {
//            throw NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document does not exist or has no data."])
//        }
//    } catch {
//        throw error // Propagate the error
//    }
//}

struct GetUpWidget: Widget {
    let kind: String = "GetUpWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GetUpWidgetEntryView(entry: entry)
                .containerBackground(Color.white, for: .widget)
        }
    }
}

struct GetUpLockScreenWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack {
            Image(systemName: "sun.haze.fill") // Custom image
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text("\(Int(entry.completionPercentage*100))% Gotten Up") // Completion percentage text
        }
    }
}

struct GetUpLockScreenWidget: Widget {
    let kind: String = "GetUpLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GetUpLockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Progress Tracker")
        .description("Displays an image and a completion percentage.")
        .supportedFamilies([.accessoryInline]) // Lock Screen widget family
    }
}

//#Preview(as: .systemSmall) {
//    GetUpWidget()
//} timeline: {
//    SimpleEntry(date: .now, configuration: .smiley)
//    SimpleEntry(date: .now, configuration: .starEyes)
//}
