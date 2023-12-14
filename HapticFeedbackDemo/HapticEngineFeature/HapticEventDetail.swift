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
        let event: HapticEvent
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

struct HapticEventDetailView: View {
    let store: StoreOf<HapticEventDetailFeature>

    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack(alignment: .leading, spacing: 10) {
                Section {
                    Text(viewStore.event.eventType.rawValue)
                        .padding([.leading, .trailing], 8)
                } header: {
                    Text("eventType(CHHapticEvent):")
                        .font(.system(size: 16, weight: .bold))
                }

                Section {
                    ForEach(viewStore.event.parameters, id: \.parameterID) { param in
                        VStack(alignment: .leading) {
                            Text("value(Float): " + param.value.formatted())
                            Text("parameterID(CHHapticEvent.ParameterID): " + param.parameterID.rawValue)
                        }
                        .padding([.leading, .trailing], 8)
                    }
                } header: {
                    Text("parameters([CHHapticEventParameter]):")
                        .font(.system(size: 16, weight: .bold))
                }
                
                Section {
                    Text(viewStore.event.relativeTime.formatted())
                        .padding([.leading, .trailing], 8)
                } header: {
                    Text("relativeTime(TimeInterval):")
                        .font(.system(size: 16, weight: .bold))
                }
                
                Section {
                    Text(viewStore.event.duration.formatted())
                        .padding([.leading, .trailing], 8)
                } header: {
                    Text("duration(TimeInterval):")
                        .font(.system(size: 16, weight: .bold))
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
            }
        )
    )
}
