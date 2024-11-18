//
//  FloatingNavBar.swift
//  GetUp
//
//  Created by ByteDance on 15/11/24.
//

import SwiftUI

struct FloatingNavBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack{
            Spacer()
            
            // Tab Bar
            HStack {
                TabBarButton(image: "checklist", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                Spacer()
                
                TabBarButton(image: "calendar", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                Spacer()
                
                TabBarButton(image: "person.2.fill", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                
                Spacer()
                
                TabBarButton(image: "person.fill", isSelected: selectedTab == 4) {
                    selectedTab = 3
                }
            }
            .padding(.horizontal, 70)
            .padding(.top, 35)
            .padding(.bottom, 45)
            .frame(height:80)
            .background(.white)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -3)
            
        }
        .edgesIgnoringSafeArea(.bottom)
            
    }
}

struct TabBarButton: View {
    var image: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: image)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black : .gray)
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 4, height: 4)
                        .offset(y: 5)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -3)
                    
                }
            }
        }
    }
}
