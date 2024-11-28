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
    var selectedDates: [Date]

    @State private var selectedTab: TaskListTab = .all
    @State private var colorFilter: Int = -1
    @State private var showColorPicker: Bool = false
    @State private var colorFilterButtonFrame: CGRect = .zero // Frame for positioning popup
    
    @State private var showTaskInputPicker: Bool = false
    @State private var taskInputButtonFrame: CGRect = .zero // Frame for positioning popup
    @State private var navigateToDictation: Bool = false
    
    @State private var showPopup: Bool = false
    @State private var isEditingTask: Bool = true
    @State private var editingTask: TaskObject? = nil
    
    @State private var newTaskName: String = ""
    @State private var newTaskDescription: String = ""
    @State private var newTaskDate: Date? = nil
    @State private var newTaskTimerSet: Bool = false
    @State private var newTaskSelectedColor: Int = 0
    @State private var newTaskParticipantsStatus: [String:Bool] = [currentUserID:false]

    enum TaskListTab {
        case all, remaining
    }
    
    private var myTaskList: [TaskObject] {
        taskList.filter { task in
            task.participantsStatus.keys.contains(currentUserID)
        }
    }
    
    private var remainingTaskList: [TaskObject] {
        myTaskList.filter { !($0.participantsStatus[currentUserID] ?? false) } // Assuming `isDone = false` means "remaining"
    }
    
    var body: some View {
        NavigationView{
            ZStack{
                VStack(alignment:.center,spacing:5){
                    HStack(alignment: .center, spacing:5){
                        GeometryReader { geometry in
                            TabSelector(
                                selectedTab: $selectedTab,
                                colorFilter: $colorFilter,
                                showColorPicker: $showColorPicker,
                                taskList: myTaskList,
                                remainingTaskList: remainingTaskList,
                                colorFilterButtonFrame: $colorFilterButtonFrame
                            )
                            .onAppear {
                                colorFilterButtonFrame = geometry.frame(in: .local)
                            }
                        }
                        
                        Spacer()
                        
                        GeometryReader { geometry in
                            Button (
                                action: {
                                    withAnimation {
                                        showTaskInputPicker = true
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
                                                .fill(selectedDates.count > 1 ? Color.black.opacity(0.2) : Color.black)
                                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                                        )
                                }
                            )
                            .disabled(selectedDates.count > 1)
                            .onAppear {
                                taskInputButtonFrame = geometry.frame(in: .local)
                            }
                        }
                        .frame(width: 40, height: 40) // Match the button size
                        
                        
                    }
                    .frame(maxWidth:.infinity, maxHeight:50)
                    
                    taskListForSelectedTab
                    
//                    ScrollView {
//                        VStack(spacing: 10) {
//                            taskListForSelectedTab
//                        }
//                    }
//                    .frame(maxWidth:.infinity,maxHeight:.infinity)
//                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
//                    if myTaskList.count > 0{
//                        ScrollView {
//                            VStack(spacing: 10) {
//                                taskListForSelectedTab
//                            }
//                        }
//                        .frame(maxWidth:.infinity,maxHeight:.infinity)
//                        .clipShape(RoundedRectangle(cornerRadius: 10))
//                    } else {
//                        Spacer()
//                        Image("fallback")
//                            .scaledToFit()
//                            .scaleEffect(0.75)
//                            .frame(width:75,height:75)
//                        Spacer()
//                    }
                    
                    
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
                    
                    colorPicker
                        .position(
                            x: screenWidth/2-15,
                            y: colorFilterButtonFrame.maxY + 45
                        ) // Position popup directly below the button
                }
                
                if showTaskInputPicker {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture {
                            withAnimation {
                                showTaskInputPicker = false
                            }
                        }
                    
                    taskInputPicker
                        .position(
                            x: screenWidth - 122, // Flush right alignment
                            y: taskInputButtonFrame.maxY + 65 // Positioned below the button
                        ) // Position popup directly below the button
                }
                
                
                
                NavigationLink(
//                    destination: DictationView(),
                    destination: DictationView(
                        selectedDate: selectedDates[0]
                    ) { newTasks in
                        taskList.append(contentsOf: newTasks)
                        taskManager.saveMultipleTasksToDB(newTasks)
                    },
                    isActive: $navigateToDictation,
                    label: { EmptyView() }
                )
            }
            .blur(radius: showPopup ? 3 : 0)
        }
        
        // Task Popup Overlay
        if showPopup {
            
            NewTaskPopupView(showPopup: $showPopup,
                                             newTaskName: $newTaskName,
                                             newTaskDescription: $newTaskDescription,
                                             newTaskDate: $newTaskDate,
                             timerSet:$newTaskTimerSet,
                             selectedColor: $newTaskSelectedColor,
                             participantsStatus: $newTaskParticipantsStatus,
                             selectedDate: selectedDates[0],
                             isEditing: isEditingTask
            ){
                // onSave closure to add the new task
                withAnimation {
                    if isEditingTask{
                        if let editingTask = editingTask {
                            // Update existing task
                            editingTask.name = newTaskName
                            editingTask.description = newTaskDescription
                            editingTask.colorIndex = newTaskSelectedColor
                            editingTask.taskDate = newTaskDate ?? currentTimeOfDate(for: selectedDates[0])
                            editingTask.timerSet = newTaskTimerSet
                            editingTask.participantsStatus = newTaskParticipantsStatus
                            
                            // Update task by taskID
                            taskManager.updateTaskToDB(editingTask)
                        }
                    }
                    else {
                        // Add a new task
                        let newTask = TaskObject(
                            name: newTaskName,
                            description: newTaskDescription,
                            colorIndex: newTaskSelectedColor,
                            taskDate: newTaskDate ?? currentTimeOfDate(for: selectedDates[0]),
                            timerSet: newTaskTimerSet,
                            participantsStatus: newTaskParticipantsStatus
                        )
                        taskList.append(newTask)
                        taskManager.saveTaskToDB(newTask)
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
                    taskManager.removeTaskFromDB(editingTask)
                }
                resetPopupFields()
            }
            .frame(maxWidth:.infinity, maxHeight:.infinity)
        }
    }
    
    private var colorPicker: some View {
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
    }
    
    private var taskInputPicker: some View {
        
        
        // The task input method picker popup
        VStack(alignment:.trailing, spacing: 10) {
            Button (
                action: {
                    withAnimation {
                        showTaskInputPicker = false
                        showPopup = true
                        isEditingTask = false
                    }
                },
                label:{
                    HStack{
                        Image(systemName: "pencil") // Pencil icon
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("Manual Input")
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            )
            
            Rectangle()
                .fill(.white)
                .frame(maxWidth:.infinity, maxHeight: 1)
            
            Button (
                action: {
                    withAnimation {
                        showTaskInputPicker = false
                        // open dictation page
                        navigateToDictation = true
                    }
                },
                label:{
                    HStack{
                        Image(systemName: "mic.fill") // Microphone icon
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("Dictation")
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black)
                .shadow(radius: 10)
        )
        .frame(width: 165) // Adjust width as needed
    }
    
    private func resetPopupFields() {
        newTaskName = ""
        newTaskDescription = ""
        newTaskDate = nil
        newTaskTimerSet = false
        newTaskSelectedColor = 0
        newTaskParticipantsStatus = [currentUserID:false]
        editingTask = nil
        isEditingTask = false
    }
    
    // Function to handle editing a task
    private func onEdit(_ task: TaskObject) {
        newTaskName = task.name
        newTaskDescription = task.description
        newTaskDate = task.taskDate
        newTaskTimerSet = task.timerSet
        newTaskSelectedColor = task.colorIndex
        newTaskParticipantsStatus = task.participantsStatus
        editingTask = task
        isEditingTask = true
        showPopup = true
    }
    
    
    // Conditionally render task list based on selected tab
    private var taskListForSelectedTab: some View {
        Group {
            let filteredList = colorFilter == -1 ? myTaskList : myTaskList.filter { $0.colorIndex == colorFilter }
            if selectedTab == .all {
                if filteredList.count > 0{
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(filteredList) { task in
                                TaskCardView(taskManager: taskManager, taskObject: task, onEdit: { onEdit(task) })
                            }
                        }
                    }
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
//                    ForEach(filteredList) { task in
//                        TaskCardView(taskManager: taskManager, taskObject: task, onEdit: { onEdit(task) })
//                    }
                } else{
                    fallbackScreen
                }
            } else {
                let leftFilteredList = filteredList.filter { !($0.participantsStatus[currentUserID] ?? false) }

                if leftFilteredList.count > 0{
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(leftFilteredList) { task in
                                TaskCardView(taskManager: taskManager, taskObject: task, onEdit: { onEdit(task) })
                            }
                        }
                    }
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
//                    ForEach(leftFilteredList.filter { !($0.participantsStatus[currentUserID] ?? false) }) { task in
//                        TaskCardView(taskManager: taskManager, taskObject: task, onEdit: { onEdit(task) })
//                    }
                } else{
                    fallbackScreen
                }
            }
        }
    }
    
    private var fallbackScreen: some View{
        VStack(alignment:.center){
            Spacer()
            Image("fallback")
                .scaledToFit()
                .scaleEffect(0.6)
                .frame(width:215,height:215)
            
            VStack(alignment:.center,spacing:5){
                Text("Nothing to do")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundStyle(.black)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                Text("Have a Great Day!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
            }
            Spacer()
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity)
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
    @Binding var selectedTab: TaskListView.TaskListTab
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
                withAnimation {
                    selectedTab = .all
                }
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
                withAnimation {
                    selectedTab = .remaining
                }
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
