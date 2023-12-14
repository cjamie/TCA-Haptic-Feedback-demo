//
//  HapticEventDetail.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import SwiftUI
import ComposableArchitecture



struct HapticEventDetailFeature: Reducer {
    struct State: Equatable {
        @BindingState
        var event: HapticEvent
//        var eventType: EventType
//        var parameters: [EventParameter]
//        var relativeTime: TimeInterval
//        var duration: TimeInterval

    }
    
    enum Action: BindableAction {
        case onAppear
        case binding(_ action: BindingAction<State>)
        case onDeleteParameters(IndexSet)
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
                print("-=- index? \(indexSet)")
                
                state.event.parameters.remove(atOffsets: indexSet)
                return .none
            }
        }
    }
}

struct HapticEventDetailView: View {
    let store: StoreOf<HapticEventDetailFeature>

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
                        Text("parameters([CHHapticEventParameter]):")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    Section {
                        Slider(value: viewStore.$event.relativeTime, in: 0...10)
                    } header: {
                        Text("relativeTime(TimeInterval): \(viewStore.event.relativeTime.formatted())")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    Section {
                        Slider(value: viewStore.$event.duration, in: 0...10)
                    } header: {
                        Text("duration(TimeInterval):\(viewStore.event.duration.formatted())")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
        }
    }
}

#Preview {
    HapticEventDetailView(
        store: Store(
            initialState: HapticEventDetailFeature.State(
                event: .dynamicMock
            ),
            reducer: {
                HapticEventDetailFeature()
                    ._printChanges()
            }
        )
    )
    .padding()
}
