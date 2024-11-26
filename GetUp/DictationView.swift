//
//  DictationView.swift
//  GetUp
//
//  Created by ByteDance on 26/11/24.
//

import SwiftUI
import Speech
import AVFoundation

import Combine

var defaultTranscribedText = "Click to start dictation"

enum TaskAction {
    case edit
    case delete
}

var isMocking = false
var mockChatGPTResponseContent = "```json\n[\n    {\n        \"name\": \"Visit hospital\",\n        \"description\": \"Visit the hospital for a medical appointment.\",\n        \"taskDate\": \"2024-12-01T21:00:00+08:00\",\n        \"timerSet\": true,\n        \"colorIndex\": 0\n    },\n    {\n        \"name\": \"Go to gym\",\n        \"description\": \"Engage in a workout session at the gym.\",\n        \"taskDate\": \"2024-12-01T15:00:00+08:00\",\n        \"timerSet\": true,\n        \"colorIndex\": 2\n    },\n    {\n        \"name\": \"Do grocery shopping\",\n        \"description\": \"Purchase necessary groceries.\",\n        \"taskDate\": \"2024-12-01T15:00:00+08:00\",\n        \"timerSet\": true,\n        \"colorIndex\": 0\n    }\n]\n```"

class DictationManager: ObservableObject {
    @Published var transcribedText: String = defaultTranscribedText
    @Published var generatedTask: TaskObject? = nil
    @Published var isRecording: Bool = false
    
    @Published var selectedDate: Date? = nil // Store the selectedDate
    @Published var taskList: [TaskObject] = []
    @Published var editingTask: TaskObject? = nil // Task being edited
    
    private let chatGPTManager = ChatGPTManager()
    
    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isAuthorized: Bool = false

    func requestAuthorizationAndStartDictation() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.isAuthorized = true
                    self.startDictation()
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                    self.isAuthorized = false
                @unknown default:
                    fatalError()
                }
            }
        }
    }

    func startDictation() {
        guard isAuthorized else {
            print("Speech recognition is not authorized")
            return
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        isRecording = true
        transcribedText = "Listening..."

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
                self.stopDictation()
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, when in
            request.append(buffer)
        }
    }
    
    func stopDictation() {
        if audioEngine.isRunning {
            try? audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Reset recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Reset the audio engine
        audioEngine.reset()

        isRecording = false
    }

    func cancelDictation() {
        stopDictation()
        transcribedText = defaultTranscribedText
        generatedTask = nil
    }

    func generateResult() {
        guard let selectedDate = selectedDate else {
            print("Selected date is not set.")
            return
        }
        
        guard !transcribedText.isEmpty && transcribedText != defaultTranscribedText else {
            print("No valid text to generate results")
            return
        }
        
//        print("Transcribed Text: \(transcribedText)")
//        print("___________________________________________")
        
        chatGPTManager.convertTextToTaskObjects(text: transcribedText, selectedDate: selectedDate) { [weak self] taskObjects in
            DispatchQueue.main.async {
                guard let taskObjects = taskObjects else {
                    print("Failed to generate TaskObjects.")
                    return
                }
                
                // Append the new tasks to the task list
                self?.taskList.append(contentsOf: taskObjects)
                print("Generated TaskObjects: \(taskObjects)")
                
                taskObjects.forEach { $0.printFields() }
                self?.cancelDictation()
            }
        }
    }
    
    func deleteTask(_ task: TaskObject) {
        taskList.removeAll { $0.taskID == task.taskID }
    }

    func updateTask(_ updatedTask: TaskObject) {
        if let index = taskList.firstIndex(where: { $0.taskID == updatedTask.taskID }) {
            taskList[index] = updatedTask
        }
    }
}


class ChatGPTManager {
    private let apiKey = env.get("OPENAI_API_KEY")
    private let apiURL = "https://api.openai.com/v1/chat/completions"

