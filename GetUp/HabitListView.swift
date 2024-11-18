//
//  HabitListView.swift
//  GetUp
//
//  Created by ByteDance on 13/11/24.
//

import SwiftUI
import Foundation
import Combine

struct HabitListView: View {
    @ObservedObject var taskManager: TaskManager
    
    @State private var selectedCardIndex: Int
    @State private var selectedDates: [Date]
    @State private var selectedTaskList: [TaskObject]
    
    @StateObject private var proxyHolder = ScrollViewProxyHolder()
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
        
        _selectedCardIndex = State(initialValue: taskManager.pastDates.count) // Assuming today is at index 30
        
        if let combinedDates = taskManager.combinedDates {
            _selectedDates = State(initialValue: [combinedDates[taskManager.pastDates.count]])
        } else{
            _selectedDates = State(initialValue: [Date()])
        }

        _selectedTaskList = State(initialValue: [])
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Title
            
            HStack(alignment: .bottom){
                VStack(alignment: .leading, spacing:5){
                    Text("Hi, "+userName+"...")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.black)
                    
                    Text("It's time to GET UP!!! 🫨🥵")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity,alignment: .leading)
                
                Button (
                    action: {
                        Task { withAnimation{resetSelection() }}
                    },
                    label:{
                        VStack(alignment: .center, spacing:5){
                            Image(systemName: "clock.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                
                            Text("Today")
                                .font(.system(size: 10))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                . fill(Color.black.opacity(0.2))
                        )
                    }
                )
            }
            .padding(.bottom,10)
            
            
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing:10){
                            
                            ForEach(Array(taskManager.pastDates.enumerated()), id: \.element) { index, date in
                                
                                if let tasksListByDate = taskManager.taskListsByDate{
                                    if let tasks = tasksListByDate[date] {
                                        let totalTasks = tasks.count
                                        let completedTasks = tasks.filter { $0.isDone }.count
                                        
                                        CalendarDayView(isSelected: selectedCardIndex == index,
                                                    onSelect:{
                                            withAnimation{makeSelection(index)}
                                                    },
                                                    isPast: true, isFuture: false, date: date,
                                                    totalTasks: totalTasks,
                                                    completedTasks: completedTasks,
                                                    id: index)
                                            .id(index)
                                    }
                                }
                                
                                
                            }
                            
                            ForEach(Array(taskManager.todayDates.enumerated()), id: \.element) { index, date in
                                if let tasksListByDate = taskManager.taskListsByDate{
                                    if let tasks = tasksListByDate[date] {
                                        let totalTasks = tasks.count
                                        let completedTasks = tasks.filter { $0.isDone }.count
                                        
                                        CalendarDayView(isSelected: selectedCardIndex == taskManager.pastDates.count + index,
                                                        onSelect:{
                                            withAnimation{makeSelection(taskManager.pastDates.count + index)}
                                        },
                                                        isPast: false, isFuture: false, date: date,
                                                        totalTasks: totalTasks,
                                                        completedTasks: completedTasks,
                                                        id: taskManager.pastDates.count + index)
                                        .id(taskManager.pastDates.count + index)
                                    }
                                }
                            }
                            
                            ForEach(Array(taskManager.futureDates.enumerated()), id: \.element) { index, date in
                                
                                if let tasksListByDate = taskManager.taskListsByDate{
                                    if let tasks = tasksListByDate[date] {
                                        let totalTasks = tasks.count
                                        let completedTasks = tasks.filter { $0.isDone }.count
                                        
                                        CalendarDayView(isSelected: selectedCardIndex == taskManager.pastDates.count + 1 + index,
                                                        onSelect:{
                                            withAnimation{makeSelection(taskManager.pastDates.count + 1 + index)}
                                        },
                                                        isPast: false, isFuture: true, date: date,
                                                        totalTasks: totalTasks,
                                                        completedTasks: 0,
                                                        id: taskManager.pastDates.count + 1 + index)
                                        .id(taskManager.pastDates.count + 1 + index)
                                    }
                                }
                            }
                        }
                        .padding([.leading],30)
                        .frame(alignment:.trailing)
                }
                .padding(.horizontal,-30)
                .onAppear {
                    if proxyHolder.proxy == nil {
                        proxyHolder.proxy = proxy
                        // Initial scroll to the center item
                        proxy.scrollTo(taskManager.pastDates.count, anchor: .center)
                        resetSelection()
                    }
                }
            }
            
            TaskListView(taskList: $selectedTaskList,
                         taskManager: taskManager,
                         selectedDates: selectedDates)
                .onChange(of: selectedTaskList) { newTasks in
                    // Update TaskManager with modified task list
                    withAnimation{
                        taskManager.updateTaskList(for: selectedDates[0], with: newTasks)
                    }
                }
                .onReceive(selectedTaskList.publisher.flatMap { $0.objectWillChange }) { _ in
                    withAnimation{
                        taskManager.updateTaskList(for: selectedDates[0], with: selectedTaskList)
                    }
                }
                .padding(.horizontal,-15)
        }
        .padding([.leading, .trailing], 30)
        .padding([.top], 80)
        .padding([.bottom], 100)
        .frame(maxWidth: screenWidth, maxHeight: .infinity)
    }
    
    private func resetSelection() {
        guard let proxy = proxyHolder.proxy else { return }
        
        triggerHapticFeedback()
        selectedCardIndex = taskManager.pastDates.count
        if let combinedDates = taskManager.combinedDates {
            selectedDates = [combinedDates[selectedCardIndex]]
        }
        withAnimation {
            proxy.scrollTo(taskManager.pastDates.count, anchor: .center)
        }
        
        if let tasksListByDate = taskManager.taskListsByDate{
            if let taskList = tasksListByDate[selectedDates[0]] {
                selectedTaskList = taskList
            }
        }
    }
    
    private func makeSelection(_ index: Int) {
        guard let proxy = proxyHolder.proxy else { return }
        
        triggerHapticFeedback()
        selectedCardIndex = index
        if let combinedDates = taskManager.combinedDates {
            selectedDates = [combinedDates[selectedCardIndex]]
        }
        withAnimation {
            proxy.scrollTo(index, anchor: .center)
        }
        
        if let tasksListByDate = taskManager.taskListsByDate{
            if let taskList = tasksListByDate[selectedDates[0]] {
                selectedTaskList = taskList
            }
        }
    }
    
    private func updateTaskStatus(_ index: Int){
        if let tasksListByDate = taskManager.taskListsByDate{
            if let combinedDates = taskManager.combinedDates{
                if let taskList = tasksListByDate[combinedDates[selectedCardIndex]] {
                    taskList[index].isDone.toggle()
                }
            }
        }
    }
}
                                
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HabitListView(taskManager: TaskManager())
    }
}
