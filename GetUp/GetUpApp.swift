//
//  GetUpApp.swift
//  GetUp
//
//  Created by ByteDance on 13/11/24.
//

import SwiftUI

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


#Preview {
    ContentView()
}