    func convertTextToTaskObjects(text: String, selectedDate: Date, completion: @escaping ([TaskObject]?) -> Void) {
        
        if isMocking{
            let taskObject = self.parseTaskObjects(from: mockChatGPTResponseContent)
            completion(taskObject)
        }else {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Singapore") // GMT+8 timezone
            let formattedDate = dateFormatter.string(from: selectedDate)
            
            let headers = [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(apiKey)"
            ]

            let prompt = """
            Based on the following text, extract multiple tasks and return an array of JSON objects, each with the following fields:
            - "name": A summary of the task's main purpose or title. Keep within 3-5 words and make sure keywords are expressed.
            - "description": A detailed and coherent description of the task.
            - "taskDate": Always return in ISO 8601 format (e.g., "2024-11-26T00:00:00+08:00").
                - If no time is mentioned, set the time to the start of the selected date: \(formattedDate).
                - If a time is mentioned, use that time on the selected date: \(formattedDate).
                - Ensure all dates and times are explicitly marked in GMT+8 timezone.
            - "timerSet": If a time is mentioned (e.g., "6 PM"), set this to true; otherwise, set this to false.
            - "colorIndex": An integer corresponding to the task category, inferred from the task name and description using the following mapping:
                \(nameDict.map { "\($0.key): \"\($0.value)\"" }.joined(separator: ", "))
                - Example: If the task is about exercise (e.g., "Go to the gym"), return 2 (EXERCISE).
                - If the task does not clearly match any specific category, return 0 (GENERAL).

            The input text may describe multiple tasks separated by words like "then", "and", or time indicators (e.g., "at 10 AM, at 2 PM"). Split these into individual tasks.

            Input: "\(text)"
            """
            
//            print("Prompt: \(prompt)")
//            print("___________________________________________")

            let body: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": [
                    ["role": "system", "content": "You are a Swift developer assistant."],
                    ["role": "user", "content": prompt]
                ],
                "max_tokens": 300
            ]

            guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
                print("Failed to serialize JSON body.")
                completion(nil)
                return
            }

            var request = URLRequest(url: URL(string: apiURL)!)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = bodyData

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                    return
                }
                
