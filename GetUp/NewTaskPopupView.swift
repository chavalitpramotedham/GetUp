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
    @Binding var selectedTime: Date?
    @Binding var selectedColor: Int
    @Binding var participantsID: [String]
    
    var isEditing: Bool
    
    @State private var showTimePicker = false
    @State private var showParticipantPicker = false
    
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    var onDelete: (() -> Void)?
    
    var body: some View {
        
        var otherParticipantList: [String] {
            getOtherUIDs(from: participantsID).map { getOtherUsername(from: $0) }
        }
        
        let _ = print(otherParticipantList)
        
        VStack(alignment:.center, spacing: 20) {
            if showTimePicker {
            // Time Picker View
                Text("Select Time")
                    .font(.title3)
                    .fontWeight(.bold)
                
                DatePicker(
                    "Select Time",
                    selection: Binding(
                        get: {
                            selectedTime ?? Date() // Provide a default date if selectedTime is nil
                        },
                        set: { newValue in
                            selectedTime = newValue // Update selectedTime when changed
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
                
            } else {
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
                        
                        VStack(alignment:.leading,spacing:10){
                            HStack(spacing: 10) {
                                Image(systemName: "timer")
                                    .font(.system(size: 16))
                                    .foregroundStyle(selectedTime != nil ? Color.white : Color.black)
                                
                                Button(selectedTime != nil ? formatDateTo24HourTime(date:selectedTime) : "--:--") {
                                    withAnimation {
                                        showTimePicker = true
                                    }
                                }
                                .foregroundStyle(selectedTime != nil ? Color.white : Color.black)
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                                
                                if selectedTime != nil {
                                    Button (
                                        action: {
                                            withAnimation{
                                                selectedTime = nil
                                            }
                                        },
                                        label:{
                                            Image(systemName: "xmark")
                                                .font(.system(size: 14))
                                                .foregroundStyle(selectedTime != nil ? Color.white : Color.black)
                                        }
                                    )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTime != nil ? Color.orange : Color.gray.opacity(0.1))
                            )
                            
                            HStack(spacing: 10) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(otherParticipantList.count >= 1 ? Color.white : Color.black)
                                
                                Button(otherParticipantList.count >= 1 ? (otherParticipantList.count >= 2 ? "\(otherParticipantList.count) others" : "\(otherParticipantList[0])") : "Sync") {
                                    withAnimation {
                                        participantsID = [uid,uid2]
                                    }
                                }
                                .foregroundStyle(otherParticipantList.count >= 1 ? Color.white : Color.black)
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                                
                                if otherParticipantList.count >= 1 {
                                    Button (
                                        action: {
                                            withAnimation{
                                                participantsID = [uid]
                                            }
                                        },
                                        label:{
                                            Image(systemName: "xmark")
                                                .font(.system(size: 14))
                                                .foregroundStyle(otherParticipantList.count >= 1 ? Color.white : Color.black)
                                                
                                        }
                                    )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(otherParticipantList.count >= 1 ? Color.blue : Color.gray.opacity(0.1))
                            )
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
        }
        .padding()
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .transition(.scale) // Popup scale animation
    }
}
