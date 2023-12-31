//
//  MicrophoneFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/30/23.
//

//import Foundation

import SwiftUI
import ComposableArchitecture

struct MicrophoneFeature: Reducer {
    struct State: Equatable {
        @BindingState
        var transcribedText: String = ""
    }

    enum Action: BindableAction {
        case onMicButtonTapped
        case stopButtonTapped
        case binding(_ action: BindingAction<State>)
        case onTranscriptUpdated(String)
        case onAppear
        case timerTick
        case stopTranscribing
    }
    
    let speech: SpeechClient
    let hapticsClient: HapticsClient

    @Dependency(\.continuousClock) var clock

    private enum CancelId {
        case stopTranscribing
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .stopTranscribing:
                return .run { send in
                    await speech.stop()
                }
            case .timerTick:
                hapticsClient.generators.randomElement()?.value.run(1)
                return .none
            case .onAppear:
                return .none
            case .onMicButtonTapped:
                return .run { send in
                    for try await transcript in speech.start() {
                        await send(.onTranscriptUpdated(transcript))
                    }
                }
            case .stopButtonTapped:
                return .run { send in
                    await speech.stop()
                }
            case .onTranscriptUpdated(let string):
                state.transcribedText = string
                hapticsClient.generators[.medium]!.run(nil)

                return .run { send in
                    try await clock.sleep(for: .seconds(3))
                    await send(.stopTranscribing)
                }.cancellable(
                    id: CancelId.stopTranscribing,
                    cancelInFlight: true
                )
                    
            case .binding:
                return .none
            }
        }
    }
}

struct MicrophoneView: View {
    let store: StoreOf<MicrophoneFeature>

    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack {
                TextEditor(text: viewStore.$transcribedText)
                    .padding()
                    .background(Color(UIColor.systemGray6))

                HStack {
                    Button(action: {
                        store.send(.onMicButtonTapped)
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.title)
                    }
                    
                    Button(action: {
                        store.send(.stopButtonTapped)
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                    }
                }
                .padding()
            }
            .onAppear { viewStore.send(.onAppear) }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MicrophoneView(
            store: .init(
                initialState: MicrophoneFeature.State(),
                reducer: {
                    MicrophoneFeature(
                        speech: .mock, 
                        hapticsClient: .mock
                    )
                }
            )
        )
    }
}
