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
            HStack {
                Text("eventType:")
                    .font(.title3)
                    .background(.gray)
                Text(viewStore.event.eventType.rawValue)
            }
            VStack(alignment: .leading) {
                Text("parameters:")
                    .font(.title3)
                    .background(.gray)
                
                ForEach(viewStore.event.parameters, id: \.parameterID) { param in
                    HStack {
                        Text("eventparameer")
                            .font(.title3)

                        Text(param.value.formatted())
                    }
                    .background(.green)
                }
                
            }

            HStack {
                Text("relativeTime:")
                    .font(.title3)
                    .background(.gray)

                Text(viewStore.event.relativeTime.formatted())
            }

            HStack {
                Text("duration:")
                    .font(.title3)
                    .background(.gray)

                Text(viewStore.event.duration.formatted())
            }
        }
    }
}
//
//#Preview {
//    HapticEventDetailView(
//        store: Store(
//            initialState: HapticEventDetailFeature.State(
//                event: .init(eventType: <#T##HapticEvent.EventType#>, parameters: <#T##[HapticEvent.EventParameter]#>, relativeTime: <#T##TimeInterval#>, duration: <#T##TimeInterval#>)
//            ),
//            reducer: {
//                HapticEventDetailFeature()
//            }
//        )
//    )
//}
