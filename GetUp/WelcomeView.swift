//
//  ContentView.swift
//  GetUp
//
//  Created by ByteDance on 13/11/24.
//

import SwiftUI

struct WelcomeView: View {
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack{
            Image("welcome_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0), Color.white.opacity(0.8),Color.white.opacity(0.99)]),
                                   startPoint: .center,
                                   endPoint: .bottom)
                    )
            
            
            VStack (alignment: .leading, spacing: 25) {
                Text("Get Up!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundStyle(.black)
                
                Text("Reminders for Chava & Cheryl")
                    .font(.title2)
                    .fontWeight(.regular)
                    .foregroundStyle(.black)
                
                NavigationLink(destination: HabitListView()) {
                    Text("Get Started")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding([.top, .bottom], 10)
                        .padding([.leading, .trailing], 20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                . fill(Color.black)
                        )
                }
                .padding(.top,10)

            }
            .offset(y:screenWidth/1.6)
            .padding(50)
        }
    }
}

#Preview {
    WelcomeView()
}
