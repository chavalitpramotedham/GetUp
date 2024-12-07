//
//  TaskCardView.swift
//  GetUp
//
//  Created by ByteDance on 14/11/24.
//

import SwiftUI
import Foundation

struct TaskCardView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var taskObject: TaskObject
    @State private var isExpanded = false
    @State private var isDone: Bool
    
    @State private var otherParticipantDict: [String: String] = [:]
    
    var onEdit: () -> Void // Closure to trigger the edit
    
    var taskName: String
    var taskDescription: String
    var taskColorIndex: Int
    var taskDate: Date?
    var timerSet: Bool
    var participantsStatus: [String:Bool]
    var creatorID: String
    
    public init(taskManager: TaskManager, taskObject: TaskObject, onEdit: @escaping () -> Void) {
        self.taskManager = taskManager
        self.taskObject = taskObject
        self.onEdit = onEdit // Initialize the onEdit property
        _isDone = State(initialValue: taskObject.participantsStatus[currentUserID] ?? false) // Initialize with the model's `isDone` value
        
        taskName = taskObject.name
        taskDescription = taskObject.description
        taskColorIndex = taskObject.colorIndex
        taskDate = taskObject.taskDate ?? nil
        timerSet = taskObject.timerSet
        participantsStatus = taskObject.participantsStatus
        creatorID = taskObject.creatorID
    }
    
    var body: some View {
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
                    
                    if (creatorID == currentUserID){
                        Button (
                            action: {
                                withAnimation {
                                    onEdit()
                                }
                            },
                            label:{
                                Image(systemName: "pencil")
                                    .font(.system(size: 15))
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                        )
                    }
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
                                Text("\(otherParticipantDict.count) others")
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
            
            HStack(alignment: .center){
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 25))
                    .foregroundStyle(isDone ? .green : .gray.opacity(0.3))
            }
            .frame(maxHeight: .infinity)
            .onTapGesture {
                taskObject.participantsStatus[currentUserID]?.toggle() // Directly toggle taskObject's isDone
                isDone = taskObject.participantsStatus[currentUserID] ?? false
                
                taskManager.updateTaskToDB(taskObject)
                triggerHapticFeedback()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            updateOtherParticipantDict()
        }
    }
    
    private func updateOtherParticipantDict() {
        getOtherParticipantDict { updatedDict in
            DispatchQueue.main.async {
                withAnimation { // Wrap the state update in an animation block
                    otherParticipantDict = updatedDict
                }
            }
        }
    }
    
    private func getOtherParticipantDict(completion: @escaping ([String: String]) -> Void) {
        let uids = getOtherUIDs(from: participantsStatus)
        var dict: [String: String] = [:]
        let group = DispatchGroup() // Use DispatchGroup to wait for all tasks

        for uid in uids {
            group.enter() // Enter the group for each async task
            Task {
                do {
                    let username = try await getOtherUsername(from: uid)
                    dict[uid] = username
                } catch {
                    print("Failed to fetch username for UID \(uid): \(error.localizedDescription)")
                    dict[uid] = "Unknown" // Fallback value
                }
                group.leave() // Leave the group when the task is complete
            }
        }

        group.notify(queue: .main) {
            completion(dict) // Call completion with the updated dictionary
        }
    }
}
