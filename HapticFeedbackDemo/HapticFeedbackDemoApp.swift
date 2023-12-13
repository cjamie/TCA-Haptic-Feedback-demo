//
//  HapticFeedbackDemoApp.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct HapticFeedbackDemoApp: App {
    var body: some Scene {
        WindowGroup {
            HapticMenuApp(store: Store(
                initialState: HapticsFeature.State(),
                reducer: {
                    HapticsFeature(client: .live)
                        ._printChanges()
                }
            ))
        }
    }
}
