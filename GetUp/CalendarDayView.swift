//
//  CalendarDayView.swift
//  GetUp
//
//  Created by ByteDance on 14/11/24.
//

import SwiftUI

struct CalendarDayView: View {
    
    let isSelected: Bool
    let onSelect: () -> Void
    
    var isPast: Bool
    var isFuture: Bool
    
    var date: Date
    var totalTasks: Int
    var completedTasks: Int
    var id: Int
    
    var circleSize: CGFloat = 30
    var startAngle: CGFloat = 0
    var rotation: Double = -85
    
    var body: some View{
        
        let percentageCompleted: CGFloat = CGFloat(completedTasks)/CGFloat(totalTasks)
        let printPercentageCompleted: Int = Int(percentageCompleted*100)
        let numTasksLeft: Int = totalTasks - completedTasks
        
        let displayColor: Color = getDisplayColorByCompletion(for: percentageCompleted)
        
        if isPast || isFuture {
            if isPast{
                VStack (alignment:.center,spacing:5){
                    
                    HStack{
                        ZStack{
                            Circle()
                                .stroke(Color.gray.opacity(0.6), lineWidth: 8)
                                .frame(width: circleSize, height: circleSize)
                            
                            Circle()
                                .trim(from: 0, to: percentageCompleted) // Show progress
                                .stroke(displayColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(rotation)) // Rotate to start from top
                                .frame(width: circleSize, height: circleSize)           // Circle size
                        }
                        .padding(10)
                        
                        if isSelected{
                            VStack(alignment: .leading){
                                Text(String(printPercentageCompleted)+"%")
                                    .font(.system(size: 18))
                                    .fontWeight(.heavy)
                                    .foregroundStyle(isSelected ? displayColor : Color.white)
                                Text((totalTasks-completedTasks == 0) ? "\(totalTasks) tasks done!" : String(numTasksLeft)+"/\(totalTasks) tasks left")
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(isSelected ? displayColor : Color.white)
                            }
                            .padding(.trailing,10)
                        }
                    }
                    
                    VStack (alignment: .center,spacing:0){
                        Text(dayOfWeek(from: date))
                            .font(.system(size: 18))
                            .fontWeight(.heavy)
                            .foregroundStyle(Color.white)
                        Text(dateToDayMonthString(date))
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .foregroundStyle(Color.white)
                    }
                }
                .padding([.top,.bottom],15)
                .padding([.leading,.trailing],10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.black : Color.gray.opacity(0.4))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .onTapGesture {
                            onSelect() // Call the selection action
                        }
                )
            } else{
                VStack (alignment:.center,spacing:5){
                    ZStack{
                        Circle()
                            .stroke(Color.gray.opacity(0.6), lineWidth: 8)
                        
                            .frame(width: circleSize, height: circleSize)
                        
                        Circle()
                            .trim(from: 0, to: percentageCompleted) // Show progress
                            .stroke(displayColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(rotation)) // Rotate to start from top
                            .frame(width: circleSize, height: circleSize)
                    }
                    .padding(10)
                    
                    VStack (alignment: .center,spacing:0){
                        Text(dayOfWeek(from: date))
                            .font(.system(size: 18))
                            .fontWeight(.heavy)
                            .foregroundStyle(Color.white)
                        Text(dateToDayMonthString(date))
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .foregroundStyle(Color.white)
                    }
                }
                .padding([.top,.bottom],15)
                .padding([.leading,.trailing],10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.black : Color.gray.opacity(0.1))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .onTapGesture {
                            onSelect() // Call the selection action
                        }
                )
            }
        } else{
            VStack (alignment:.center,spacing:5){
                HStack{
                    ZStack{
                        Circle()
                            .stroke(Color.gray.opacity(0.6), lineWidth: 8)
                        
                            .frame(width: circleSize, height: circleSize)
                        
                        Circle()
                            .trim(from: 0, to: percentageCompleted) // Show progress
                            .stroke(displayColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(rotation)) // Rotate to start from top
                            .frame(width: circleSize, height: circleSize)
                    }
                    .padding(10)
                    
                    VStack(alignment: .leading){
                        Text(String(printPercentageCompleted)+"%")
                            .font(.system(size: 18))
                            .fontWeight(.heavy)
                            .foregroundStyle(isSelected ? displayColor : Color.white)
                        Text((totalTasks-completedTasks == 0) ? "\(totalTasks) tasks done!" : String(numTasksLeft)+"/\(totalTasks) tasks left")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundStyle(isSelected ? displayColor : Color.white)
                    }
                    .padding(.trailing,10)
                    
                }
                
                
                VStack (alignment: .center,spacing:0){
                    Text("Today")
                        .font(.system(size: 18))
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.white)
                    Text(dateToDayMonthString(date))
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                }
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.black : Color.gray.opacity(0.5))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .onTapGesture {
                        onSelect() // Call the selection action
                    }
            )
        }
    }
}

func dayOfWeek(from date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEE"
    return dateFormatter.string(from: date)
}

func dateToDayMonthString(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d MMM" // "d" for day without leading zero, "MMM" for abbreviated month name
    return dateFormatter.string(from: date)
}
