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
            // TODO: - destination based navigation.
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
                        initialState: HapticEngineFeature.State(
                            hapticPattern: hapticPatternGen.run()
                        ),
                        reducer: {
                            HapticEngineFeature(
                                client: .liveHaptic,
                                copyClient: .live, 
                                hapticEventGen: vanillaHapticEventGen.run
                            )
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
            
//            PresetAudioEngineView(
//                store: Store(
//                    initialState: PresetAudioEngineFeature.State(),
//                    reducer: {
//                        PresetAudioEngineFeature(
//                            namedLoaders: Named.basicCases,
//                            client: .liveCHHapticPattern
//                        )
//                            ._printChanges()
//                    }
//                )
//            )
        }
    }
}
