//
//  HapticsFeature.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import SwiftUI
import ComposableArchitecture

struct HapticsFeature: Reducer {
    struct State: Equatable {
        @BindingState
        var selectedHapticType = BasicHaptic
            .allCases
            .randomElement() ?? .light
        
        @BindingState
        var intensity: CGFloat?
        var supportsHaptics = false
        
        var userAudit: String?
        var supportsHapticsTitle = ""
        
        var intensityTitle: String {
            intensity.map { "Intensity: \($0.formatted())" } ?? "No intensity"
        }
    }
    
    // TODO: - need to check out caspeathable
    //    @CasePathable
    enum Action: BindableAction {
        case binding(_ action: BindingAction<State>)
        case onHapticTapped(BasicHaptic)
        case onAppear
        case onPrepareButtonTapped
        case onRetriggerButtonTapped

        case userAudit(String)
        case clearAudit
    }
    
    let client: HapticsClient
    
    @Dependency(\.continuousClock) var clock
    
    private enum CancelID {
        case auditDebounce
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onHapticTapped(let haptic):
                state.selectedHapticType = haptic
                client.generators[haptic]?.run(state.intensity)
                
                return .none
                
            case .onAppear:
                state.supportsHaptics = client.supportsHaptics()
                state.supportsHapticsTitle = "SupportsHaptics: \(client.supportsHaptics())"
                return .none
                
            case .onPrepareButtonTapped:
                client.generators[state.selectedHapticType]?.prepare()
                return .none
                
            case .userAudit(let userAudit):
                state.userAudit = userAudit
                
                return .run { send in
                    try await clock.sleep(for: .seconds(5))
                    await send(.clearAudit)
                }.cancellable(id: CancelID.auditDebounce, cancelInFlight: true)
                
            case .clearAudit:
                state.userAudit = nil
                return .none
            case .onRetriggerButtonTapped:
                client.generators[state.selectedHapticType]?.run(state.intensity)

                return .none
            }
        }
        Reduce { state, action in
            switch action {
            case .userAudit, .binding, .clearAudit:
                return .none
            default:
                return .send(.userAudit("\(action)"))
            }
        }
    }
}

struct HapticMenuApp: View {
    let store: StoreOf<HapticsFeature>
    
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            ScrollView(showsIndicators: false) {
                VStack {
                    Text("Haptic Menu App: \(viewStore.selectedHapticType.rawValue)")
                        .font(.title)
                    Text(viewStore.supportsHapticsTitle)
                        .foregroundStyle(viewStore.supportsHaptics ? .green : .red)
                    
                    if case .feedback = viewStore.selectedHapticType.category {
                        VStack {
                            Toggle(
                                viewStore.intensityTitle,
                                isOn: viewStore.binding(
                                    get: { $0.intensity != nil },
                                    send: { .set(\.$intensity, $0 ? 0.5 : nil) }
                                )
                            )
                            
                            if let intensity = viewStore.$intensity.unwrap() {
                                Slider(value: intensity, in: 0...1)
                            }
                        }
                        .padding()
                    }
                    
                    VStack {
                        ForEach(BasicHaptic.allCases, id: \.self) { hapticType in
                            Button(action: {
                                viewStore.send(.onHapticTapped(hapticType))
                            }) {
                                Text(hapticType.rawValue)
                                    .font(.headline)
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(viewStore.selectedHapticType == hapticType ? Color.red : .blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .onAppear { viewStore.send(.onAppear) }
                    .padding()
                    
                    HStack {
                        Button("Prepare \(viewStore.selectedHapticType.rawValue) generator") {
                            viewStore.send(.onPrepareButtonTapped)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("retrigger \(viewStore.selectedHapticType.rawValue)") {
                            viewStore.send(.onRetriggerButtonTapped)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    viewStore.userAudit.map {
                        Text($0)
                            .font(.title)
                            .padding()
                    }
                }
                .navigationTitle("Haptic Demo")
            }
        }
    }
}

#Preview {
    HapticMenuApp(store: Store(
        initialState: HapticsFeature.State(),
        reducer: {
            HapticsFeature(client: .mock)
        }
    ))
}
