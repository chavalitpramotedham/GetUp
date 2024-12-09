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
    @State private var isDone: Bool
    
    @State private var titleHeight: CGFloat = 20
    
    @State private var otherParticipantDict: [String: String] = [:]
    
    var onEdit: () -> Void // Closure to trigger the edit
    var onCopy: () -> Void // Closure to trigger the edit
    
    var taskName: String
    var taskDescription: String
    var taskColorIndex: Int
    var taskDate: Date?
    var timerSet: Bool
    var participantsStatus: [String:Bool]
    var creatorID: String
    
    public init(taskManager: TaskManager, taskObject: TaskObject, onEdit: @escaping () -> Void, onCopy: @escaping () -> Void) {
        self.taskManager = taskManager
        self.taskObject = taskObject
        self.onEdit = onEdit // Initialize the onEdit property
        self.onCopy = onCopy // Initialize the onClose property
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
                HStack(alignment: .top,spacing: 10){
                    // Dynamic Rounded Rectangle for Task Color
                    RoundedRectangle(cornerRadius: 100)
                        .fill(colorDict[taskColorIndex] ?? Color.gray)
                        .frame(maxWidth: 15,maxHeight:.infinity)
                        .padding(.vertical,3)
                    
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
                                ZStack{
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10))
                                        .fontWeight(.bold)
                                        .foregroundColor(.black.opacity(0.75))
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 24,height:24)
                                }
                            }
                        )
                    }
                    
                    Button (
                        action: {
                            withAnimation {
                                onCopy()
                            }
                        },
                        label:{
                            ZStack{
                                Image(systemName: "plus.square.on.square")
                                    .font(.system(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black.opacity(0.75))
                                
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 24,height:24)
                            }
                            
                        }
                    )
                }
                .padding(0)
                
                Text(taskDescription != "" ? taskDescription : "No description")
                    .foregroundStyle(taskDescription != "" ? .black : .gray)
                    .font(.system(size: 14))
                    .fontWeight(.regular)
                    .lineLimit(1)
                
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
                    
                    Spacer()
                }
                .frame(height: 30)
                .frame(maxWidth:.infinity)
//                .frame(width: .infinity, height: 30)
            }
            .frame(maxWidth: .infinity)
            
//            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 25))
                .foregroundStyle(isDone ? .green : .gray.opacity(0.3))
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
        .frame(maxWidth: .infinity)
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
