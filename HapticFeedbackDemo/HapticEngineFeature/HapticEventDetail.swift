//
//  HapticEventDetail.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import SwiftUI
import ComposableArchitecture

// TODO: - this is specifically for haptics.. will create another for audio.
struct EditHapticEventFeature: Reducer {
    struct State: Equatable, Identifiable {
        @BindingState
        var event: HapticEvent
        
        var id: UUID {
            event.id
        }
    }
    
    enum Action: BindableAction {
        case onAppear
        case binding(_ action: BindingAction<State>)
        case onDelete(IndexSet)
        case onRandomizeButtonTapped
        case onAddEventParameterButtonTapped(ScrollViewProxy)
        case scrollTo(ScrollViewProxy, UUID)
        case onMove(IndexSet, Int)
    }
    
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                return .none
                
            case .onDelete(let indexSet):
                state.event.parameters.remove(atOffsets: indexSet)
                return .none
                
            case .onRandomizeButtonTapped:
                let new = vanillaHapticEventGen.run()

                var copy = state.event
                copy.eventType = new.eventType
                copy.relativeTime = new.relativeTime
                copy.duration = new.duration

                for indice in copy.parameters.indices {
                    copy.parameters[indice].change(to: hapticEventParam.run())
                }

                state.event = copy
                
                return .none
                
            case .onAddEventParameterButtonTapped(let proxy):
                // TODO: injection
                let new = hapticEventParam.run()
                state.event.parameters.append(new)
                return .run { [id = new.id, proxy] send in
                    try await clock.sleep(for: .milliseconds(100))
                    await send(.scrollTo(proxy, id), animation: .spring(.snappy, blendDuration: 0.3))
                }
            case .scrollTo(let proxy, let id):
                proxy.scrollTo(id, anchor: .top)

                return .none
            case let .onMove(offsets, destination):
                state.event.parameters.move(
                    fromOffsets: offsets,
                    toOffset: destination
                )
                return .none
            }
        }
    }
}

struct HapticEventDetailView: View {
    let store: StoreOf<EditHapticEventFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 10) {
                Section {
                    Picker("Select an option", selection: viewStore.$event.eventType) {
                        ForEach(HapticEvent.EventType.hapticCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("eventType(CHHapticEvent):")
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                }
                                    
                ScrollViewReader { proxy in
                    VStack {
                        HStack {
                            Text("parameters([CHHapticEventParameter]):")
                                .font(.system(size: 16, weight: .bold))
                            
                            Button(action: {
                                viewStore.send(.onAddEventParameterButtonTapped(proxy))
                            }, label: {
                                HStack(spacing: .zero) {
                                    Image(systemName: "plus")
                                    Text("Parameter")
                                }
                            })
                        }
                        
                        List {
                            ForEach(viewStore.$event.parameters, id: \.id) { param in
                                VStack(alignment: .leading) {
                                    Slider(value: param.value, in: param.wrappedValue.range)
                                    Text("value(Float): " + param.wrappedValue.value.formatted())
                                        .font(.subheadline)
                                    Text("parameterID(CHHapticEvent.ParameterID): " + param.wrappedValue.parameterID.rawValue)
                                        .font(.caption)
                                }.id(param.wrappedValue.id)
                            }
                            .onDelete { viewStore.send(.onDelete($0)) }
                            .onMove { indices, newOffset in
                                viewStore.send(.onMove(indices, newOffset))
                            }
                        }
                        .frame(height: 300)
                    }
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
                
//                Button(action: {
//                    viewStore.send(.onRandomizeButtonTapped, animation: .bouncy)
//                }) {
//                    Text("Randomize")
//                }
            }
            .onAppear { viewStore.send(.onAppear) }
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
