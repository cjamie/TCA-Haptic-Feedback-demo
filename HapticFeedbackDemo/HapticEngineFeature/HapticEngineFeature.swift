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
        
        @BindingState
        var hapticPattern = try! HapticPattern(
//            events: hapticEventGen.array(of: .always(1)).run(),
            events: [
                HapticEvent(
                    id: UUID(),
                    eventType: .hapticContinuous,
                    parameters: [
//                        .init(id: UUID(), parameterID: .hapticIntensity, value: 1.0, range: 0...1),
//                        .init(id: UUID(), parameterID: .hapticSharpness, value: 1.0, range: 0...1),
//                        .init(id: UUID(), parameterID: .attackTime, value: 1.0, range: 0...1)
//                        .init(id: UUID(), parameterID: .audioBrightness, value: 1.0, range: 0...1),
//                        .init(id: UUID(), parameterID: .audioPan, value: 1.0, range: 0...1),
//                        .init(id: UUID(), parameterID: .audioPitch, value: 1.0, range: 0...1),
                        .init(id: UUID(), parameterID: .audioVolume, value: 1.0, range: 0...1),
//                        .init(id: UUID(), parameterID: .decayTime, value: 1.0, range: 0...1),
//                        .init(id: UUID(), parameterID: .releaseTime, value: 1.0, range: 0...1),
//                        .init(id: UUID(), parameterID: .sustained, value: 1.0, range: 0...1),

                    ],
                    relativeTime: 0,
                    duration: 1
                )
            ],
//            events: [
//                
//            ],
            parameters: []
        )

        @BindingState
        var formattedString: String?
    }
    
    enum Action: BindableAction {
        case onAppear
        case onDemoButtonTapped
        case onEngineCreation(HapticEngine)
        case onCreationFailed(Error)
        
        case binding(_ action: BindingAction<State>)
    }
    
    let client: HapticEngineClient
    let encoder = JSONEncoder()

    var body: some ReducerOf<Self> {
        BindingReducer()
            .onChange(of: \.$hapticPattern) { _, newValue in
                Reduce { state, _ in
                    
                    print("-=- z... ")
                    encoder.outputFormatting = .prettyPrinted
                    state.formattedString = (try? encoder.encode(newValue))
                        .flatMap { String(data: $0, encoding: .utf8) }

                    return .none
                }
            }
        Reduce { state, action in
            switch action {
            case .onAppear:
                encoder.outputFormatting = .prettyPrinted
                state.formattedString = (try? encoder.encode(state.hapticPattern))
                    .flatMap { String(data: $0, encoding: .utf8) }

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
                state.localizedError = nil

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
                    state.localizedError = "Error generating haptic feedback: \(error.localizedDescription)"
                }

                return .none
            case .binding:
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
                    Text(viewStore.localizedError ?? "Haptic Pattern detail")
                        
                    Section("Events") {
                        VStack(alignment: .leading) {
                            // TODO: - this needs a foreach store
                            ForEach(viewStore.hapticPattern.events) { event in
                                HapticEventDetailView(
                                    store: Store(
                                        initialState: EditHapticEventFeature.State(
                                            event: event
                                        ),
                                        reducer: {
                                            EditHapticEventFeature()
                                                ._printChanges()
                                        }
                                    )
                                )
                                .padding()
                            }
                        }
                    }
                    
                    // TODO: - handle focus state changes (because of keyboard)
                    viewStore.$formattedString.unwrap().map {
                        TextField("Enter text here", text: $0, axis: .vertical)
                            .padding()
                            .background(.green)
                            .frame(height: 200)
                        
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


