//
//  GetUpWidgetBundle.swift
//  GetUpWidget
//
//  Created by ByteDance on 27/11/24.
//

import WidgetKit
import SwiftUI
import FirebaseCore

@main
struct GetUpWidgetBundle: WidgetBundle {
    init() {
        FirebaseApp.configure()
    }

    var body: some Widget {
        GetUpWidget()
        GetUpWidgetControl()
        GetUpWidgetLiveActivity()
    }
}
