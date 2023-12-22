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
        var engine: HapticEngine<HapticPattern>?
        var namedPatterns: IdentifiedArrayOf<Named<Pattern>> = []
        var errorString: String?
        
    }

    enum Action {
        case onAppear
        case onTryTapped(Named<Pattern>.ID)
    }
    
    let namedLoaders: [Named<Loader<Pattern>>]
    let client: HapticEngineClient<HapticPattern>
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
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
                        } catch {
                            
                        }
                    }
            case .onTryTapped(let id):

                // TODO: - we need to be able to plug this pattern, into the engine.
                state.namedPatterns[id: id]?.wrapped
                return .none
            }
        }
    }
}


struct PresetAudioEngineView<T: Equatable>: View {
    
    let store: StoreOf<PresetAudioEngineFeature<T>>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
   
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
        }
    }
}

#Preview("Infra preview") {
    PresetAudioEngineView(
        store: Store(
            initialState: PresetAudioEngineFeature<CHHapticPattern>.State(),
            reducer: {
                PresetAudioEngineFeature(namedLoaders: Named.allCases, client: .mock)
                    ._printChanges()
            }
        )
    )
}
