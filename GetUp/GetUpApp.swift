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
var currentUserName = ""
var currentUserID = ""
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


class TaskObject: ObservableObject, Identifiable, Equatable{
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
    
    static func == (lhs: TaskObject, rhs: TaskObject) -> Bool {
        lhs.id == rhs.id &&
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


struct ContentView: View {
    var body: some View {
        NavigationStack {
            WelcomeView()
        }
    }
}

@main
struct GetUpApp: App {
    init() {
        FirebaseApp.configure()
    }
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
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


#Preview {
    ContentView()
}
