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
    @State private var colorFilter: Int = -1
    @State private var showColorPicker: Bool = false
    @State private var colorFilterButtonFrame: CGRect = .zero // Frame for positioning popup
    
    @State private var showPopup: Bool = false
    @State private var isEditingTask: Bool = true
    @State private var editingTask: TaskObject? = nil
    
    @State private var newTaskName: String = ""
    @State private var newTaskDescription: String = ""
    @State private var newTaskTimer: Date? = nil
    @State private var newTaskSelectedColor: Int = 0

    enum Tab {
        case all, remaining
    }
    
    private var remainingTaskList: [TaskObject] {
        taskList.filter { !$0.isDone } // Assuming `isDone = false` means "remaining"
    }
    
    var body: some View {
        ZStack{
            VStack(alignment:.center,spacing:5){
                HStack(alignment: .center, spacing:5){
                    GeometryReader { geometry in
                        TabSelector(
                            selectedTab: $selectedTab,
                            colorFilter: $colorFilter,
                            showColorPicker: $showColorPicker,
                            taskList: taskList,
                            remainingTaskList: remainingTaskList,
                            colorFilterButtonFrame: $colorFilterButtonFrame
                        )
                        .onAppear {
                            colorFilterButtonFrame = geometry.frame(in: .local)
                        }
                    }
                    
                    Spacer()
                    
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
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black)
                                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
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
            .padding([.leading,.trailing,.bottom],10)
            .padding(.top,5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .shadow(color: Color.black.opacity(10), radius: 5, x: 0, y: -1) // Inner shadow effect
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            .blur(radius: showColorPicker ? 3 : 0)
            
            // Dim background while keeping the color filter button in focus
            if showColorPicker {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        withAnimation {
                            showColorPicker = false
                        }
                    }
                
                // The color picker popup
                HStack(spacing: 10) {
                    HStack(alignment:.center,spacing:0){
                        ForEach(colorDict.keys.sorted(), id: \.self) { key in
                            Rectangle()
                                .fill(colorDict[key] ?? Color.clear)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth:36,maxHeight: 36)
                    .overlay(
                        Circle()
                            .stroke(colorFilter == -1 ? Color.black : Color.clear, lineWidth: 2)
                    )
                    .clipShape(Circle())
                    .onTapGesture {
                        withAnimation {
                            colorFilter = -1
                            showColorPicker = false
                        }
                    }
                    
                    ForEach(colorDict.keys.sorted(), id: \.self) { key in
                        Circle()
                            .fill(colorDict[key] ?? Color.clear)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(colorFilter == key ? Color.black : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                withAnimation {
                                    colorFilter = key
                                    showColorPicker = false
                                }
                            }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(radius: 10)
                )
//                .frame(width: 200) // Adjust width as needed
                .position(
                    x: screenWidth/2-15,
                    y: colorFilterButtonFrame.maxY + 45
                ) // Position popup directly below the button
            }
            
//            Spacer()
        }
        .blur(radius: showPopup ? 3 : 0)
            
//        // Popup Overlay
        if showPopup {
            
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
            let filteredList = colorFilter == -1 ? taskList : taskList.filter { $0.colorIndex == colorFilter }
            if selectedTab == .all {
                ForEach(filteredList) { task in
                    TaskCardView(taskObject: task, onEdit: { onEdit(task) })
                }
            } else {
                ForEach(filteredList.filter { !$0.isDone }) { task in
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
    @Binding var colorFilter: Int
    @Binding var showColorPicker: Bool
    var taskList: [TaskObject]
    var remainingTaskList: [TaskObject]
    @Binding var colorFilterButtonFrame: CGRect
    
    var body: some View {
        HStack(alignment: .center){
            HStack(alignment:.center,spacing:10){
                Text("All")
                    .font(.system(size: 16))
                    .fontWeight(selectedTab == .all ? .heavy : .semibold)
                
                Text("\(taskList.count)")
                    .font(.system(size: 16))
                    .fontWeight(selectedTab == .all ? .bold : .regular)
            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .foregroundColor(selectedTab == .all ? Color.white : Color.black)
            .background{
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedTab == .all ? Color.black : Color.white)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }
            .onTapGesture {
                selectedTab = .all
            }
            
            HStack(alignment:.center,spacing:10){
                Text("Left")
                    .font(.system(size: 16))
                    .fontWeight(selectedTab == .remaining ? .heavy : .semibold)
                
                Text("\(remainingTaskList.count)")
                    .font(.system(size: 16))
                    .fontWeight(selectedTab == .remaining ? .bold : .regular)
            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .foregroundColor(selectedTab == .remaining ? Color.white : Color.black)
            .background{
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedTab == .remaining ? Color.black : Color.white)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }
            .onTapGesture {
                selectedTab = .remaining
            }
                
            HStack(alignment:.center,spacing:10){
                HStack(alignment:.center,spacing:0){
                    Group {
                        switch colorFilter {
                        case -1:
                            ForEach(colorDict.keys.sorted(), id: \.self) { key in
                                Rectangle()
                                    .fill(colorDict[key] ?? Color.clear)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        default:
                            Circle()
                                .fill(colorDict[colorFilter] ?? Color.clear)
                        }
                    }
                }
                .frame(maxWidth:20,maxHeight: 20)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1) // Optional border
                )
                .clipShape(Circle())
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 16))
                    .fontWeight(colorFilter == -1 ? .semibold : .heavy)
            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .foregroundColor(colorFilter == -1 ? Color.black : Color.white)
            .background{
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorFilter == -1 ? Color.white : Color.black)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }
            .onTapGesture {
                withAnimation {
                    showColorPicker.toggle()
                }
            }
            
            Spacer()
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity)
        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
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

