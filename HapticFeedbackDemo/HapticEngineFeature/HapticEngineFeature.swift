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
        var engine: HapticEngine<HapticPattern>?
        var generalTitle: String?
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
        case onEngineCreation(HapticEngine<HapticPattern>)
        case onRandomizeButtonTapped
        case onDisplayButtonTapped
        case cancelPrettyJSONButtonTapped
        case onCopyPrettyJSONTapped
        case resetCopyImage
        case onToggleEngineStateButtonTapped
        case onEngineFailure(Error)
        
        case hapticEvent(UUID, EditHapticEventFeature.Action)
        case binding(_ action: BindingAction<State>)
        
        case onFormattedDisplayDismissed
    }
    
    let client: HapticEngineClient<HapticPattern>
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
                return startEngineEffect(engine: state.engine)
                //                    .merge(with: .send(.onDisplayButtonTapped))
            case .hapticEvent:
                return .none
            case .onEngineFailure(let error):
                state.engineFailureDescription = error.localizedDescription
                return .none
            case .onToggleEngineStateButtonTapped:
                if state.isEngineInBadState {
                    state.engineFailureDescription = nil
                    
                    return .run { [state] send in
                        do {
                            try await state
                                .engine
                                .unwrapOrThrow()
                                .stop()
                            
                            
                        } catch {
                            await send(.onEngineFailure(error))
                        }
                    }
                    
                } else {
                    return startEngineEffect(engine: state.engine)
                }
                
                
            case .onEngineCreation(let engine):
                state.engine = engine
                state.engineFailureDescription = nil
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
                state.engineFailureDescription = nil
                state.generalTitle = nil
                
                guard client.supportsHaptics() else {
                    state.generalTitle = "Device does not support haptics."
                    return .none
                }
                
                do {
                    try state.engine
                        .unwrapOrThrow()
                        .makePlayer(state.hapticPattern)
                        .start(HapticTimeImmediate)
                    
                    return .none
                    
                } catch {
                    return .send(.onEngineFailure(error))
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
                    state.generalTitle = error.localizedDescription
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
    
    // TODO: - implement real handlers for reset, and stopped..
    private func startEngineEffect(
        engine: HapticEngine<HapticPattern>?
    ) -> Effect<HapticEngineFeature.Action> {
        .run { send in
            do {
                let engine = try engine ?? client.makeHapticEngine(
                    resetHandler: {
                        print("-=- reset handler called.. ")
                    },
                    stoppedHandler: {
                        print("-=- stoppedHandler called.. \($0)")
                    }
                )
                
                try await engine.start()
                await send(.onEngineCreation(engine))
            } catch {
                await send(.onEngineFailure(error))
            }
        }
    }
}

struct HapticButtonView: View {
    
    let store: StoreOf<HapticEngineFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Text(viewStore.generalTitle ?? "Haptic Pattern detail")
                Button(action: {
                    viewStore.send(.onToggleEngineStateButtonTapped)
                }) {
                    Text(viewStore.isEngineInBadState ? "Restart Engine" : "Stop Engine")
                        .font(.headline)
                        .padding()
                        .cornerRadius(10)
                }
                
                // TODO: - add an add button here...
                if !viewStore.isEngineInBadState {
                    
                    ScrollViewReader { proxy in
                        List {
                            ForEachStore(store.scope(
                                state: \.hapticEvents,
                                action: HapticEngineFeature.Action.hapticEvent
                            )) {
                                HapticEventDetailView(store: $0)
                            }.onDelete {
                                print("-=- finally.. \($0)")
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
                }
            }
            .onAppear { viewStore.send(.onAppear) }
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
