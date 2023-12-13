//
//  HapticEngineFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import SwiftUI
import ComposableArchitecture

struct HapticEngineFeature: Reducer {
    struct State: Equatable {
        var engine: HapticEngine?
        var localizedError: String?
        // TODO: - injection
        
        @BindingState
        var hapticPattern = try! HapticPattern(
            events: [
                HapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        .init(parameterID: .hapticIntensity, value: 1.0),
                        .init(parameterID: .hapticSharpness, value: 1.0),
                    ],
                    relativeTime: 0,
                    duration: 1
                )
            ],
            parameters: []
        )
        var formattedString: String?
    }
    
    enum Action: BindableAction {
        case onAppear
        case onDemoButtonTapped
        case onEngineCreation(HapticEngine)
        case onCreationFailed(Error)
        
        case binding(_ action: BindingAction<State>)
    }
    
    let client: HapticEngineClient
    let encoder = JSONEncoder.init()

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                encoder.outputFormatting = .prettyPrinted
                state.formattedString = (try? encoder.encode(state.hapticPattern))
                    .flatMap { String(data: $0, encoding: .utf8) }

                return .run { send in
                    do {
                        let engine = try client.makeHapticEngine()
                        await send(.onEngineCreation(engine))
                        try await engine.start()
                    } catch {
                        await send(.onCreationFailed(error))
                    }
                }

            case .onCreationFailed(let error):
                state.localizedError = error.localizedDescription
                return .none
                
            case .onEngineCreation(let engine):
                state.engine = engine
                return .none

            case .onDemoButtonTapped:
                guard client.supportsHaptics() else {
                    state.localizedError = "Device does not support haptics."
                    return .none
                }
                
                do {
                    try state.engine
                        .unwrapOrThrow()
                        .makePlayer(state.hapticPattern)
                        .start(HapticTimeImmediate)
                } catch {
                    print("Error generating haptic feedback: \(error.localizedDescription)")
                }

                return .none
            case .binding:
                return .none
            }
        }
    }
}

struct HapticButtonView: View {

    let store: StoreOf<HapticEngineFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack {
                    
                    Text("Haptic Pattern detail")
                    
                    Section("Events") {
                        VStack(alignment: .leading) {
                            ForEach(viewStore.hapticPattern.events) { event in
//                                HStack {
//                                    Text("eventType:")
//                                        .font(.title3)
//                                        .background(.gray)
//                                    Text(event.eventType.rawValue)
//                                }
//                                VStack(alignment: .leading) {
//                                    Text("parameters:")
//                                        .font(.title3)
//                                        .background(.gray)
//                                    
//                                    ForEach(event.parameters, id: \.parameterID) { param in
//                                        HStack {
//                                            Text("eventparameer")
//                                                .font(.title3)
//
//                                            Text(param.value.formatted())
//                                        }
//                                        .background(.green)
//                                    }
//                                    
//                                }
//
//                                HStack {
//                                    Text("relativeTime:")
//                                        .font(.title3)
//                                        .background(.gray)
//
//                                    Text(event.relativeTime.formatted())
//                                }
//
//                                HStack {
//                                    Text("duration:")
//                                        .font(.title3)
//                                        .background(.gray)
//
//                                    Text(event.duration.formatted())
//                                }
                            }
                        }
                    }
                    
                    
//                    viewStore.formattedString.map {
//                        Text($0)
//                            .lineLimit(nil)
//                    }

                    Button(
                        action: { viewStore.send(.onDemoButtonTapped) }
                    ) {
                        Text("Tap Me!")
                            .font(.headline)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .onAppear {
                        viewStore.send(.onAppear)
                    }
                }
            }
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


