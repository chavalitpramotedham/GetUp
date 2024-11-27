//
//  GetUpWidgetLiveActivity.swift
//  GetUpWidget
//
//  Created by ByteDance on 27/11/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GetUpWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GetUpWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GetUpWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension GetUpWidgetAttributes {
    fileprivate static var preview: GetUpWidgetAttributes {
        GetUpWidgetAttributes(name: "World")
    }
}

extension GetUpWidgetAttributes.ContentState {
    fileprivate static var smiley: GetUpWidgetAttributes.ContentState {
        GetUpWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GetUpWidgetAttributes.ContentState {
         GetUpWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GetUpWidgetAttributes.preview) {
   GetUpWidgetLiveActivity()
} contentStates: {
    GetUpWidgetAttributes.ContentState.smiley
    GetUpWidgetAttributes.ContentState.starEyes
}
