//
//  GetUpApp.swift
//  GetUp
//
//  Created by ByteDance on 13/11/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

// Static variables

let startingScreenIndex = 0
let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

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

/// USER Variables:
var currentUserID = "987"
var currentUserName = "Default"
var connectionsList: [String] = []

//var currentUserID = "123"
//var currentUserName = "Chava"
//var connectionsList: [String] = ["456"]

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

let env = EnvReader()

var numPastFutureDates: Int = 90


class TaskObject: ObservableObject, Identifiable, Equatable, Decodable{
    @Published var taskID: String
    @Published var name: String
    @Published var description: String
    @Published var colorIndex: Int
    
    @Published var taskDate : Date?
    @Published var timerSet : Bool
    @Published var creatorID: String
    @Published var participantsStatus : [String:Bool]{
        didSet {
            objectWillChange.send() // Notify listeners
        }
    }

    init(taskID: String = "\(UIDevice.current.identifierForVendor?.uuidString ?? "unknown")-\(UUID().uuidString)", name: String = "Task", description: String = "Description", colorIndex: Int = 0,isDone: Bool = false, taskDate: Date? = Date(), timerSet: Bool = false, creatorID: String = currentUserID, participantsStatus: [String:Bool] = [currentUserID:false]) {
        self.taskID = taskID
        self.name = name
        self.description = description
        self.colorIndex = colorIndex
        self.taskDate = taskDate ?? nil
        self.timerSet = timerSet
        self.creatorID = creatorID
        self.participantsStatus = participantsStatus
    }
    
    // Conformance to Decodable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode each property
        self.taskID = try container.decode(String.self, forKey: .taskID)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.colorIndex = try container.decode(Int.self, forKey: .colorIndex)
        self.timerSet = try container.decode(Bool.self, forKey: .timerSet)
        self.creatorID = try container.decode(String.self, forKey: .creatorID)
        self.participantsStatus = try container.decode([String: Bool].self, forKey: .participantsStatus)

        // Decode `taskDate` safely (as it’s optional)
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .taskDate) {
            self.taskDate = timestamp.dateValue() // Convert Firebase Timestamp to Date
        } else if let date = try? container.decodeIfPresent(Date.self, forKey: .taskDate) {
            self.taskDate = date
        } else {
            self.taskDate = nil
        }
    }

    // Keys for Coding
    enum CodingKeys: String, CodingKey {
        case taskID
        case name
        case description
        case colorIndex
        case taskDate
        case timerSet
        case creatorID
        case participantsStatus
    }
    
    static func == (lhs: TaskObject, rhs: TaskObject) -> Bool {
//        lhs.id == rhs.id &&
        lhs.taskID == rhs.taskID &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.colorIndex == rhs.colorIndex &&
        lhs.taskDate == rhs.taskDate &&
        lhs.timerSet == rhs.timerSet &&
        lhs.creatorID == rhs.creatorID &&
        lhs.participantsStatus == rhs.participantsStatus
    }
    
    // Convert to Dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "taskID": taskID,
            "name": name,
            "description": description,
            "colorIndex": colorIndex,
            "timerSet": timerSet,
            "creatorID": creatorID,
            "participantsStatus": participantsStatus
        ]

        // Convert taskDate to Firestore Timestamp if it exists
        if let date = taskDate {
            dictionary["taskDate"] = Timestamp(date: date)
        }

        return dictionary
    }
    
    // Initialize from Firestore Document
    convenience init?(from document: [String: Any]) {
        guard
            let taskID = document["taskID"] as? String,
            let name = document["name"] as? String,
            let description = document["description"] as? String,
            let colorIndex = document["colorIndex"] as? Int,
            let timerSet = document["timerSet"] as? Bool,
            let creatorID = document["creatorID"] as? String,
            let participantsStatus = document["participantsStatus"] as? [String: Bool]
        else {
            return nil // Return nil if required fields are missing
        }

        let taskDate: Date? = (document["taskDate"] as? Timestamp)?.dateValue()

        self.init(
            taskID: taskID,
            name: name,
            description: description,
            colorIndex: colorIndex,
            taskDate: taskDate,
            timerSet: timerSet,
            creatorID: creatorID,
            participantsStatus: participantsStatus
        )
    }
    
    func printFields() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        print("Task Details:")
        print("Task ID: \(taskID)")
        print("Name: \(name)")
        print("Description: \(description)")
        print("Color Index: \(colorIndex)")
        print("Task Date: \(taskDate != nil ? dateFormatter.string(from: taskDate!) : "No date set")")
        print("Timer Set: \(timerSet ? "Yes" : "No")")
        print("Creator ID: \(creatorID)")
        print("Participants Status: \(participantsStatus.map { "\($0.key): \($0.value ? "Done" : "Pending")" }.joined(separator: ", "))")
    }
}

