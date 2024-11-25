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
            
            
            VStack (alignment: .leading, spacing: 10) {
                Text("Get Up!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                
                Text("Reminders for Chava & Cheryl")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                UserSelectionView()
            }
//            .offset(y:screenWidth/2)
            .padding(50)
        }
    }
}

struct UserSelectionView: View {
    
    var body: some View {
        HStack(alignment: .top){
            Spacer()
            
            ForEach(Array(userDB.keys).sorted(), id: \.self){ userID in
                
                let profilePicture = userDB[userID]?["profilePicture"]?[0] ?? "person"
                let userName = userDB[userID]?["userName"]?[0] ?? "Unknown"
                
                if currentUserID == userID{
                    VStack(spacing: 20) {
                        Image(profilePicture)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(1.5)
                            .frame(width: (screenWidth - 120) / 2, height: (screenWidth - 120) / 2)
                            .clipShape(Circle()) // Make the image circular
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2) // Add a black outline
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                        
                        VStack(spacing:5){
                            Text(userName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                            
                            Text("Current user")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundStyle(.black)
                        }
                    }
                } else{
                    NavigationLink(destination: MainPageView()) {
                        VStack(spacing: 20) {
                            Image(profilePicture)
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(1.5)
                                .frame(width: (screenWidth - 120) / 2, height: (screenWidth - 120) / 2)
                                .clipShape(Circle()) // Make the image circular
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 1) // Add a black outline
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                            
                            Text(userName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        setUID(userID) // Initialize UID for Chava
                    })
                }
                
                Spacer()
            }
        }
        .padding(.top,10)
    }
}

#Preview {
    WelcomeView()
}
