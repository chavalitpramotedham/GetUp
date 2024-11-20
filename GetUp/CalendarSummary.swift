//
//  CalendarSummary.swift
//  GetUp
//
//  Created by ByteDance on 15/11/24.
//
import SwiftUI

struct CalendarSummary: View {
    @ObservedObject var taskManager: TaskManager
    var summaryDates: [Date] = []
    
    var totalTaskList: [TaskObject] = []
    
    var body: some View {
        
        VStack(alignment:.center,spacing: 20) {
            // Overall Completion Chart
            
            overallCompletionChart()
                .padding(.horizontal,20)
                
            
            HStack(spacing:0){
                ConcentricCircleView(taskList: totalTaskList)
                CategoryCompletionChart(taskList: totalTaskList)
            }
            .padding(.horizontal,-10)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 0)
    }
    
    
    
    // MARK: - Overall Completion Chart
    private func overallCompletionChart() -> some View {
        let completedTasks = totalTaskList.filter { $0.participantsStatus[currentUserID] ?? false }.count
        let totalTasks = totalTaskList.count
        let completionPercentage = totalTasks > 0 ? CGFloat(completedTasks) / CGFloat(totalTasks) : 0
        
        let displayColor: Color = getDisplayColorByCompletion(totalTasks: totalTasks, completedTasks: completedTasks)
        
        return AnyView(
            HStack (spacing:20){
                if totalTasks == 0{
                    Text("No Tasks Yet")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                }else{
                    Text("\(Int(completionPercentage * 100))%")
                        .font(.system(size: 30))
                        .foregroundColor(displayColor)
                        .fontWeight(.heavy)
                        .frame(width:90, alignment:.trailing)
                    
                    VStack {
                        ProgressView(value: completionPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: displayColor))
                            .scaleEffect(x: 1, y: 9, anchor: .center)
                            .overlay(
                                HStack{
                                    Text("\(completedTasks)/\(totalTasks) done")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                }
                                
                            )
                    }
                }
            }
        )
    }
}

struct ConcentricCircleView: View {
    var taskList: [TaskObject]
//    @ObservedObject var taskManager: TaskManager // Assumes taskManager manages task data
    let circleThickness: CGFloat = 10           // Adjust circle thickness

    var body: some View {
        ZStack {
            // Dynamically generate circles based on colorIndex categories
            ForEach(taskCategories(taskList).indices, id: \.self) { index in
                let category = taskCategories(taskList)[index]
                let completedTasks = category.completedTasks
                let totalTasks = category.totalTasks
                let progress = category.progress
                let color = category.color
                
                ZStack{
                    Circle()
                        .stroke(totalTasks > 0 ? color.opacity(0.3) : color.opacity(0.05), style: StrokeStyle(lineWidth: circleThickness, lineCap: .round))
                        .rotationEffect(.degrees(-90)) // Rotate to start from top
                        .frame(width: calculateSize(index), height: calculateSize(index))
                    
                    Circle()
                        .trim(from: 0, to: progress) // Show progress
                        .stroke(color, style: StrokeStyle(lineWidth: circleThickness, lineCap: .round))
                        .rotationEffect(.degrees(-90)) // Rotate to start from top
                        .frame(width: calculateSize(index), height: calculateSize(index))
                }
            }
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helper Methods

    /// Calculate the size of each circle based on its index
    private func calculateSize(_ index: Int) -> CGFloat {
        let baseSize: CGFloat = 160 // Base size for the outermost circle
        let spacing: CGFloat = 15  // Space between circles
        return baseSize - CGFloat(index) * (circleThickness + spacing)
    }
}

struct CategoryCompletionChart: View {
    var taskList: [TaskObject]

    var body: some View {
        VStack(alignment:.leading,spacing:5){
            ForEach(taskCategories(taskList).indices, id: \.self) { index in
                let category = taskCategories(taskList)[index]
                let name = category.name
                let completedTasks = category.completedTasks
                let totalTasks = category.totalTasks
                let progress = category.progress
                let color = category.color
                
                
                HStack (spacing:8){
                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                    VStack(alignment: .leading, spacing:0) {
                        HStack{
                            Text(name)
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                                .foregroundStyle(color)
                        }
                        HStack (spacing:0){
                            Text(totalTasks > 0 ? "\(completedTasks)/\(totalTasks) done" : "-")
                                .font(.system(size: 12))
                                .fontWeight(.regular)
                                .foregroundStyle(totalTasks > 0 ? Color.black : Color.gray)
                            
                        }
                    }
                }
            }
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}



/// Calculate task categories and their progress
func taskCategories(_ taskList: [TaskObject]) -> [(name: String, color: Color, progress: CGFloat, totalTasks: Int, completedTasks: Int)] {
    
    let allTasks = taskList.flatMap { $0 }
    
    var categories: [(name: String, color: Color, progress: CGFloat, totalTasks: Int, completedTasks: Int)] = []
    
    for (index, color) in colorDict.sorted(by: { $0.key < $1.key }) {
        let name = nameDict[index] ?? ""
        let tasksInCategory = allTasks.filter { $0.colorIndex == index }
        let totalTasks = tasksInCategory.count
        let completedTasks = tasksInCategory.filter { $0.participantsStatus[currentUserID] ?? false }.count
        let progress: CGFloat = totalTasks > 0 ? CGFloat(completedTasks) / CGFloat(totalTasks) : 0
        
//        if(totalTasks > 0){
//            categories.append((name: name, color: color, progress: progress, totalTasks: totalTasks, completedTasks: completedTasks))
//        }
        
        categories.append((name: name, color: color, progress: progress, totalTasks: totalTasks, completedTasks: completedTasks))
    }
    
    return categories
}

#Preview {
    CalendarSummary(taskManager: TaskManager())
}
