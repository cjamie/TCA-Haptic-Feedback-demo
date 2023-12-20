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
//            HapticMenuApp(store: Store(
//                initialState: HapticsFeature.State(),
//                reducer: {
//                    HapticsFeature(client: .live)
//                        ._printChanges()
//                }
//            ))
//            EmptyView()
            
            NavigationStack {
                
                HapticButtonView(
                    store: Store(
                        initialState: HapticEngineFeature.State(),
                        reducer: {
                            HapticEngineFeature(client: .liveHaptic, copyClient: .live)
                                ._printChanges()
                        }
                    )
                )
            }
            
//            HapticEventDetailView(
//                store: Store(
//                    initialState: EditHapticEventFeature.State(
//                        event: .dynamicMock
//                    ),
//                    reducer: {
//                        EditHapticEventFeature()
//                            ._printChanges()
//                    }
//                )
//            )
//            .padding()
        }
    }
}
