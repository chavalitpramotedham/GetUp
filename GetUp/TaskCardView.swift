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
    
    var onEdit: () -> Void // Closure to trigger the edit
    
    public init(taskManager: TaskManager, taskObject: TaskObject, onEdit: @escaping () -> Void) {
        self.taskManager = taskManager
        self.taskObject = taskObject
        self.onEdit = onEdit // Initialize the onEdit property
        _isDone = State(initialValue: taskObject.participantsStatus[currentUserID] ?? false) // Initialize with the model's `isDone` value
    }
    
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
    }
}
