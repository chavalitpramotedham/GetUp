//
//  TaskCardView.swift
//  GetUp
//
//  Created by ByteDance on 14/11/24.
//

import SwiftUI

struct TaskCardView: View {
//    @Binding var taskObject: TaskObject
    @ObservedObject var taskObject: TaskObject
    @State private var isExpanded = false
    @State private var isDone: Bool
    
    var onEdit: () -> Void // Closure to trigger the edit
    
    public init(taskObject: TaskObject, onEdit: @escaping () -> Void) {
        self.taskObject = taskObject
        self.onEdit = onEdit // Initialize the onEdit property
        _isDone = State(initialValue: taskObject.isDone) // Initialize with the model's `isDone` value
    }
    
    var body: some View {
        
        let taskName: String = taskObject.name
        let taskDescription: String = taskObject.description
        let taskColorIndex: Int = taskObject.colorIndex
        let taskIndex: Int = taskObject.index
        let timer: String = taskObject.timer
        
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
                
                VStack(alignment:.leading, spacing:5){
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
                
                HStack(alignment: .center,spacing: 10){
                    Image(systemName: "timer")
                        .font(.system(size: 18))
                    Text(timer)
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
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
                taskObject.isDone.toggle() // Directly toggle taskObject's isDone
                isDone = taskObject.isDone
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
