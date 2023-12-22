//
//  AudioEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/19/23.
//

import SwiftUI
import ComposableArchitecture
import CoreHaptics

// this will be able to produce sounds.. and we need an audio generator..
// under the hood, this is created by files, and not wave form generators.
struct PresetAudioEngineFeature<Pattern: Equatable>: Reducer {
    struct State: Equatable {
        var engine: HapticEngine<Pattern>?
        var namedPatterns: IdentifiedArrayOf<Named<Pattern>> = []
        var errorString: String?
     }

    enum Action {
        case onAppear
        case onTryTapped(Named<Pattern>.ID)
        case onEngineCreationResult(Result<HapticEngine<Pattern>, Error>)
        case onScenePhaseChanged(ScenePhase, ScenePhase)
    }
    
    let namedLoaders: [Named<Loader<Pattern>>]
    let client: HapticEngineClient<Pattern>
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onScenePhaseChanged(.inactive, .active):
                return state.engine.map { engine in
                   .run { send in
                       do {
                           try await engine.start()
                       } catch {
                           await send(.onEngineCreationResult(.failure(error)))
                       }
                   }
               } ?? createEngine(client: client)
                
            case .onScenePhaseChanged:

                return .none
            case .onAppear:
                do {
                    state.namedPatterns = try IdentifiedArray(
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

                state.engine = engine

                return .run { [engine] send in
                    do {
                        try await engine.start()
                    } catch {
                        await send(.onEngineCreationResult(.failure(error)))
                    }
                }
            case .onEngineCreationResult(.failure(let error)):
                state.engine = nil
                state.errorString = error.localizedDescription
            case .onTryTapped(let id):

                do {
                    
                    let pattern = try state.namedPatterns[id: id].unwrapOrThrow().wrapped

                    let newPlayer = try state.engine.unwrapOrThrow().makePlayer(pattern)

                    try newPlayer.sendParameters(parameters: [
                        .init(parameterId: .hapticIntensityControl, value: 1, relativeTime: 0),
                        .init(parameterId: .audioVolumeControl, value: 1, relativeTime: 0)
                    ], atTime: HapticTimeImmediate)

                    try newPlayer.start(HapticTimeImmediate)
                } catch {
                    state.errorString = error.localizedDescription
                }
            }

            return .none
        }
    }
}


struct PresetAudioEngineView<T: Equatable>: View {
    @Environment(\.scenePhase) var scenePhase

    @State var temp = ScenePhase.active
    let store: StoreOf<PresetAudioEngineFeature<T>>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                viewStore.errorString.map {
                    Text("somehting went wrong: " + $0)
                }
   
                ForEach(viewStore.namedPatterns) { namedPattern in
                    Text(namedPattern.name)
                    Button(action: {
                        viewStore.send(.onTryTapped(namedPattern.id))
                    }, label: {
                        Text("Try")
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

#Preview("Infra preview") {
    PresetAudioEngineView(
        store: Store(
            initialState: PresetAudioEngineFeature<CHHapticPattern>.State(),
            reducer: {
                PresetAudioEngineFeature(namedLoaders: Named.allCases, client: .liveCHHapticPattern)
                    ._printChanges()
            }
        )
    )
}
//
//extension ScenePhase: _Bindable {
//    public var wrappedValue: ScenePhase {
//        get {
//            self
//        }
//        nonmutating set(newValue) {
//            
//        }
//    }
//    
//    public typealias Value = ScenePhase
//}

private func createEngine<Pattern>(
    client: HapticEngineClient<Pattern>
) -> Effect<PresetAudioEngineFeature<Pattern>.Action> {
    .run { send in
        do {
            try await send(.onEngineCreationResult(.success(client.makeHapticEngine(
                resetHandler: {
                    print("-=- reset handler called.. ")
                },
                stoppedHandler: {
                    print("-=- stoppedHandler called.. \($0)")
                }
            ))))

        } catch {
            await send(.onEngineCreationResult(.failure(error)))
        }
    }
}
