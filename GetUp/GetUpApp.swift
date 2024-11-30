//
//  GetUpApp.swift
//  GetUp
//
//  Created by ByteDance on 13/11/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage
import UserNotifications
import WidgetKit

import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    var isConnected: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            print("Network connectivity: \(self.isConnected ? "Connected" : "Disconnected")")
        }
        monitor.start(queue: queue)
    }
}

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

var currentDeviceID: String {
    UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
}

var currentUserID: String = "unknown"
var currentUserName: String = "unknown"
var currentUserImageURL: String = ""
var currentUserConnections: [String] = []

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
    private var rawTaskList: [TaskObject] = []
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

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification received in foreground: \(notification.request.content.userInfo)")
        // Show banner, play sound, and set badge
        completionHandler([.banner, .sound, .badge])
    }

    // Handle when the user interacts with a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification interaction: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
}

// Call fetchAndSaveFCMToken in the AppDelegate when the APNs token is received
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass the APNs token to Firebase
        Messaging.messaging().apnsToken = deviceToken

        // Log the APNs token for debugging
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Device Token: \(tokenString)")

        // Now fetch and save the FCM token
        fetchAndSaveFCMToken()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    private func fetchAndSaveFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
            } else if let token = token {
                print("FCM Token: \(token)")
                // Save the FCM token to Firestore or your backend
                let userID = currentUserID // Replace with your logic to get the user ID
                Firestore.firestore().collection("users").document(userID).setData(["fcmToken": token], merge: true)
            }
        }
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

class UserSession {
    static let shared = UserSession()
    private let queue = DispatchQueue(label: "com.getup.userSession", attributes: .concurrent)

    private var _deviceLinkedUIDs: [String] = []

    var deviceLinkedUIDs: [String] {
        get { queue.sync { _deviceLinkedUIDs } }
        set { queue.async(flags: .barrier) { self._deviceLinkedUIDs = newValue } }
    }
}

class AppState: ObservableObject {
    @Published var isInitialized = false

    func initialize() async {
        await Self.fetchInitialData()
        DispatchQueue.main.async {
            self.isInitialized = true
        }
    }

    private static func fetchInitialData() async {
        await withCheckedContinuation { continuation in
            getLastLinkedUserAndUIDs {
                continuation.resume()
            }
        }
    }
}

@main
struct GetUpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var appState = AppState()
    
    init() {
        FirebaseApp.configure()
        configureNotificationPermissions() // Request permissions and set up notifications
        
        print(currentDeviceID)
    }
    
    var body: some Scene {
        WindowGroup {
            
            if appState.isInitialized {
                ContentView()
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .active {
                            // Trigger widget refresh when app enters the foreground
                            WidgetCenter.shared.reloadTimelines(ofKind: "GetUpWidget")
                            WidgetCenter.shared.reloadTimelines(ofKind: "GetUpLockScreenWidget")
                            print("Widget refreshed on app enter")
                        } else if newPhase == .background {
                            // Trigger widget refresh when app enters the background
                            WidgetCenter.shared.reloadTimelines(ofKind: "GetUpWidget")
                            WidgetCenter.shared.reloadTimelines(ofKind: "GetUpLockScreenWidget")
                            print("Widget refreshed on app exit")
                        }
                    }
            } else {
                ProgressView("Initializing...")
                    .onAppear {
                        Task {
                            await appState.initialize()
                        }
                    }
            }
        }
    }
    
    // Function to configure notifications
    private func configureNotificationPermissions() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge] // Include sound explicitly
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else if granted {
                print("Notification permissions granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permissions denied")
            }
        }

        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate()
    }
}

extension GetUpApp {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert device token to a string
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Device Token: \(token)")

