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
// TODO: - we can have more use-case specific errors for more nuanced error handling

struct PresetAudioEngineFeature<P: Equatable>: Reducer {
    struct State: Equatable {

        // TODO: - these can be playyers instead of patterns.
        var basicPatterns: IdentifiedArrayOf<Named<P>> = []
        var advancedPatterns: IdentifiedArrayOf<Named<P>> = []

        // PatternPlayer caches
        var basicPatternPlayers: IdentifiedArrayOf<
            Identified<String, HapticPatternPlayer>
        > = []
        
        var advancedPatternPlayers: IdentifiedArrayOf<
            Identified<String, AdvancedHapticPatternPlayer>
        > = []
        
        
        var errorString: String?
        var engineState: EngineState<P> = .uninitialized
        
        var engine: HapticEngine<P>? {
            switch engineState {
            case .initialized(let engine, _):
                return engine
            case .uninitialized:
                return nil
            }
        }
        
        // MARK: - Equatable
        
        static func ==(
            lhs: PresetAudioEngineFeature<P>.State,
            rhs: PresetAudioEngineFeature<P>.State
        ) -> Bool {
            [
                lhs.errorString == rhs.errorString,
                lhs.engine == rhs.engine,
                lhs.engineState == rhs.engineState,
            ].allSatisfy { $0 }
        }
    }

    enum Action {
        case onAppear
        case onTryBasicTapped(Named<P>)
        case onEngineCreationResult(Result<HapticEngine<P>, Error>)
        case onEngineReset(HapticEngine<P>)
        case onEngineStopped(HapticEngine<P>, StoppedReason)
        case onBasicPlayersCreationResult(
            Result<IdentifiedArrayOf<Identified<String, HapticPatternPlayer>>, Error>
        )

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
                            try Named(name: $0.name, wrapped: $0.wrapped())
                        },
                        id: \.name
                    )
                } catch {
                    state.errorString = error.localizedDescription
                }
                
                return createEngine(client: client)

            case .onBasicPlayersCreationResult(.success(let basicPlayers)):
                state.basicPatternPlayers = basicPlayers
                
                return .none

            case .onBasicPlayersCreationResult(.failure(let error)):
                state.errorString = error.localizedDescription
                return .none

            case .onEngineCreationResult(.success(let engine)):
                state.engineState = .initialized(engine, .created)

                let base = startEngine(engine)

                return state.basicPatternPlayers.isEmpty 
                ? .concatenate(base, createBasicHapticPlayers(state: state))
                : base

            case .onEngineCreationResult(.failure(let error)):
                state.engineState = .uninitialized
                state.errorString = error.localizedDescription

            case .onTryBasicTapped(let basicPattern):
                let id = basicPattern.id
                return .concatenate(
                    ensureEngineIsInGoodState(
                        client: client,
                        engineState: state.engineState
                    ),
                    .run { [state] send in
                        let player = try state.basicPatternPlayers[id: id]?.value
                            ?? state.engine.unwrapOrThrow().makePlayer(
                                state.basicPatterns[id: id].unwrapOrThrow().wrapped
                            )
                                                
                        let params: [HapticDynamicParameter] = [
                            .init(parameterId: .hapticIntensityControl, value: 1, relativeTime: 0),
                            .init(parameterId: .audioVolumeControl, value: 1, relativeTime: 0)
                        ]
                        try player.sendParameters(parameters: params, atTime: HapticTimeImmediate)
                        try player.start(HapticTimeImmediate)
                    }
                )
            case .onEngineReset(let engine):
                state.engineState = .initialized(engine, .reset)

            case .onEngineStopped(let engine, let reason):
                state.engineState = .initialized(engine, .stopped(reason))
            }

            return .none
        }
    }

    private func ensureEngineIsInGoodState(
        client: HapticEngineClient<P>,
        engineState: EngineState<P>
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
                    resetHandler: { Task { [cache] in
                        if let cache {
                            await send(.onEngineReset(cache))
                        }
                    }},
                    stoppedHandler: { reason in Task { [cache] in
                        if let cache {
                            await send(.onEngineStopped(cache, reason))
                        }
                    }}
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
    
    private func createBasicHapticPlayers(state: State) -> Effect<Action> {
        .run(priority: .medium) { send in
            do {
                let basicPlayers = try state.basicPatterns.map {
                    Identified(
                        try state.engine.unwrapOrThrow(NSError(domain: "no engine present", code: -1)).makePlayer($0.wrapped),
                        id: $0.id
                    )
                }
                
                await send(.onBasicPlayersCreationResult(
                    .success(.init(uncheckedUniqueElements: basicPlayers))
                ))
            } catch {
                await send(.onBasicPlayersCreationResult(
                    .failure(error)
                ))
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
                        viewStore.send(.onTryBasicTapped(namedPattern))
                    }, label: {
                        Text(namedPattern.name)
                    })
                }
                
                // TODO: - finish this...
                ForEach(viewStore.advancedPatterns) { namedPattern in
                    Button(action: {
                        viewStore.send(.onTryBasicTapped(namedPattern))
                    }, label: {
                        Text(namedPattern.name)
                    })
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                viewStore.send(.onScenePhaseChanged(oldPhase, newPhase))
            }
        }
    }
}

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