class FirestoreManager {
    private let db = Firestore.firestore() // Firestore instance

    // Save TaskObject to Firestore
    func saveTask(_ task: TaskObject, completion: @escaping (Error?) -> Void) {
        let taskData = task.toDictionary()
        db.collection("tasks").document(task.taskID).setData(taskData) { error in
            completion(error) // Call the completion handler with the result
        }
    }

    // Update specific fields in an existing task
    func updateTask(_ task: TaskObject, completion: @escaping (Error?) -> Void) {
        let taskData = task.toDictionary() // Convert the TaskObject to a dictionary
        db.collection("tasks").document(task.taskID).setData(taskData, merge: true) { error in
            completion(error) // Pass any errors to the completion handler
        }
    }

    // Delete a TaskObject from Firestore
    func deleteTask(_ task: TaskObject, completion: @escaping (Error?) -> Void) {
        db.collection("tasks").document(task.taskID).delete { error in
            completion(error) // Pass any errors to the completion handler
        }
    }

    // Fetch all tasks
    func fetchTasks(completion: @escaping ([TaskObject]?, Error?) -> Void) {
        db.collection("tasks").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error) // Return error if fetching fails
                return
            }

            // Parse documents into TaskObject instances
            let tasks = snapshot?.documents.compactMap { doc in
                TaskObject(from: doc.data())
            }
            completion(tasks, nil)
        }
    }

    // Fetch a specific task by ID
    func fetchTask(byID taskID: String, completion: @escaping (TaskObject?, Error?) -> Void) {
        db.collection("tasks").document(taskID).getDocument { document, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let documentData = document?.data(),
                  let task = TaskObject(from: documentData) else {
                completion(nil, nil) // Return nil if task not found
                return
            }

            completion(task, nil)
        }
    }
}



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
    
    func saveMultipleTasksToDB(_ tasks: [TaskObject]) {
        for task in tasks{
            firestoreManager.saveTask(task) { error in
                if let error = error {
                    print("Error saving task: \(error.localizedDescription)")
                } else {
                    print("Task successfully saved!")
                }
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

class EnvReader {
    private var variables: [String: String] = [:]

    init(fileName: String = ".env") {
        print("Initializing EnvReader")
        if let filePath = Bundle.main.path(forResource: fileName, ofType: nil) {
            print("File path: \(filePath)")
            do {
                let contents = try String(contentsOfFile: filePath, encoding: .utf8)
                parseEnv(contents)
            } catch {
                print("Error reading .env file: \(error)")
            }
        } else {
            print(".env file not found in the bundle.")
        }
    }

    private func parseEnv(_ contents: String) {
        
        print("Parsing")
        let lines = contents.split(separator: "\n")
        for line in lines {
            // Ignore comments and empty lines
            guard !line.starts(with: "#"), !line.trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }
            // Split the line into key-value pairs
            let keyValue = line.split(separator: "=", maxSplits: 1)
            if keyValue.count == 2 {
                let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
                let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)
                variables[key] = value
            }
        }
    }

    func get(_ key: String, default defaultValue: String = "") -> String {
        return variables[key] ?? defaultValue
    }
}


struct ContentView: View {
    @StateObject private var taskManager: TaskManager
    
    init(){
        let manager = TaskManager()
        _taskManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        NavigationStack {
            WelcomeView(taskManager: taskManager)
        }
    }
}

@main
struct GetUpApp: App {
    
    
    init() {
        FirebaseApp.configure()
        print(env.get("OPENAI_API_KEY") ?? "API_KEY not found")
    }
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
//            DictationView()
            ContentView()
        }
    }
}

func triggerHapticFeedback() {
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    impactFeedbackGenerator.prepare()
    impactFeedbackGenerator.impactOccurred()
}

func setUID(_ uid:String){
    currentUserID = uid
    currentUserName = userDB[currentUserID]?["userName"]?[0] ?? ""
    connectionsList = userDB[currentUserID]?["connections"] ?? []
}

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

#Preview {
    ContentView()
}
