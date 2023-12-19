//
//  HapticEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import SwiftUI
import ComposableArchitecture
import Foundation

// shows a pattern, (with multiple events).
struct HapticEngineFeature: Reducer {
    struct State: Equatable {
        var engine: HapticEngine?
        var localizedError: String?
        
        @BindingState
        var hapticPattern = try! HapticPattern(
            events: vanillaHapticEventGen
                .array(of: .always(2)).run(),
            parameters: []
        )

        @BindingState
        var formattedString: String?
        
        var hapticEvents: IdentifiedArrayOf<EditHapticEventFeature.State> {
            get {
                .init(uniqueElements: makeFrom(hapticPattern.events))
            }
            set {
                hapticPattern.events = newValue.elements.map(\.event)
            }
        }
    }
    
    enum Action: BindableAction {
        case onAppear
        case onDemoButtonTapped
        case onEngineCreation(HapticEngine)
        case onCreationFailed(Error)
        case onRandomizeButtonTapped
        
        case changeFormatted
        case hapticEvent(UUID, EditHapticEventFeature.Action)
        case binding(_ action: BindingAction<State>)
    }
    
    let client: HapticEngineClient
    let encoder = JSONEncoder().then {
        $0.outputFormatting = .prettyPrinted
    }
    
    private enum CancelID {
        case throttleFormatted
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    do {
                        let engine = try client.makeHapticEngine()
                        await send(.onEngineCreation(engine))
                        try await engine.start()
                    } catch {
                        await send(.onCreationFailed(error))
                    }
                }.merge(with: .send(.changeFormatted))
            case .hapticEvent:
                return .none

            case .onCreationFailed(let error):
                state.localizedError = error.localizedDescription
                return .none
                
            case .onEngineCreation(let engine):
                state.engine = engine
                return .none
                
            case .onRandomizeButtonTapped:
                for indice in state.hapticPattern.events.indices {
                    state.hapticPattern.events[indice]
                        .change(to: vanillaHapticEventGen.run())
                }

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
            case .changeFormatted:
                state.formattedString = (try? encoder.encode(state.hapticPattern))
                    .flatMap { String(data: $0, encoding: .utf8) }

                return .none
            }
        }.forEach(
            \.hapticEvents,
             action: /HapticEngineFeature.Action.hapticEvent,
             element: {
                 EditHapticEventFeature()
             }
        )
        .onChange(of: \.hapticPattern) { _, newValue in
            Reduce { state, _ in
                .send(.changeFormatted).throttle(
                    id: CancelID.throttleFormatted,
                    for: .seconds(1),
                    scheduler: DispatchQueue.main,
                    latest: true
                )
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
                            ForEachStore(store.scope(
                                state: \.hapticEvents,
                                action: HapticEngineFeature.Action.hapticEvent
                            )) {
                                HapticEventDetailView(store: $0).padding()
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
                    
                    HStack {
                        Button(
                            action: { viewStore.send(.onDemoButtonTapped) }
                        ) {
                            Text("Demo Haptic")
                                .font(.headline)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(
                            action: { viewStore.send(.onRandomizeButtonTapped) }
                        ) {
                            Text("Randomize")
                                .font(.headline)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
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

private let makeFrom = map(EditHapticEventFeature.State.init)
