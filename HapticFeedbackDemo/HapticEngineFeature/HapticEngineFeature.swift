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
        
        var identifiedFormattedString: Identified<UUID, String>? {
            get {
                prettyJSONFormattedDescription.map {
                    Identified($0, id: uuidGen.run())
                } ?? nil
            }
            set {
                
            }
        }
    }
    
    enum Action: BindableAction {
        case onAppear
        case onDemoButtonTapped
        case onEngineCreation(HapticEngine)
        case onRandomizeButtonTapped
        case onDisplayButtonTapped
        
        case onFailure(Error)

        case hapticEvent(UUID, EditHapticEventFeature.Action)
        case binding(_ action: BindingAction<State>)
        
        case formattedDisplayDismissed
    }
    
    let client: HapticEngineClient
    
    let encoder = JSONEncoder().then {
        $0.outputFormatting = .prettyPrinted
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    do {
                        let engine = try client.makeHapticEngine()
                        try await engine.start()
                        await send(.onEngineCreation(engine))
                    } catch {
                        await send(.onFailure(error))
                    }
                }
                //.merge(with: .send(.changeFormatted))
            case .hapticEvent:
                return .none

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
                state.prettyJSONFormattedDescription = (try? encoder.encode(state.hapticPattern))
                    .flatMap { String(data: $0, encoding: .utf8) }

                return .none
            case .formattedDisplayDismissed:
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
//        .onChange(of: \.hapticPattern) { _, newValue in
//            Reduce { state, _ in
//                .send(.changeFormatted).throttle(
//                    id: CancelID.throttleFormatted,
//                    for: .seconds(1),
//                    scheduler: DispatchQueue.main,
//                    latest: true
//                )
//            }
//        }
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
                    
//                    // TODO: - handle focus state changes (because of keyboard)
//                    viewStore.$formattedString.unwrap().map {
//                        TextField("Enter text here", text: $0, axis: .vertical)
//                            .padding()
//                            .background(.green)
//                            .frame(height: 200)
//                            .disabled(true)
//                    }
                    
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
            .sheet(isPresented: viewStore.binding(
                get: { $0.prettyJSONFormattedDescription != nil },
                send: { _ in HapticEngineFeature.Action.formattedDisplayDismissed }
            ), content: {                
                ScrollView {
                    if let jsonText = viewStore.prettyJSONFormattedDescription {
                        Text(jsonText)
                            .background(.green)
                    }
                }.padding(.zero)
            })
            
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

func asas() {
//    Identified(<#T##value: Value##Value#>, id: <#T##Hashable#>)
}
