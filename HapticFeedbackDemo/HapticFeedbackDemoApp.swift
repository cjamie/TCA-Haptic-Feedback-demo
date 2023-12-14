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
            
//            NavigationView {
//                
//                HapticButtonView(
//                    store: Store(
//                        initialState: HapticEngineFeature.State(),
//                        reducer: {
//                            HapticEngineFeature(client: .live)
//                        }
//                    )
//                ).navigationTitle("Build your own!")
//            }
            
            HapticEventDetailView(
                store: Store(
                    initialState: HapticEventDetailFeature.State(
                        event: .dynamicMock
                    ),
                    reducer: {
                        HapticEventDetailFeature()
                            ._printChanges()
                    }
                )
            )
            .padding()
        }
    }
}
