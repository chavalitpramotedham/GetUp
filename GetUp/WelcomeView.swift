//
//  ContentView.swift
//  GetUp
//
//  Created by ByteDance on 13/11/24.
//

import SwiftUI
import FirebaseAuth

struct WelcomeView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var userDetails: [String: (userName: String, userImageURL: String)] = [:] // Store user details
    @State private var isLoading = true // Tracks whether the data is still loading

    @State private var showAuthPopup = false // Tracks whether the data is still loading
    
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
    }
    
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
                    .padding(.horizontal)
                
                Text("Reminders for Chava & Cheryl")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                
                Spacer()
                
                if isLoading {
                    // Display a loading indicator while fetching data
                    ProgressView("Loading user data...")
                        .font(.headline)
                        .foregroundStyle(.gray)
                        .frame(maxWidth:.infinity)
                } else {
                    UserSelectionView
                }
            }
            .padding(50)
            .blur(radius: showAuthPopup ? 3 : 0)
            
            if showAuthPopup{
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showAuthPopup = false
                        }
                    }
                
                AuthView(taskManager: taskManager, showAuthPopup: $showAuthPopup)
                    .frame(maxWidth:screenWidth*0.9)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
            }
        }
        .task{
            fetchAllUserDetails()
        }
    }
    
    private var UserSelectionView: some View {
        VStack(spacing:30){
            
            if !UserSession.shared.deviceLinkedUIDs.isEmpty{
                NavigationLink(destination: MainPageView(taskManager: taskManager)) {
                    VStack(spacing: 20) {
                        
                        if currentUserImageURL != "" {
                            let url = URL(string: currentUserImageURL)
                            
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .scaleEffect(1.5)
                                    .frame(width: 250, height: 250)
                                    .clipShape(Circle()) // Make the image circular
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                            } placeholder: {
                                ZStack{
                                    Circle()
                                        .fill(Color.gray.opacity(0.9))
                                        .stroke(Color.white, lineWidth: 3)
                                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                                        .frame(width: 250, height: 250)
                                    
                                    ProgressView()
                                }
                            }
                        } else{
                            ZStack{
                                Circle()
                                    .fill(Color.gray.opacity(0.6))
                                    .stroke(Color.white, lineWidth: 3) // Add a black outline
                                    .frame(width: 250, height: 250)
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                                
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .scaleEffect(0.4)
                                    .foregroundColor(.white)
                                    .frame(width: 250, height: 250)
                                    .clipShape(Circle()) // Make the image circular
                            }
                        }
                        
                        
                        VStack(spacing:5){
                            Text(currentUserName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                            
                            Text("Current user")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundStyle(.black)
                        }
                    }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    setUID(currentUserID) // Initialize UID for Chava
                })
            }
            
            HStack(alignment: .top, spacing: 20){
                Spacer()
                
                ForEach(getOtherLinkedUIDs(), id: \.self) { userID in
                    let userName = userDetails[userID]?.userName ?? "Loading..."
                    let userImageURL = userDetails[userID]?.userImageURL ?? ""
                    
                    NavigationLink(destination: MainPageView(taskManager: taskManager)) {
                        VStack(spacing: 10) {
                            
                            if userImageURL != "" {
                                let url = URL(string: userImageURL)
                                
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .scaleEffect(1.5)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle()) // Make the image circular
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 1) // Add a black outline
                                        )
                                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                                } placeholder: {
                                    ZStack{
                                        Circle()
                                            .fill(Color.gray.opacity(0.6))
                                            .stroke(Color.black, lineWidth: 1) // Add a black outline
                                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                                            .frame(width: 50, height: 50)
                                        
                                        ProgressView()
                                    }
                                }
                            } else {
                                
                                ZStack{
                                    Circle()
                                        .fill(Color.gray.opacity(0.6))
                                        .stroke(Color.black, lineWidth: 1) // Add a black outline
                                        .frame(width: 50, height: 50)
                                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                                    
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .scaleEffect(0.4)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle()) // Make the image circular
                                }
                            }
                            
                            Text(userName)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .frame(width: 60)
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        setUID(userID)
                    })
                    
                }
                
                Button (
                    action: {
                        // Add new user (login/signup) <WIP>
                        showAuthPopup = true
                    },
                    label:{
                        HStack(alignment:.center, spacing: 10){
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.black)
//                                .frame(width: 50, height: 50)
                                .scaledToFit()
                            
                            if UserSession.shared.deviceLinkedUIDs.isEmpty{
                                Text("Add account")
                                    .font(.title3)
                                    .foregroundColor(.black)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.gray.opacity(0.4))
//                                .shadow(radius: 10)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        )
//                        .fill(Color.gray.opacity(0.4))
//                        .frame(height: 50)
//                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        
//                        ZStack{
//                            Circle()
//                                .fill(Color.gray.opacity(0.4))
//                                .frame(width: 50, height: 50)
//                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
//                            
//                            Image(systemName: "plus")
//                                .font(.title3)
//                                .foregroundColor(.black)
//                                .frame(width: 50, height: 50)
//                                .scaledToFit()
//                        }
                        
                        
                    }
                )
                
                Spacer()
            }
            .padding(.top,10)
        }
        
    }
    
    private func fetchAllUserDetails() {
        Task {
            guard !UserSession.shared.deviceLinkedUIDs.isEmpty else {
                print("Device Linked UIDs are empty. Aborting fetchAllUserDetails.")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            var tempUserDetails: [String: (userName: String, userImageURL: String)] = [:]
            
            for uid in UserSession.shared.deviceLinkedUIDs {
                do {
                    let data = try await fetchUserData(from: uid)
                    let userName = data["userName"] as? String ?? "Unknown"
                    let userImageURL = data["userImageURL"] as? String ?? ""
                    tempUserDetails[uid] = (userName: userName, userImageURL: userImageURL)
                } catch {
                    print("Error fetching data for UID \(uid): \(error.localizedDescription)")
                    tempUserDetails[uid] = (userName: "Unknown", userImageURL: "")
                }
            }

            // Update `userDetails` and mark loading as complete on the main thread
            DispatchQueue.main.async {
                self.userDetails = tempUserDetails
                self.isLoading = false
            }
        }
    }
}


func signUpWithEmail(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        if let user = authResult?.user {
            print("User signed up with UID: \(user.uid)")
            completion(.success(user.uid)) // Return the user's unique ID
        } else {
            completion(.failure(NSError(domain: "FirebaseAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unexpected error during sign-up"])))
        }
    }
}

func loginWithEmail(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
    Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        if let user = authResult?.user {
            print("User logged in with UID: \(user.uid)")
            completion(.success(user.uid)) // Return the user's unique ID
        } else {
            completion(.failure(NSError(domain: "FirebaseAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unexpected error during login"])))
        }
    }
}
