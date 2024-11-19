//
//  NewTaskPopupView.swift
//  GetUp
//
//  Created by ByteDance on 14/11/24.
//

import SwiftUI
import Combine

struct NewTaskPopupView: View {
    
    @Binding var showPopup: Bool
    @Binding var newTaskName: String
    @Binding var newTaskDescription: String
    @Binding var newTaskDate: Date?
    @Binding var timerSet: Bool
    @Binding var selectedColor: Int
    @Binding var participantsStatus: [String:Bool]
    
    var selectedDate: Date
    
    var isEditing: Bool
    
    @State private var showTimePicker = false
    @State private var showParticipantPicker = false
    
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    var onDelete: (() -> Void)?
    
    private var otherParticipantDict: [String: String] {
        let uids = getOtherUIDs(from: participantsStatus)
        var dict: [String: String] = [:]
        for uid in uids {
            dict[uid] = getOtherUsername(from: uid)
        }
        return dict
    }

    
    var body: some View {
        VStack(alignment:.center, spacing: 20) {
            if showTimePicker {
                // Time Picker View
                TimePickerView()
            } else {
                TaskEditorView()
            }
        }
        .padding()
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .transition(.scale) // Popup scale animation
    }
    
    @ViewBuilder
    private func TimePickerView() -> some View {
        Text("Select Time")
            .font(.title3)
            .fontWeight(.bold)
        
        DatePicker(
            "Select Time",
            selection: Binding(
                get: {
                    newTaskDate ?? currentTimeOfDate(for: selectedDate)
                },
                set: { newValue in
                    newTaskDate = newValue // Update selectedTime when changed
                    timerSet = true
                }
            ),
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(WheelDatePickerStyle())
        .labelsHidden()
        .frame(maxWidth:UIScreen.main.bounds.width-100)
        

        Button("Done") {
            withAnimation {
                showTimePicker = false
            }
        }
        .padding(.vertical,10)
        .foregroundStyle(.white)
        .font(.title3)
        .fontWeight(.bold)
        .frame(maxWidth:.infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                . fill(Color.black)
        )
    }
    
    @ViewBuilder
    private func TaskEditorView() -> some View {
        Text(isEditing ? "Edit or Delete Task" : "Create New Task")
            .font(.title3)
            .fontWeight(.bold)
        
        VStack(spacing:20){
            
            VStack(spacing:10){
                TextField("Name", text: $newTaskName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                
                TextField("Description (Optional)", text: $newTaskDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 18))
                    .fontWeight(.regular)
            }
            
            HStack(alignment: .center,spacing:10){
                
                ColorSelectorView()
                
                VStack(alignment:.leading,spacing:10){
                    
                    TimingSelectorView()
                    
                    ParticipantsSelectorView()
                }
            }
        }
        
//                Spacer()
        
        HStack{
            Button("Cancel") {
                onCancel?()
                withAnimation {
                    showPopup = false
                }
            }
            .foregroundStyle(.white)
            .font(.title3)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth:.infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    . fill(Color.gray)
            )
            
            Button("Save") {
                // Handle save action here
                onSave?()
                withAnimation {
                    showPopup = false
                }
            }
            .foregroundStyle(.white)
            .font(.title3)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth:.infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(newTaskName.isEmpty ? .green : .green)
            )
            .disabled(newTaskName.isEmpty) // Disable if newTaskName is empty
            .opacity(newTaskName.isEmpty ? 0.3 : 1) // Adjust opacity for disabled state
            
            if isEditing{
                Button (
                    action: {
                        onDelete?()
                        withAnimation {
                            showPopup = false
                        }
                    },
                    label:{
                        Image(systemName: "trash")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            
                    }
                )
                .frame(width:50)
                .frame(maxHeight:.infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.red)
                )
            }
        }
    }
    
    @ViewBuilder
    private func ColorSelectorView() -> some View {
        VStack (spacing:15){
            HStack(spacing: 15) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(colorDict[index] ?? Color.clear)
                        .opacity(selectedColor == index ? 1 : 0.6)
                        .frame(width:30,height:30)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == index ? Color.black : Color.clear, lineWidth: 1.5)
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedColor = index
                            }
                        }
                }
            }
            HStack(spacing: 15) {
                ForEach(3..<colorDict.count, id: \.self) { index in
                    Circle()
                        .fill(colorDict[index] ?? Color.clear)
                        .opacity(selectedColor == index ? 1 : 0.6)
                        .frame(width:30,height:30)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == index ? Color.black : Color.clear, lineWidth: 1.5)
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedColor = index
                            }
                        }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    @ViewBuilder
    private func TimingSelectorView() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 16))
                .foregroundStyle(timerSet ? Color.white : Color.black)
            
            Button(timerSet ? formatDateTo24HourTime(date:newTaskDate) : "--:--") {
                withAnimation {
                    showTimePicker = true
                }
            }
            .foregroundStyle(timerSet ? Color.white : Color.black)
            .font(.system(size: 16))
            .fontWeight(.semibold)
            
            if timerSet {
                Button (
                    action: {
                        withAnimation{
                            newTaskDate = currentTimeOfDate(for: newTaskDate ?? Date())
                            timerSet = false
                        }
                    },
                    label:{
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(timerSet ? Color.white : Color.black)
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(timerSet ? Color.orange : Color.gray.opacity(0.1))
        )
    }
    
    @ViewBuilder
    private func ParticipantsSelectorView() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 16))
                .foregroundStyle(otherParticipantDict.count >= 1 ? Color.white : Color.black)
            
            Button(otherParticipantDict.count >= 1 ? (otherParticipantDict.count >= 2 ? "\(otherParticipantDict.count) others" : (otherParticipantDict.first.map { $0.value } ?? "Unknown")) : "Sync") {
                withAnimation {
                    let connections = connectionsList
                    if connections.count > 0 {
                        if connections.count == 1 {
                            // Assumes only can add 1 other person
                            for target in connections{
                                if !participantsStatus.keys.contains(target){
                                    participantsStatus[target] = false
                                }
                            }
                        } else{
                            // Default behavior: add all connections to task
                            for target in connections{
                                if !participantsStatus.keys.contains(target){
                                    participantsStatus[target] = false
                                }
                            }
                        }
                    }
                }
            }
            .foregroundStyle(otherParticipantDict.count >= 1 ? Color.white : Color.black)
            .font(.system(size: 16))
            .fontWeight(.semibold)
            
            if otherParticipantDict.count >= 1 {
                Button (
                    action: {
                        withAnimation{
                            if otherParticipantDict.count == 1 {
                                for target in otherParticipantDict.keys{
                                    if participantsStatus.keys.contains(target){
                                        participantsStatus.removeValue(forKey: target)
                                    }
                                }
                            } else{
                                // Default behavior: remove all participants in task
                                for target in otherParticipantDict.keys{
                                    if participantsStatus.keys.contains(target){
                                        participantsStatus.removeValue(forKey: target)
                                    }
                                }
                            }
                        }
                    },
                    label:{
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(otherParticipantDict.count >= 1 ? Color.white : Color.black)
                            
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(otherParticipantDict.count >= 1 ? Color.blue : Color.gray.opacity(0.1))
        )
    }
}
