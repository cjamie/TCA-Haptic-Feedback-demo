//
//  HapticEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import SwiftUI
import ComposableArchitecture

// shows a pattern, (with multiple events).
struct HapticEngineFeature: Reducer {
    struct State: Equatable {
        var engine: HapticEngine?
        var localizedError: String?
        var engineFailureDescription: String?

        var copyImage: String = "square.on.square"
        var copyColor: Color = .blue
        
        @BindingState
        var hapticPattern = try! HapticPattern(
            events: vanillaHapticEventGen
                .array(of: .always(2)).run(),
            parameters: []
        )

        @BindingState
        var prettyJSONFormattedDescription: String?
        
        // TODO: - this should be a view state, which we should scope down to.
        var hapticEvents: IdentifiedArrayOf<EditHapticEventFeature.State> {
            get {
                .init(uniqueElements: makeFrom(hapticPattern.events))
            }
            set {
                hapticPattern.events = newValue.elements.map(\.event)
            }
        }
        
        var isEngineInBadState: Bool {
            engineFailureDescription != nil
        }
    }
    
    enum Action: BindableAction {
        case onAppear
        case onDemoButtonTapped
        case onEngineCreation(HapticEngine)
        case onRandomizeButtonTapped
        case onDisplayButtonTapped
        case cancelPrettyJSONButtonTapped
        case onCopyPrettyJSONTapped
        case resetCopyImage
        case onRestartEngineButtonTapped
        
        case onFailure(Error)
        case onEngineFailure(Error)

        case hapticEvent(UUID, EditHapticEventFeature.Action)
        case binding(_ action: BindingAction<State>)
        
        case onFormattedDisplayDismissed
    }
    
    let client: HapticEngineClient
    let copyClient: CopyClient
    
    let encoder = JSONEncoder().then {
        $0.outputFormatting = .prettyPrinted
    }

    @Dependency(\.continuousClock) var clock
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
                        
            switch action {
            case .onAppear:
                return .run { send in
                    do {
                        let engine = try client.makeHapticEngine(
                            resetHandler: {
                                
                            },
                            stoppedHandler: { _ in }
                        )
                        try await engine.start()
                        await send(.onEngineCreation(engine))
                    } catch {
                        await send(.onFailure(error))
                    }
                }
                .merge(with: .send(.onDisplayButtonTapped))
                
            case .hapticEvent:
                return .none
            case .onEngineFailure(let error):
                state.engineFailureDescription = error.localizedDescription
                return .none
            case .onRestartEngineButtonTapped:
                
                // TODO: - reduce duplication
                return .run { send in
                    do {
                        let engine = try client.makeHapticEngine(
                            resetHandler: {
                                
                            },
                            stoppedHandler: { _ in }
                        )
                        try await engine.start()
                        await send(.onEngineCreation(engine))
                    } catch {
                        await send(.onFailure(error))
                    }
                }
                
            case .onFailure(let error):
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
            case .cancelPrettyJSONButtonTapped:
                state.prettyJSONFormattedDescription = nil
                return .none
            case .onCopyPrettyJSONTapped:
                state.copyImage = "checkmark.circle.fill"
                state.prettyJSONFormattedDescription.map(copyClient.copy)
                state.copyColor = .green

                return .run { send in
                    try await clock.sleep(for: .seconds(1))
                    await send(.resetCopyImage, animation: .bouncy)
                }
            case .resetCopyImage:
                state.copyImage = "square.on.square"
                state.copyColor = .blue
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

                    return .none

                } catch {
                    return .send(.onFailure(error))
                }
            case .binding:
                return .none

            case .onDisplayButtonTapped:
                
                do {
                    state.prettyJSONFormattedDescription = String(
                        data: try encoder.encode(state.hapticPattern),
                        encoding: .utf8
                    )
                } catch {
                    state.localizedError = error.localizedDescription
                }
                
                return .none
            case .onFormattedDisplayDismissed:
                state.prettyJSONFormattedDescription = nil
                return .none
            }
        }
        .forEach(
            \.hapticEvents,
             action: /HapticEngineFeature.Action.hapticEvent,
             element: {
                 EditHapticEventFeature()
             }
        )
    }
}

struct HapticButtonView: View {

    let store: StoreOf<HapticEngineFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack {
                    Text(viewStore.localizedError ?? "Haptic Pattern detail")
                    
                    if viewStore.isEngineInBadState {
                        Button(action: {
                            viewStore.send(.onRestartEngineButtonTapped)
                        }) {
                            Text("Restart Engine")
                                .font(.headline)
                                .padding()
                                .cornerRadius(10)
                        }
                    }
                        
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
                                        
                    Button(action: {
                        viewStore.send(.onDisplayButtonTapped)
                    }) {
                        Text("Show pretty JSON")
                            .font(.headline)
                            .padding()
                            .cornerRadius(10)
                    }
                                        
                    HStack {
                        Button(action: {
                            viewStore.send(.onDemoButtonTapped)
                        }) {
                            Text("Demo Haptic")
                                .font(.headline)
                                .padding()
                                .cornerRadius(10)
                        }

                        Button(action: {
                            viewStore.send(.onRandomizeButtonTapped)
                        }) {
                            Text("Randomize")
                                .font(.headline)
                                .padding()
                                .cornerRadius(10)
                        }
                    }
                }.onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .sheet(
                isPresented: viewStore.binding(
                    get: { $0.prettyJSONFormattedDescription != nil },
                    send: { _ in HapticEngineFeature.Action.onFormattedDisplayDismissed }
                ),
                content: {
                    NavigationView {
                        ScrollView {
                            viewStore.prettyJSONFormattedDescription.map {
                                Text($0)
                                    .padding()
                            }
                        }.toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    viewStore.send(.cancelPrettyJSONButtonTapped)
                                }
                            }
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    viewStore.send(.onCopyPrettyJSONTapped)
                                }) {
                                    Image(systemName: viewStore.copyImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(viewStore.copyColor)
                                }
                            }
                        }
                    }
                }
            )
        }
    }
}

#Preview {
    HapticButtonView(
        store: Store(
            initialState: HapticEngineFeature.State(),
            reducer: {
                HapticEngineFeature(client: .mock, copyClient: .mock)
                    ._printChanges()
            }
        )
    )
}

private let makeFrom = map(EditHapticEventFeature.State.init)
