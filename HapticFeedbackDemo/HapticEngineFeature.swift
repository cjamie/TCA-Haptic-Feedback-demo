//
//  HapticEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import SwiftUI
//import CoreHaptics
import ComposableArchitecture

struct HapticEngineFeature: Reducer {
    
    struct State: Equatable {
        var engine: HapticEngine?
        var localizedError: String?
    }
    
    enum Action {
        case onAppear
        case onDemoButtonTapped
    }
    
    let client: HapticEngineClient
        
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                do {
                    let engine = try client.makeHapticEngine()
                    state.engine = engine
                    
                    return .run { [engine] send in
                        try await engine.start()
                    }
                } catch {
                    state.localizedError = error.localizedDescription
                }
 
                return .none
            case .onDemoButtonTapped:
                guard client.supportsHaptics() else {
                    state.localizedError = "Device does not support haptics."
                    return .none
                }
                
                do {
                    let engine = try state.engine.unwrapOrThrow()
                    let event = HapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            .init(parameterID: .hapticIntensity, value: 1.0),
                            .init(parameterID: .hapticSharpness, value: 1.0),
                        ],
                        relativeTime: 0,
                        duration: 1
                    )
                                        
                    let pattern = try HapticPattern(events: [event], parameters: [])
                    let player = try engine.makePlayer(pattern)
                    try player.start(HapticTimeImmediate)
                } catch {
                    print("Error generating haptic feedback: \(error.localizedDescription)")
                }

                return .none
            }
        }
    }
}

struct HapticButtonView: View {
    let store: StoreOf<HapticEngineFeature>
    

    var body: some View {
        
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                
                Text("Long label that needs to be able to wrap but isn't doing it yet.")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                
                
                Button(
                    action: { viewStore.send(.onDemoButtonTapped) }
                ) {
                    Text("Tap Me!")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
        }
    }
}

#Preview {
    HapticButtonView(
        store: Store(
            initialState: HapticEngineFeature.State(),
            reducer: {
                HapticEngineFeature(client: .mock)
            }
        )
    )
}
