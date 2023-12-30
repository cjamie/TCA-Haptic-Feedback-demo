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
        var hapticPattern: HapticPattern
        
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
        case onEngineCreationResult(Result<HapticEngine<HapticPattern>, Error>)
        case onRandomizeButtonTapped
        case onDisplayButtonTapped
        case cancelPrettyJSONButtonTapped
        case onCopyPrettyJSONTapped
        case resetCopyImage
        case onToggleEngineStateButtonTapped
        case onEngineFailure(Error)
        case onDeleteEvent(IndexSet)
        case onAddEventButtonTapped(ScrollViewProxy)
        case scrollTo(ScrollViewProxy, UUID)
        case onMove(IndexSet, Int)

        case hapticEvent(UUID, EditHapticEventFeature.Action)
        case binding(_ action: BindingAction<State>)
        
        case onFormattedDisplayDismissed
        case delegate(Delegate)
        
        enum Delegate {
            case onDisappear(HapticPattern)
        }
    }
    
    let client: HapticEngineClient<HapticPattern>
    let copyClient: CopyClient
    
    let encoder = JSONEncoder().then {
        $0.outputFormatting = .prettyPrinted
    }
    
    let hapticEventGen: () -> HapticEvent
    
    @Dependency(\.continuousClock) var clock
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .onAppear:
                return startEngineEffect(engine: state.engine)
            case .hapticEvent:
                return .none
            case .onEngineFailure(let error):
                state.engineFailureDescription = error.localizedDescription
                return .none
            case .onAddEventButtonTapped(let proxy):
                
                let new = hapticEventGen()
                state.hapticPattern.events.append(new)
                
                return .run { [id = new.id] send in
                    try await clock.sleep(for: .milliseconds(100))
                    await send(
                        .scrollTo(proxy, id),
                        animation: .spring(.snappy, blendDuration: 0.3)
                    )
                }
            case .scrollTo(let proxy, let id):
                proxy.scrollTo(id, anchor: .top)

                return .none
            case let .onMove(offsets, destination):
                state.hapticEvents.move(
                    fromOffsets: offsets,
                    toOffset: destination
                )
                return .none
            case .onToggleEngineStateButtonTapped:
                if !state.isEngineInBadState {
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
            case .onDeleteEvent(let indexSet):
                state.hapticEvents.remove(atOffsets: indexSet)
                
                return .none
                
            case .onEngineCreationResult(let engineResult):

                switch engineResult {
                case .success(let engine):
                    state.engine = engine
                    state.engineFailureDescription = nil
                case .failure(let error):
                    state.engine = nil
                    state.engineFailureDescription = error.localizedDescription
                }

                return .none
                
            case .onRandomizeButtonTapped:
                
                for indice in state.hapticPattern.events.indices {
                    state.hapticPattern.events[indice]
                        .change(to: hapticEventGen())
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
                 EditHapticEventFeature(
                    hapticEventGen: vanillaHapticEventGen.run,
                    paramGen: hapticEventParam.run
                 )
             }
        )
    }
    
    // TODO: - implement real handlers for reset, and stopped..
    private func startEngineEffect(
        engine: HapticEngine<HapticPattern>?
    ) -> Effect<HapticEngineFeature.Action> {
        .run { send in
            do {
                // TODO: - port over EngineState into this reducer, to represent state of the engine. 
                let engine = try engine ?? client.makeHapticEngine(
                    resetHandler: {
                        print("-=- reset handler called.. ")
                    },
                    stoppedHandler: {
                        print("-=- stoppedHandler called.. \($0)")
                    }
                )
                
                try await engine.start()
                await send(.onEngineCreationResult(.success(engine)))
            } catch {
                await send(.onEngineCreationResult(.failure(error)))
            }
        }
    }
}

struct HapticButtonView: View {
    
    let store: StoreOf<HapticEngineFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: .zero) {
                Text(viewStore.generalTitle ?? "Haptic Pattern detail (\(viewStore.hapticEvents.count))")
                
                ScrollViewReader { proxy in
                    HStack {
                        Button(
                            action: { viewStore.send(.onToggleEngineStateButtonTapped) },
                            label: {
                                Text(viewStore.isEngineInBadState ? "Restart Engine" : "Stop Engine")
                                    .font(.headline)
                                    .padding()
                                    .cornerRadius(10)
                            }
                        )
                        Button(
                            action: { viewStore.send(.onAddEventButtonTapped(proxy)) },
                            label: {
                                HStack(spacing: .zero) {
                                    Image(systemName: "plus")
                                    Text("Event")
                                }
                            }
                        )
                    }

                    List {
                        ForEachStore(store.scope(
                            state: \.hapticEvents,
                            action: HapticEngineFeature.Action.hapticEvent
                        )) {
                            HapticEventDetailView(store: $0)
                        }
                        .onDelete { viewStore.send(.onDeleteEvent($0)) }
                        .onMove { indices, newOffset in
                            viewStore.send(.onMove(indices, newOffset))
                        }
                    }
                }
                
                Button(action: { viewStore.send(.onDisplayButtonTapped) }) {
                    Text("Show pretty JSON")
                        .font(.headline)
                        .padding()
                        .cornerRadius(10)
                }
                
                HStack {
                    Button(action: { viewStore.send(.onDemoButtonTapped) }) {
                        Text("Demo Haptic")
                            .font(.headline)
                            .padding()
                            .cornerRadius(10)
                    }
                    
                    Button(action: { viewStore.send(.onRandomizeButtonTapped) }) {
                        Text("Randomize")
                            .font(.headline)
                            .padding()
                            .cornerRadius(10)
                    }
                }
            }
            .onAppear { viewStore.send(.onAppear) }
            .onDisappear { viewStore.send(.delegate(.onDisappear(viewStore.hapticPattern))) }
            .sheet(
                isPresented: viewStore.binding(
                    get: { $0.prettyJSONFormattedDescription != nil },
                    send: { _ in HapticEngineFeature.Action.onFormattedDisplayDismissed }
                ),
                content: {
                    NavigationView {
                        ScrollView {
                            viewStore.prettyJSONFormattedDescription.map {
                                Text($0).padding()
                            }
                        }.toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    viewStore.send(.cancelPrettyJSONButtonTapped)
                                }
                            }
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: { viewStore.send(.onCopyPrettyJSONTapped) }) {
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
            initialState: HapticEngineFeature.State(
                hapticPattern: hapticPatternGen.run()
            ),
            reducer: {
                HapticEngineFeature(
                    client: .mock,
                    copyClient: .mock, 
                    hapticEventGen: vanillaHapticEventGen.run
                )
                    ._printChanges()
            }
        )
    )
}

private let makeFrom = map(EditHapticEventFeature.State.init)