        // Pass the device token to Firebase
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

func getLastLinkedUserAndUIDs(completion: @escaping () -> Void){

    let deviceRef = Firestore.firestore().collection("deviceToUsers").document(currentDeviceID)
    
    if FirebaseApp.app() != nil {
        print("Firebase is configured!")
    } else {
        print("Firebase is not configured.")
    }
    
    if NetworkMonitor.shared.isConnected {
        print("Internet is available")
    } else {
        print("No internet connection")
    }

    deviceRef.getDocument { document, error in
        if let error = error {
            print("Error fetching device document: \(error.localizedDescription)")
            completion() // Always call the completion handler
            return
        }
        
        guard let document = document, document.exists else {
            print("Device document does not exist. Initialize entry")
            
            // Write default fields to Firestore
            deviceRef.setData([
                "lastLinkedUID": "",
                "linkedUIDs": []
            ]) { error in
                if let error = error {
                    print("Error writing default fields: \(error.localizedDescription)")
                } else {
                    print("Default fields successfully written to Firestore.")
                }
                completion() // Call completion after handling the write operation
            }
            return
        }

        // Parse the data
        let data = document.data()
        let lastLinkedUID = data?["lastLinkedUID"] as? String ?? ""
        UserSession.shared.deviceLinkedUIDs = data?["linkedUIDs"] as? [String] ?? []

        print("Retrieved lastLinkedUID: \(lastLinkedUID)")
        print("Retrieved linkedUIDs: \(UserSession.shared.deviceLinkedUIDs)")

        // Now fetch the user data based on this UID
        // Fetch the user data based on lastLinkedUID
        if !lastLinkedUID.isEmpty && lastLinkedUID != ""{
            Task {
                do {
                    try await setUserData(lastLinkedUID)
                } catch {
                    print("Failed to set user data for lastLinkedUID \(lastLinkedUID): \(error.localizedDescription)")
                }
            }
        } else {
            print("No lastLinkedUID found.")
        }
        
        completion()
    }
}

func getOtherLinkedUIDs() -> [String] {
    var otherLinkedUIDs = UserSession.shared.deviceLinkedUIDs
    if let index = otherLinkedUIDs.firstIndex(of: currentUserID) {
        otherLinkedUIDs.remove(at: index)
    }
    return otherLinkedUIDs
}


func setUserData(_ uid: String) async throws {
    do {
        let data = try await fetchUserData(from: uid)

        // Assign values to your variables
        currentUserID = uid
        currentUserName = data["userName"] as? String ?? ""
        currentUserImageURL = data["userImageURL"] as? String ?? ""
        currentUserConnections = data["userConnections"] as? [String] ?? []

        // Optional: Print to verify
        print("User Data:")
        print("ID: \(currentUserID)")
        print("Name: \(currentUserName)")
        print("Image URL: \(currentUserImageURL)")
        print("Connections: \(currentUserConnections)")
    } catch {
        print("Error fetching user data: \(error.localizedDescription)")
        throw error // Rethrow the error if necessary
    }
}

func triggerHapticFeedback() {
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    impactFeedbackGenerator.prepare()
    impactFeedbackGenerator.impactOccurred()
}

func setUID(_ uid: String) {
    currentUserID = uid
    
    Task {
        do {
            try await setUserData(uid)
        } catch {
            print("Failed to set user data: \(error.localizedDescription)")
        }
    }

    // Fetch the FCM token
    Messaging.messaging().token { token, error in
        if let error = error {
            print("Error fetching FCM token: \(error.localizedDescription)")
        } else if let token = token {
            print("Fetched FCM Token: \(token)")

            // Write the uid:fcm pair to Firestore
            let userRef = Firestore.firestore().collection("users").document(uid)
            userRef.setData(["fcmToken": token], merge: true) { error in
                if let error = error {
                    print("Error writing FCM token to Firestore: \(error.localizedDescription)")
                } else {
                    print("Successfully wrote FCM token to Firestore for uid: \(uid)")
                }
            }
        } else {
            print("FCM token not available.")
        }
    }
    
    // Write the most recently linked UID to deviceToUsers
    let deviceRef = Firestore.firestore().collection("deviceToUsers").document(currentDeviceID)
    
    // Fetch current linkedUIDs and update them
    deviceRef.getDocument { snapshot, error in
        if let error = error {
            print("Error fetching deviceToUsers document: \(error.localizedDescription)")
        } else {
            UserSession.shared.deviceLinkedUIDs = snapshot?.data()?["linkedUIDs"] as? [String] ?? []
            
            if !UserSession.shared.deviceLinkedUIDs.contains(uid) {
                UserSession.shared.deviceLinkedUIDs.append(uid)
                
                deviceRef.setData(["linkedUIDs": UserSession.shared.deviceLinkedUIDs], merge: true) { error in
                    if let error = error {
                        print("Error writing linkedUIDs to Firestore: \(error.localizedDescription)")
                    } else {
                        print("Successfully updated linkedUIDs for DeviceID: \(currentDeviceID)")
                    }
                }
            } else {
                print("UID \(uid) is already in linkedUIDs.")
            }
            
            deviceRef.setData(["lastLinkedUID": uid], merge: true) { error in
                if let error = error {
                    print("Error writing LastLinkedUID to Firestore: \(error.localizedDescription)")
                } else {
                    print("Successfully wrote LastLinkedUID to Firestore for DeviceID: \(currentDeviceID)")
                }
            }
        }
    }
    
    
    deviceRef.setData(["lastLinkedUID": uid], merge: true) { error in
        if let error = error {
            print("Error writing LastLinkedUID to Firestore: \(error.localizedDescription)")
        } else {
            print("Successfully wrote LastLinkedUID to Firestore for DeviceID: \(currentDeviceID)")
        }
    }
    
    fetchUserImageURL(uid: uid) { result in
        switch result {
        case .success(let url):
            print("Image URL: \(url)")
            // Save this URL to Firestore for the user
        case .failure(let error):
            print("Error fetching URL: \(error.localizedDescription)")
        }
    }
}

func fetchUserImageURL(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
    let storageRef = Storage.storage().reference()
    let imageRef = storageRef.child("userImages/\(uid).jpg")

    imageRef.downloadURL { url, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        if let downloadURL = url?.absoluteString {
            completion(.success(downloadURL))
        }
    }
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
    
    // Sort tasks in each date bucket
    for key in taskListsByDate.keys {
        taskListsByDate[key]?.sort { task1, task2 in
            // Sorting logic:
            // 1. Tasks with `timerSet == true` come first
            // 2. Among tasks with `timerSet == true`, sort by `taskDate` (earlier -> later)
            // 3. Tasks with `timerSet == false` come after
            if task1.timerSet && !task2.timerSet {
                return true
            } else if !task1.timerSet && task2.timerSet {
                return false
            } else {
                return task1.taskDate ?? Date.distantPast < task2.taskDate ?? Date.distantPast
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

func getOtherUsername(from uid: String) async throws -> String {
    let data = try await fetchUserData(from: uid)
    return data["userName"] as? String ?? ""
}

func fetchUserData(from uid: String) async throws -> [String: Any] {
    let userRef = Firestore.firestore().collection("users").document(uid)

    do {
        let document = try await userRef.getDocument()
        if let data = document.data() {
            return data // Return the document data
        } else {
            throw NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document does not exist or has no data."])
        }
    } catch {
        throw error // Propagate the error
    }
}

#Preview {
    ContentView()
}
