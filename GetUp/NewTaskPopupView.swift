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
                    
                    HStack(alignment: .center,spacing:20){
                        HStack(spacing: 10) {
                            Image(systemName: "timer")
                                .font(.system(size: 16))
                            
                            Button(selectedTime != nil ? formattedTime() : "--:--") {
                                withAnimation {
                                    showTimePicker = true
                                }
                            }
                            .foregroundStyle(.black)
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.gray.opacity(0.1))
                        )
                        
                        HStack(spacing: 10) {
                            ForEach(0..<colorDict.count, id: \.self) { index in
                                Circle()
                                    .fill(colorDict[index] ?? Color.clear)
                                    .opacity(selectedColor == index ? 1 : 0.6)
                                    .frame(width:20,height:20)
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
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.gray.opacity(0.1))
                        )
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
    
    // Function to format the selected time as a string
    private func formattedTime() -> String {
        guard let time = selectedTime else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}
