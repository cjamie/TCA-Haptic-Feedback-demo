//
//  HapticEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import SwiftUI
import ComposableArchitecture

struct HapticEngineFeature: Reducer {
    struct State: Equatable {
        var engine: HapticEngine?
        var localizedError: String?
        // TODO: - injection
        var hapticPattern = try! HapticPattern(
            events: [
                HapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        .init(parameterID: .hapticIntensity, value: 1.0),
                        .init(parameterID: .hapticSharpness, value: 1.0),
                    ],
                    relativeTime: 0,
                    duration: 1
                )
            ],
            parameters: []
        )
        var formattedString: String?
    }
    
    enum Action {
        case onAppear
        case onDemoButtonTapped
        case onEngineCreation(HapticEngine)
        case onCreationFailed(Error)
    }
    
    let client: HapticEngineClient
        
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                
//                let data   if let prettyPrintedData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
//try? JSONSerialization.data(withJSONObject: state.hapticPattern, options: .prettyPrinted)
//                try NSJSONSerialization.dataWithJSONObject(props,
//                            options: .PrettyPrinted)
                
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                state.formattedString = (try? encoder.encode(state.hapticPattern))
                    .flatMap {
                    String(data: $0, encoding: .utf8)
                }

                return .run { send in
                    do {
                        let engine = try client.makeHapticEngine()
                        await send(.onEngineCreation(engine))
                        try await engine.start()
                    } catch {
                        await send(.onCreationFailed(error))
                    }
                }

            case .onCreationFailed(let error):
                state.localizedError = error.localizedDescription
                return .none
                
            case .onEngineCreation(let engine):
                state.engine = engine
                return .none

            case .onDemoButtonTapped:
                guard client.supportsHaptics() else {
                    state.localizedError = "Device does not support haptics."
                    return .none
                }
                
                do {
                    try state.engine
                        .unwrapOrThrow()
                        .makePlayer(state.hapticPattern)
                        .start(HapticTimeImmediate)
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
            ScrollView {
                VStack {
                    
                    viewStore.formattedString.map {
                        Text($0)
                            .lineLimit(nil)
                    }

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
