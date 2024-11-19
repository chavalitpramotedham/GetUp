//
//  GetUpApp.swift
//  GetUp
//
//  Created by ByteDance on 13/11/24.
//

import SwiftUI

let startingScreenIndex = 0

let colorDict: [Int: Color] = [
    0: Color.gray,
    1: Color.mint,
    2: Color.purple,
    3: Color.pink,
    4: Color.orange
]

let nameDict: [Int: String] = [
    0: "GENERAL",
    1: "WORK",
    2: "EXERCISE",
    3: "LEARN",
    4: "SOCIAL"
]

// To be stored in DB
//var currentUserName = ""
//var currentUserID = ""
//var connectionsList: [String] = []

var currentUserName = "Chava"
var currentUserID = "123"
var connectionsList: [String] = ["456"]

let userDB: [String:[String:[String]]] = [
    "123": [
        "userName": ["Chava"],
        "profilePicture": ["Chava"],
        "connections": ["456"]
    ],
    "456":
    [
        "userName": ["Cheryl"],
        "profilePicture": ["Cheryl"],
        "connections": ["123"]
    ]
]


let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

struct ContentView: View {
    var body: some View {
        NavigationStack {
            WelcomeView()
        }
    }
}

@main
struct GetUpApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

func triggerHapticFeedback() {
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    impactFeedbackGenerator.prepare()
    impactFeedbackGenerator.impactOccurred()
}

func setUID(_ uid:String){
    currentUserID = uid
    currentUserName = userDB[currentUserID]?["userName"]?[0] ?? ""
    connectionsList = userDB[currentUserID]?["connections"] ?? []
}


#Preview {
    ContentView()
}
