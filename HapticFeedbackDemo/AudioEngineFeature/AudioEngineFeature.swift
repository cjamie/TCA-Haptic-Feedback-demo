//
//  AudioEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/19/23.
//

import SwiftUI
import ComposableArchitecture
//import AVFoundation

struct AudioEngineFeature: Reducer {
    struct State: Equatable {
        
    }

    enum Action {
        
    }
    

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            }
        }
    }
}


struct AudioEngineView: View {
    
    let store: StoreOf<AudioEngineFeature>

    var body: some View {
        Text("audio engine view")
    }
}

#Preview {
    AudioEngineView.init(
        store: Store.init(
            initialState: AudioEngineFeature.State(),
            reducer: {
                AudioEngineFeature()
            }
        )
    )
}
