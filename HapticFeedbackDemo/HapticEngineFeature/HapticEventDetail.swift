//
//  HapticEventDetail.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import SwiftUI
import ComposableArchitecture



struct EditHapticEventFeature: Reducer {
    struct State: Equatable {
        @BindingState
        var event: HapticEvent
    }
    
    enum Action: BindableAction {
        case onAppear
        case binding(_ action: BindingAction<State>)
        case onDeleteParameters(IndexSet)
        case onRandomizeButtonTapped
        case onAddParameterButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                return .none

            case .onDeleteParameters(let indexSet):
                state.event.parameters.remove(atOffsets: indexSet)
                return .none

            case .onRandomizeButtonTapped:
                state.event = .dynamicMock
                return .none
            case .onAddParameterButtonTapped:
                var counter = state.event.parameters.map(\.parameterID)
                
                let all = Set(HapticEvent.EventParameter.ParameterID.allCases)
                
                let eligible = all.subtracting(counter)
                
                let makeNewParameterWithId: (HapticEvent.EventParameter.ParameterID) -> HapticEvent.EventParameter = { _ in fatalError() }
                
//                if let unUsedParameterId = eligible.randomElement() {
//                    state.event.parameters.append(makeNewParameterWithId(unUsedParameterId))
//                } else {
//                    state.
//                }
                
                
                return .none
            }
        }
    }
}

struct HapticEventDetailView: View {
    let store: StoreOf<EditHapticEventFeature>

    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Section {
                        Picker("Select an option", selection: viewStore.$event.eventType) {
                            ForEach(HapticEvent.EventType.allCases, id: \.self) { option in
                                Text(option.rawValue)
                                    .padding([.leading, .trailing], 8)
                            }
                        }
                        .pickerStyle(.wheel)
                    } header: {
                        Text("eventType(CHHapticEvent): \(viewStore.event.eventType.rawValue)")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    Section {
                        List {
                            ForEach(viewStore.$event.parameters, id: \.parameterID) { param in
                                VStack(alignment: .leading) {
                                    Slider(value: param.value, in: 0...1)
                                    Text("value(Float): " + param.wrappedValue.value.formatted())
                                    Text("parameterID(CHHapticEvent.ParameterID): " + param.wrappedValue.parameterID.rawValue)
                                }
                                .padding([.leading, .trailing], 8)
                            }
                            .onDelete {
                                viewStore.send(.onDeleteParameters($0))
                            }
                        }.frame(height: 300)
                    } header: {
                        
                        HStack {
                            Text("parameters([CHHapticEventParameter]):")
                                .font(.system(size: 16, weight: .bold))
                            
                            Button(action: {
                                viewStore.send(.onAddParameterButtonTapped)
                            }, label: {
                                Text("add")
                            })
                        }
                    }
                    
//                    Section {
//                        Slider(value: viewStore.$event.relativeTime, in: 0...10)
//                    } header: {
//                        Text("relativeTime(TimeInterval): \(viewStore.event.relativeTime.formatted())")
//                            .font(.system(size: 16, weight: .bold))
//                    }
//                    
//                    Section {
//                        Slider(value: viewStore.$event.duration, in: 0...10)
//                    } header: {
//                        Text("duration(TimeInterval):\(viewStore.event.duration.formatted())")
//                            .font(.system(size: 16, weight: .bold))
//                    }
//                                        
//                    Button(action: {
//                        viewStore.send(.onRandomizeButtonTapped)
//                    }) {
//                        Text("Randomize")
//                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }.navigationTitle("Edit Haptic Event")
        }
    }
}

#Preview {
    NavigationView {
        HapticEventDetailView(
            store: Store(
                initialState: EditHapticEventFeature.State(
                    event: .dynamicMock
                ),
                reducer: {
                    EditHapticEventFeature()
                        ._printChanges()
                }
            )
        )
        .padding()
    }
}
