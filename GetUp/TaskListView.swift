//
//  TaskListView.swift
//  GetUp
//
//  Created by ByteDance on 14/11/24.
//

import SwiftUI

struct TaskListView: View {
    @Binding var taskList: [TaskObject]
    @ObservedObject var taskManager: TaskManager
    var selectedDate: Date
    @State private var selectedTab: Tab = .all
    
    @State private var showPopup: Bool = false
    @State private var isEditingTask: Bool = true
    @State private var editingTask: TaskObject? = nil
    
    @State private var newTaskName: String = ""
    @State private var newTaskDescription: String = ""
    @State private var newTaskTimer: Date? = nil
    @State private var newTaskSelectedColor: Int = 0

    enum Tab {
        case all, left
    }
    
    private var remainingTaskList: [TaskObject] {
        taskList.filter { !$0.isDone } // Assuming `isDone = false` means "left"
    }
    
    var body: some View {
        ZStack{
            VStack(alignment:.center,spacing:10){
                HStack(alignment: .center, spacing:10){
                    TabSelector(selectedTab: $selectedTab)
                    
                    Button (
                        action: {
                            withAnimation {
                                showPopup = true
                                isEditingTask = false
                            }
                        },
                        label:{
                            Image(systemName: "plus")
                                .font(.system(size: 18))
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                                .padding(15)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black)
                                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                                )
                        }
                    )
                }
                .frame(maxWidth:.infinity, maxHeight:50)
                
                
                ScrollView {
                    VStack(spacing: 10) {
                        taskListForSelectedTab
                    }
                }
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .shadow(color: Color.black.opacity(10), radius: 5, x: 0, y: -1) // Inner shadow effect
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            )
        }
        .blur(radius: showPopup ? 3 : 0)
            
//        // Popup Overlay
        if showPopup {
            Color.black.opacity(0.4)
                .ignoresSafeArea() // Dimmed background
            
            NewTaskPopupView(showPopup: $showPopup,
                                             newTaskName: $newTaskName,
                                             newTaskDescription: $newTaskDescription,
                                             selectedTime: $newTaskTimer,
                             selectedColor: $newTaskSelectedColor,
                             isEditing: isEditingTask
            ){
                // onSave closure to add the new task
                withAnimation {
                    if isEditingTask, let editingTask = editingTask {
                        // Update existing task
                        editingTask.name = newTaskName
                        editingTask.description = newTaskDescription
                        editingTask.timer = DateTimeToString(from: newTaskTimer)
                        editingTask.colorIndex = newTaskSelectedColor
                    } else {
                        // Add a new task
                        let newTask = TaskObject(
                            index: taskList.count,
                            name: newTaskName,
                            description: newTaskDescription,
                            colorIndex: newTaskSelectedColor,
                            isDone: false,
                            timer: DateTimeToString(from: newTaskTimer)
                        )
                        taskList.append(newTask)
                    }
                }
                
                // Reset popup fields and states
                resetPopupFields()
            } onCancel: {
                // onCancel: Dismiss the popup and reset fields without saving
                resetPopupFields()
            } onDelete: {
                // onDelete: Remove the task if it exists
                if let editingTask = editingTask {
                    if let index = taskList.firstIndex(of: editingTask) {
                        taskList.remove(at: index)
                    }
                }
                resetPopupFields()
            }
            .frame(maxWidth:.infinity, maxHeight:.infinity)
            
        }
    }
    
    private func resetPopupFields() {
        newTaskName = ""
        newTaskDescription = ""
        newTaskTimer = nil
        newTaskSelectedColor = 0
        editingTask = nil
        isEditingTask = false
    }
    
    // Function to handle editing a task
    private func onEdit(_ task: TaskObject) {
        newTaskName = task.name
        newTaskDescription = task.description
        newTaskTimer = dateFromString(task.timer)
        newTaskSelectedColor = task.colorIndex
        editingTask = task
        isEditingTask = true
        showPopup = true
    }
    
    
    // Conditionally render task list based on selected tab
    private var taskListForSelectedTab: some View {
        Group {
            if selectedTab == .all {
                ForEach(taskList) { task in
                    TaskCardView(taskObject: task, onEdit: { onEdit(task) })
                }
            } else {
                ForEach(remainingTaskList) { task in
                    TaskCardView(taskObject: task, onEdit: { onEdit(task) })
                }
            }
        }
    }
                    
    func DateTimeToString(from date: Date?) -> String {
        guard let date = date else {
            return "No Timing Set"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // 24-hour format
        return formatter.string(from: date)
    }
    
    private func dateFromString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
}



struct TabSelector: View {
    @Binding var selectedTab: TaskListView.Tab
    
    var body: some View {
        HStack(alignment: .center){
            Text("All")
                .frame(maxWidth: .infinity, maxHeight:.infinity)
                .font(.system(size: 16))
                .fontWeight(selectedTab == .all ? .heavy : .semibold)
                .background(selectedTab == .all ? Color.green : Color.clear)
                .foregroundColor(.white)
                .cornerRadius(10)
                .onTapGesture {
                    selectedTab = .all
                }
            Text("Remaining")
                .frame(maxWidth: .infinity, maxHeight:.infinity)
                .font(.system(size: 16))
                .fontWeight(selectedTab == .left ? .heavy : .semibold)
                .background(selectedTab == .left ? Color.orange : Color.clear)
                .foregroundColor(.white)
                .cornerRadius(10)
                .onTapGesture {
                    selectedTab = .left
                }
        }
        .padding(5)
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .background{
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2) // Inner shadow effect
        }
    }
}

struct AddTaskButton: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 18))
            .fontWeight(.heavy)
            .foregroundColor(.white)
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
            )
    }
}
