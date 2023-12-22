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
    
//    struct NamedPattern {
//        let name: String,
//        let pattern: Pattern
//        init(name: String, pattern: Pattern)
//    }
    
    struct State: Equatable {
        var engine: HapticEngine<Pattern>?
        var namedPatterns: IdentifiedArrayOf<Named<Pattern>> = []
        var errorString: String?
        
        @BindingState
        var scenePhase: ScenePhase = .active
    }

    enum Action {
        case onAppear
        case onTryTapped(Named<Pattern>.ID)
        case onEngineCreation(HapticEngine<Pattern>)
        case onScenePhaseChanged(ScenePhase, ScenePhase)
    }
    
    let namedLoaders: [Named<Loader<Pattern>>]
    let client: HapticEngineClient<Pattern>
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onScenePhaseChanged(let old, let new):
                switch (old, new) {
                case (.inactive, .active):
//                case (_, .background)
                    
                    return .run { [state] send in
                        do {
                            
                            try await state.engine?.start()
                        }
                        //                    await send(.onEngineCreation(engine))
                        
                    }
                default:
                    return .none
                }
                
                
            case .onAppear:
                // load your audio patterns
                do {
                    state.namedPatterns = try IdentifiedArray(
                        uniqueElements: namedLoaders
                            .map { try Named(
                                name: $0.name,
                                wrapped: $0.wrapped.load() // these are the loaded audio patterns.
                            ) },
                        id:  \.name
                    )
                } catch {
                    state.errorString = error.localizedDescription
                }
                                
                return
                    .run { send in
                        do {
                            let engine = try client.makeHapticEngine(
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
                            
                        }
                    }
            case .onEngineCreation(let engine):
                
                state.engine = engine
                return .none
            case .onTryTapped(let id):

                // TODO: - we need to be able to plug this pattern, into the engine.
                
                do {
                    
                    let zz = try state.namedPatterns[id: id].unwrapOrThrow()
                    let newPlayer = try state.engine?.makePlayer(zz.wrapped)
                    try newPlayer?.sendParameters(parameters: [
                        .init(parameterId: .hapticIntensityControl, value: 1, relativeTime: 0),
                        .init(parameterId: .audioVolumeControl, value: 1, relativeTime: 0)
                    ], atTime: HapticTimeImmediate)
                    try newPlayer?.start(HapticTimeImmediate)
                    
                    print("-=- done...")
                } catch {
                    state.errorString = error.localizedDescription
                }
                
                return .none
            }
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
