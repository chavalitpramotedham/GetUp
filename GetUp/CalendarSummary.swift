//
//  CalendarSummary.swift
//  GetUp
//
//  Created by ByteDance on 15/11/24.
//
import SwiftUI

struct CalendarSummary: View {
    @ObservedObject var taskManager: TaskManager
    
    var body: some View {
        VStack(alignment:.leading,spacing: 40) {
            // Overall Completion Chart
            Text("Task Summary")
                .font(.title3)
                .fontWeight(.bold)
            
            overallCompletionChart()
            
            // Category-based Completion Charts
            ForEach(uniqueCategories(), id: \.self) { colorIndex in
                categoryCompletionChart(for: colorIndex)
            }
        }
        .padding()
    }
    
    // MARK: - Overall Completion Chart
    private func overallCompletionChart() -> some View {
        if let taskListsByDate = taskManager.taskListsByDate {
            let allTasks = taskListsByDate.values.flatMap { $0 }
            let completedTasks = allTasks.filter { $0.isDone }.count
            let totalTasks = allTasks.count
            let completionPercentage = totalTasks > 0 ? CGFloat(completedTasks) / CGFloat(totalTasks) : 0
            
            return AnyView(
                VStack {
                    ProgressView(value: completionPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 10, anchor: .center)
                        .overlay(
                            HStack{
                                Text("\(Int(completionPercentage * 100))% completed")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                
                                Text("\(Int(completionPercentage * 100))% completed")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                
                            }
                            
                        )
                }
            )
        } else {
            return AnyView(
                VStack {
                    Text("Overall Completion")
                        .font(.headline)
                }
            )
        }
    }
    
    // MARK: - Category-based Completion Chart
    private func categoryCompletionChart(for colorIndex: Int) -> some View {
        if let taskListsByDate = taskManager.taskListsByDate {
            let tasksInCategory = taskListsByDate.values.flatMap { $0 }.filter { $0.colorIndex == colorIndex }
            let completedTasks = tasksInCategory.filter { $0.isDone }.count
            let totalTasks = tasksInCategory.count
            let completionPercentage = totalTasks > 0 ? CGFloat(completedTasks) / CGFloat(totalTasks) : 0
            
            return AnyView(
                HStack {
                    Circle()
                        .fill(colorDict[colorIndex] ?? Color.gray)
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading) {
                        Text("Category \(colorIndex)")
                            .font(.headline)
                        ProgressView(value: completionPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: colorDict[colorIndex] ?? Color.gray))
                        Text("\(Int(completionPercentage * 100))% completed")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            )
        } else {
            return AnyView(
                HStack {
                    Circle()
                        .fill(colorDict[colorIndex] ?? Color.gray)
                        .frame(width: 24, height: 24)
                    Text("No tasks")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            )
        }
    }
    
    // MARK: - Helper to Get Unique Categories
    private func uniqueCategories() -> [Int] {
        let allTasks = taskManager.taskListsByDate?.values.flatMap { $0 } ?? []
        let categories = allTasks.map { $0.colorIndex }
        return Array(Set(categories))
    }
}

#Preview {
    CalendarSummary(taskManager: TaskManager())
}
