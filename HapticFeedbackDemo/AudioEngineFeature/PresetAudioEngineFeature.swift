//
//  AudioEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/19/23.
//

import SwiftUI
import ComposableArchitecture


// this will be able to produce sounds.. and we need an audio generator..

struct PresetAudioEngineFeature: Reducer {
    struct State: Equatable {
        
    }

    enum Action {
        case onAppear
    }
    

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                
                
                return .none
            }
        }
    }
}


struct PresetAudioEngineView: View {
    
    let store: StoreOf<PresetAudioEngineFeature>

    var body: some View {
        Text("audio engine view")
    }
}

#Preview {
    PresetAudioEngineView(
        store: Store(
            initialState: PresetAudioEngineFeature.State(),
            reducer: {
                PresetAudioEngineFeature()
            }
        )
    )
}
