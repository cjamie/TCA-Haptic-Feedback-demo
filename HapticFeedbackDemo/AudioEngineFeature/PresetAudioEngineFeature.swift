//
//  AudioEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/19/23.
//

import SwiftUI
import ComposableArchitecture

// this will be able to produce sounds.. and we need an audio generator..
// under the hood, this is created by files, and not wave form generators.
struct PresetAudioEngineFeature<P: Equatable>: Reducer {
    struct State: Equatable {
        
        enum EngineState: Equatable {
            enum State: Equatable {
                case created
                case started
                case reset
                case stopped(StoppedReason)
            }
            
            case initialized(HapticEngine<P>, State)
            case uninitialized
            
            var engine: HapticEngine<P>? {
                switch self {
                case .initialized(let engine, _):
                    return engine
                case .uninitialized:
                    return nil
                }
            }
        }

        // TODO: - these can be playyers instead of patterns.
        var basicPatterns: IdentifiedArrayOf<Named<P>> = []
        var errorString: String?
        var engineState: EngineState = .uninitialized
        
        var engine: HapticEngine<P>? {
            engineState.engine
        }
    }

    enum Action {
        case onAppear
        case onTryTapped(Named<P>.ID)
        case onEngineCreationResult(Result<HapticEngine<P>, Error>)
        case onEngineReset(HapticEngine<P>)
        case onEngineStopped(HapticEngine<P>, StoppedReason)

        case onScenePhaseChanged(ScenePhase, ScenePhase)
    }
    
    private enum CancelID {
        case engineCreation
    }
    
    let namedLoaders: [Named<Loader<P>>]
    let client: HapticEngineClient<P>
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onScenePhaseChanged(.inactive, .active):
                return ensureEngineIsInGoodState(
                    client: client,
                    engineState: state.engineState
                )
            case .onScenePhaseChanged:
                break

            case .onAppear:
                do {
                    state.basicPatterns = try IdentifiedArray(
                        uniqueElements: namedLoaders.map {
                            try Named(
                                name: $0.name,
                                wrapped: $0.wrapped()
                            )
                        },
                        id: \.name
                    )
                } catch {
                    state.errorString = error.localizedDescription
                }
                                
                return createEngine(client: client)
            case .onEngineCreationResult(.success(let engine)):
                state.engineState = .initialized(engine, .created)
                return startEngine(engine)

            case .onEngineCreationResult(.failure(let error)):
                state.engineState = .uninitialized
                state.errorString = error.localizedDescription

            case .onTryTapped(let id):
                return .concatenate(
                    ensureEngineIsInGoodState(
                        client: client,
                        engineState: state.engineState
                    ),
                    .run(operation: { [state] send in
                        let pattern = try state.basicPatterns[id: id].unwrapOrThrow().wrapped
                        let newPlayer = try state.engine.unwrapOrThrow().makePlayer(pattern)
                        try newPlayer.sendParameters(parameters: [
                            .init(parameterId: .hapticIntensityControl, value: 1, relativeTime: 0),
                            .init(parameterId: .audioVolumeControl, value: 1, relativeTime: 0)
                        ], atTime: HapticTimeImmediate)
                        
                        try newPlayer.start(HapticTimeImmediate)
                    })
                )
            case .onEngineReset(let engine):
                state.engineState = .initialized(engine, .reset)
                return .none
            case .onEngineStopped(let engine, let reason):
                state.engineState = .initialized(engine, .stopped(reason))
                return .none
            }

            return .none
        }
    }

    private func ensureEngineIsInGoodState(
        client: HapticEngineClient<P>,
        engineState: State.EngineState
    ) -> Effect<Action> {
        switch engineState {
        case .initialized(_, .started):
            return .none
        case .initialized(let engine, _):
            return startEngine(engine)
        case .uninitialized:
            return createEngine(client: client)
        }
    }
    
    private func createEngine(client: HapticEngineClient<P>) -> Effect<Action> {
        .run { send in
            do {
                var cache: HapticEngine<P>?
                
                let engine = try client.makeHapticEngine(
                    resetHandler: {
                        Task { [cache] in
                            if let cache {
                                await send(.onEngineReset(cache))
                            }
                        }
                    },
                    stoppedHandler: { reason in
                        Task { [cache] in
                            if let cache {
                                await send(.onEngineStopped(cache, reason))
                            }
                        }
                    }
                )
                
                cache = engine
                
                await send(.onEngineCreationResult(.success(engine)))
            } catch {
                await send(.onEngineCreationResult(.failure(error)))
            }
        }.debounce(id: CancelID.engineCreation, for: .milliseconds(100), scheduler: DispatchQueue.main)
    }
    
    
    private func startEngine(_ engine: HapticEngine<P>) -> Effect<Action> {
        .run { send in
            do {
                try await engine.start()
            } catch {
                await send(.onEngineCreationResult(.failure(error)))
            }
        }
    }
}

struct PresetAudioEngineView<T: Equatable>: View {
    @Environment(\.scenePhase) var scenePhase

    let store: StoreOf<PresetAudioEngineFeature<T>>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 20) {
                viewStore.errorString.map {
                    Text("Something went wrong: " + $0)
                }
   
                ForEach(viewStore.basicPatterns) { namedPattern in
                    Button(action: {
                        viewStore.send(.onTryTapped(namedPattern.id))
                    }, label: {
                        Text(namedPattern.name)
                    })
                }
                                
                Text("audio engine viw")
                    .onAppear {
                        viewStore.send(.onAppear)
                    }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                viewStore.send(.onScenePhaseChanged(oldPhase, newPhase))
            }
        }
    }
}

// TODO: - repair the preset.. should not import CoreHaptics
#Preview("Infra preview") {
    PresetAudioEngineView(
        store: Store(
            initialState: PresetAudioEngineFeature<HapticPattern>.State(),
            reducer: {
                PresetAudioEngineFeature(
                    namedLoaders: (3...8).map {
                        .init(name: String($0), wrapped: .init(load: hapticPatternGen.run))
                    },
                    client: .mock
                )._printChanges()
            }
        )
    )
}
