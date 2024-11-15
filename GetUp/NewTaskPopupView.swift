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
    
    var isEditing: Bool
    
    @State private var showTimePicker = false
    
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment:.center, spacing: 20) {
            if showTimePicker {
            // Time Picker View
                
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
                    
                    HStack(spacing: 15) {
                        ForEach(0..<colorDict.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 5)
                                .fill(colorDict[index] ?? Color.clear)
                                .opacity(selectedColor == index ? 1 : 0.6)
                                .frame(maxWidth:.infinity,maxHeight:.infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(selectedColor == index ? Color.black : Color.clear, lineWidth: 1.5)
                                )
                                .onTapGesture {
                                    selectedColor = index
                                    print(isEditing)
                                }
                        }
                    }
                    .frame(height:20)
                    
                    HStack(alignment: .center,spacing: 10){
                        Image(systemName: "timer")
                            .font(.system(size: 18))
                        
                        Button(selectedTime != nil ? formattedTime() : "Set Timer") {
                            withAnimation {
                                showTimePicker = true
                            }
                        }
                        .foregroundStyle(.black)
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                        
                    }
                    .frame(width:150,height: 40)
                    
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
    
    // Function to format the selected time as a string
    private func formattedTime() -> String {
        guard let time = selectedTime else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}