//                // Debug the raw response
//                if let rawResponse = String(data: data, encoding: .utf8) {
//                    print("Raw API Response: \(rawResponse)")
//                    print("___________________________________________")
//                }

                do {
                    let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                    if let content = result.choices.first?.message.content {
                        // Parse the JSON response into a TaskObject
                        let taskObjects = self.parseTaskObjects(from: content)
                        completion(taskObjects)
                    } else {
                        completion(nil)
                    }
                } catch {
                    print("Failed to decode response: \(error.localizedDescription)")
                    completion(nil)
                }
            }.resume()
        }
    }
    
    private func parseTaskObjects(from response: String) -> [TaskObject] {
        let dateFormatter = DateFormatter()
        
//        print("Parsing String: \(response)")
//        print("___________________________________________")
        
        let cleanResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
//        print("Cleaned String: \(cleanResponse)")
//        print("___________________________________________")
        
        guard let data = cleanResponse.data(using: .utf8) else {
            print("Failed to convert response to Data.")
            return []
        }

        do {
            // Decode JSON into an array of TaskInference
            let inferences = try JSONDecoder().decode([TaskInference].self, from: data)
            
            return inferences.compactMap { inference in
                let taskDate: Date? = {
                    if let taskDateString = inference.taskDate {
                        return parseTaskDate(taskDateString: taskDateString)
                    }
                    return nil
                }()
                
                return TaskObject(
                    name: inference.name,
                    description: inference.description,
                    colorIndex: inference.colorIndex,
                    taskDate: taskDate,
                    timerSet: inference.timerSet
                )
            }
        } catch let error as DecodingError {
            // Handle specific decoding errors
            switch error {
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type mismatch: \(type), \(context.debugDescription)")
            case .valueNotFound(let value, let context):
                print("Value '\(value)' not found: \(context.debugDescription)")
            default:
                print("Decoding error: \(error.localizedDescription)")
            }
            return []
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseTaskDate(taskDateString: String?) -> Date? {
        guard let taskDateString = taskDateString else { return nil }
        
        let iso8601Formatter = ISO8601DateFormatter()
        return iso8601Formatter.date(from: taskDateString)
    }
}

struct TaskInference: Codable {
    let name: String
    let description: String
    let taskDate: String? // Use `String` to parse ISO 8601 format, handle conversion to `Date`
    let timerSet: Bool
    let colorIndex: Int
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}


struct DictationView: View {
    let selectedDate: Date
    @StateObject private var dictationManager = DictationManager()
    var onSave: ([TaskObject]) -> Void // Closure to pass tasks back
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showPopup = false // Controls popup visibility
    @State private var taskID = ""
    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var taskDate: Date? = nil
    @State private var timerSet = false
    @State private var selectedColor = 0
    @State private var participantsStatus: [String: Bool] = [:]
        
    var body: some View {
        VStack{
            ZStack{
                VStack (alignment:.center,spacing:20) {
                    
                    dictationTextBox
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(dictationManager.taskList) { task in
                                TemporaryTaskCardView(taskObject: task) { action in
                                    handleTaskAction(action: action, task: task)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth:.infinity,maxHeight: .infinity)
                    .background(Color.gray.opacity(0.25))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .shadow(color: Color.black.opacity(10), radius: 5, x: 0, y: -1) // Inner shadow effect
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    )
                }
                .onAppear{
                    dictationManager.requestAuthorizationAndStartDictation()
                }
                .blur(radius: showPopup ? 3 : 0)
                
                if showPopup {
                    NewTaskPopupView(
                        showPopup: $showPopup,
                        newTaskName: $taskName,
                        newTaskDescription: $taskDescription,
                        newTaskDate: $taskDate,
                        timerSet: $timerSet,
                        selectedColor: $selectedColor,
                        participantsStatus: $participantsStatus,
                        selectedDate: taskDate ?? Date(),
                        isEditing: dictationManager.editingTask != nil,
                        onSave: saveTask,
                        onCancel: cancelEdit,
                        onDelete: deleteTask
                    )
                    .frame(maxHeight:375)
                }
            }
        }
        .padding([.leading, .trailing], 20)
        .padding([.top], 10)
        .padding([.bottom], 40)
        .frame(maxWidth: screenWidth, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                dictationManager.cancelDictation()
                dismissView()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                    Text("Back")
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                }
            },
            trailing: Button(action: saveAndDismiss) {
                Text("Save (\(dictationManager.taskList.count))")
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            }
                .disabled(dictationManager.taskList.isEmpty)
                .opacity(dictationManager.taskList.isEmpty ? 0.3 : 1)
        )
        .onAppear {
            dictationManager.selectedDate = selectedDate // Pass the selectedDate to the manager
        }
    }
    
    private var dictationTextBox: some View {
        VStack(alignment:.leading){
            Text(dictationManager.transcribedText)
                .foregroundStyle(dictationManager.isRecording ? .black: .gray)
                .padding(10)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            HStack(alignment: .center, spacing: 10){
                if dictationManager.isRecording{
                    // Cancel Button
                    Button(action: {
                        withAnimation {
                            dictationManager.cancelDictation()
                        }
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .frame(height: 20)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray)
                        )
                    }
                    
                    Button(action: {
                        withAnimation{
                            dictationManager.generateResult()
                        }
                    }) {
                        HStack{
                            Image(systemName: "lightbulb") // Microphone icon
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            Text("Generate Tasks")
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                        .frame(height: 20)
                        .padding()
                        .frame(maxWidth:.infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black)
                        )
                    }
                } else{
                    Button(action: {
                        withAnimation{
                            dictationManager.requestAuthorizationAndStartDictation()
                        }
                    }) {
                        HStack{
                            Image(systemName: "mic.fill") // Microphone icon
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("Start Dictation")
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .frame(height: 20)
                        .padding()
                        .frame(maxWidth:.infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black)
                        )
                    }
                }
            }
            
            
//                .padding()
        }
        .padding()
        .frame(maxWidth:.infinity,maxHeight: screenHeight/4)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }
    
    func handleTaskAction(action: TaskAction, task: TaskObject) {
        switch action {
        case .delete:
            dictationManager.deleteTask(task)
        case .edit:
            populatePopupFields(for: task)
        }
    }
    
    func populatePopupFields(for task: TaskObject) {
        taskID = task.taskID
        taskName = task.name
        taskDescription = task.description
        taskDate = task.taskDate
        timerSet = task.timerSet
        selectedColor = task.colorIndex
        participantsStatus = task.participantsStatus
        
        dictationManager.editingTask = task
        showPopup = true
    }
    
    func saveTask() {
        guard !taskName.isEmpty else { return }
        let updatedTask = TaskObject(
            taskID: dictationManager.editingTask?.taskID ?? "",
            name: taskName,
            description: taskDescription,
            colorIndex: selectedColor,
            taskDate: taskDate,
            timerSet: timerSet,
            participantsStatus: participantsStatus
        )
        
        if let editingTask = dictationManager.editingTask {
            dictationManager.updateTask(updatedTask) // Update existing task
        } else {
            dictationManager.taskList.append(updatedTask) // Add new task
        }
        dictationManager.editingTask = nil
        showPopup = false // Close popup
    }
    
    func deleteTask() {
        if let editingTask = dictationManager.editingTask {
            dictationManager.deleteTask(editingTask) // Delete task
        }
        dictationManager.editingTask = nil
        showPopup = false // Close popup
    }

    func cancelEdit() {
        dictationManager.editingTask = nil
    }
    
    private func saveAndDismiss() {
        onSave(dictationManager.taskList) // Pass the generated tasks back
        dismissView()
    }

    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct TemporaryTaskCardView: View {
    @ObservedObject var taskObject: TaskObject
    @State private var isExpanded = false
    
    var onTaskAction: (TaskAction) -> Void
    
    var body: some View {
        
        let taskName: String = taskObject.name
        let taskDescription: String = taskObject.description
        let taskColorIndex: Int = taskObject.colorIndex
        let taskDate: Date? = taskObject.taskDate ?? nil
        let timerSet: Bool = taskObject.timerSet
        let participantsStatus = taskObject.participantsStatus
        let creatorID = taskObject.creatorID
        
        var otherParticipantDict: [String: String] {
            let uids = getOtherUIDs(from: participantsStatus)
            var dict: [String: String] = [:]
            for uid in uids {
                dict[uid] = getOtherUsername(from: uid)
            }
            return dict
        }
        
        HStack (alignment: .center,spacing: 20){
            VStack(alignment: .leading,spacing:10){
                HStack(alignment: .center,spacing: 10){
                    
                    ZStack{ }
                    .frame(width: 18, height: 18)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorDict[taskColorIndex] ?? Color.gray)
                    )
                    
                    Text(taskName)
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .lineLimit(2)
                }
                
                VStack(alignment:.leading, spacing:10){
                    Text(taskDescription == "" ? "No description":taskDescription)
                        .font(.system(size: 14))
                        .fontWeight(.regular)
                        .lineLimit(isExpanded ? nil : 1) // No limit if expanded, 1 line if collapsed
                        .animation(.easeInOut, value: isExpanded)
                    
                    Button(action: {
                        isExpanded.toggle() // Toggle the expanded state
                    }) {
                        Text(isExpanded ? "See Less" : "See More")
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(alignment: .center,spacing: 20){
                    HStack(alignment: .center,spacing:10){
                        Image(systemName: "timer")
                            .font(.system(size: 16))
                            .foregroundStyle(.black.opacity(0.75))
                    
                        Text(timerSet ? formatDateTo24HourTime(date:taskDate) : "-")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(.black.opacity(0.75))
                    }
                    HStack{
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.black.opacity(0.75))
                        
                        if otherParticipantDict.count >= 1 {
                            
                            if otherParticipantDict.count >= 2 {
                                Text("\(otherParticipantDict.first.map { $0.value } ?? "Unknown"))  +\(otherParticipantDict.count - 1)")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.black.opacity(0.75))
                                
                                // Insert view all progress sheet (future work)
                                
                            } else{
                                HStack(spacing:5){
                                    Text((otherParticipantDict.first.map { $0.value } ?? "Unknown"))
                                        .font(.system(size: 16))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.black.opacity(0.75))
                                    
                                    if let firstKey = otherParticipantDict.keys.first {
                                        let checkMarkColor = participantsStatus[firstKey] == true ? Color.green : Color.gray.opacity(0.3)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(checkMarkColor)
                                    }
                                }
                            }
                            
                        } else{
                            Text("-")
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                                .foregroundStyle(.black.opacity(0.75))
                        }
                        
                    }
                }
                .frame(width: .infinity, height: 30)
            }
            
            Spacer()
            
            VStack(alignment: .center){
                Button (
                    action: {
                        withAnimation {
                            onTaskAction(.edit)
                        }
                    },
                    label:{
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            
                    }
                )
                .frame(width:40)
                .frame(maxHeight:.infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray)
                )
                
                Button (
                    action: {
                        withAnimation {
                            onTaskAction(.delete)
                        }
                    },
                    label:{
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            
                    }
                )
                .frame(width:40)
                .frame(maxHeight:.infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.red)
                )
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

//#Preview {
//    DictationView()
//}
