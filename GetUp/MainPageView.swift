//
//  MainPageView.swift
//  GetUp
//
//  Created by ByteDance on 15/11/24.
//

import SwiftUI
import Foundation
import Combine



class ScrollViewProxyHolder: ObservableObject {
    var proxy: ScrollViewProxy?
}

struct MainPageView: View {
    
    @ObservedObject var taskManager: TaskManager
    @StateObject private var proxyHolder = ScrollViewProxyHolder()
    
    @State private var selectedBottomTab: Int
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
        _selectedBottomTab = State(initialValue: startingScreenIndex)
    }
    
    var body: some View {
        ZStack{
            Image("welcome_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0), Color.white.opacity(0.8),Color.white.opacity(0.9),Color.white.opacity(0.99)]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
            
            Group {
                switch selectedBottomTab {
                case 0:
                    HabitListView(taskManager: taskManager)
                case 1:
                    CalendarView(taskManager: taskManager)
                case 2:
                    Text("Social View <WIP>")

                case 3:
                    Text("Profile View <WIP>")
//                    UserSelectionView()
//                        .padding(.horizontal,30)

                default:
                    Text("Invalid Tab")
                }
            }
            
            FloatingNavBar(selectedTab: $selectedBottomTab)
                .frame(maxWidth: screenWidth)
        }
        .frame(maxWidth: screenWidth, maxHeight: screenHeight)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

//#Preview{
//    MainPageView()
//}
                                
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainPageView()
//    }
//}
