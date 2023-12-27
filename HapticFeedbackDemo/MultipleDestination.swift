//
//  MultipleDestination.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/26/23.
//

import ComposableArchitecture
import SwiftUI


struct MultipleDestination: Reducer {
    
    struct Destination: Reducer {
        enum State: Equatable {
            // basic haptics.
            case drillDownBasic(HapticsFeature.State)
            case popoverBasic(HapticsFeature.State)
            case sheetBasic(HapticsFeature.State)
            
            case drillDownIntegrated(HapticEngineFeature.State)
            case popoverIntegrated(HapticEngineFeature.State)
            case sheetIntegrated(HapticEngineFeature.State)
        }
        
        enum Action {
            case drillDownBasic(HapticsFeature.Action)
            case popoverBasic(HapticsFeature.Action)
            case sheetBasic(HapticsFeature.Action)

            case drillDownIntegrated(HapticEngineFeature.Action)
            case popoverIntegrated(HapticEngineFeature.Action)
            case sheetIntegrated(HapticEngineFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(
                state: /State.sheetBasic,
                action: /Action.sheetBasic
            ) { HapticsFeature(client: .live) }
            Scope(
                state: /State.drillDownBasic,
                action: /Action.drillDownBasic
            ) { HapticsFeature(client: .live) }
            Scope(
                state: /State.popoverBasic,
                action: /Action.popoverBasic
            ) { HapticsFeature(client: .live) }
            Scope(
                state: /State.popoverIntegrated,
                action: /Action.popoverIntegrated
            ) {
                HapticEngineFeature(
                    client: .liveHaptic,
                    copyClient: .live,
                    hapticEventGen: vanillaHapticEventGen.run
                )
            }
            Scope(
                state: /State.sheetIntegrated,
                action: /Action.sheetIntegrated
            ) { 
                HapticEngineFeature(
                    client: .liveHaptic,
                    copyClient: .live,
                    hapticEventGen: vanillaHapticEventGen.run
                )
            }
            Scope(
                state: /State.drillDownIntegrated,
                action: /Action.drillDownIntegrated
            ) {
                HapticEngineFeature(
                    client: .liveHaptic,
                    copyClient: .live,
                    hapticEventGen: vanillaHapticEventGen.run
                )
            }
        }
    }
    
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var sharedIntegratedState = hapticPatternGen.run()
    }
    
    enum Action {
        case destination(PresentationAction<Destination.Action>)

        case onShowBasicDrillDownButtonTapped
        case onShowBasicPopoverButtonTapped
        case onShowBasicSheetButtonTapped
        
        case onShowIntegratedDrillDownButtonTapped
        case onShowIntegratedPopoverButtonTapped
        case onShowIntegratedSheetButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination(.presented(.drillDownIntegrated(.delegate(.onDisappear(let newState))))):
                state.sharedIntegratedState = newState
                return .none
            case .destination:
                return .none

            case .onShowBasicDrillDownButtonTapped:
                state.destination = .drillDownBasic(HapticsFeature.State())
            case .onShowBasicPopoverButtonTapped:
                state.destination = .popoverBasic(HapticsFeature.State())
            case .onShowBasicSheetButtonTapped:
                state.destination = .sheetBasic(HapticsFeature.State())



            case .onShowIntegratedDrillDownButtonTapped:
                state.destination = .drillDownIntegrated(.init(hapticPattern: state.sharedIntegratedState))
            case .onShowIntegratedPopoverButtonTapped:
                state.destination = .popoverIntegrated(.init(hapticPattern: state.sharedIntegratedState))
            case .onShowIntegratedSheetButtonTapped:
                state.destination = .sheetIntegrated(.init(hapticPattern: state.sharedIntegratedState))

            }
            return .none
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

struct MultipleDestinationsView: View {
    let store: StoreOf<MultipleDestination>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section("Basic") {
                    Button("Show drill-down") {
                        viewStore.send(.onShowBasicDrillDownButtonTapped)
                    }
                    Button("Show popover") {
                        viewStore.send(.onShowBasicPopoverButtonTapped)
                    }
                    Button("Show sheet") {
                        viewStore.send(.onShowBasicSheetButtonTapped)
                    }
                }

                Section("Integrated") {
                    Button("Show drill-down") {
                        viewStore.send(.onShowIntegratedDrillDownButtonTapped)
                    }
                    Button("Show popover") {
                        viewStore.send(.onShowIntegratedPopoverButtonTapped)
                    }
                    Button("Show sheet") {
                        viewStore.send(.onShowIntegratedSheetButtonTapped)
                    }
                }

            }
            .sheet(
                store: store.scope(
                    state: \.$destination,
                    action: MultipleDestination.Action.destination
                ),
                state: /MultipleDestination.Destination.State.sheetBasic,
                action: MultipleDestination.Destination.Action.sheetBasic
            ) { store in
                HapticMenuApp(store: store)
            }
            .popover(
                store: store.scope(
                    state: \.$destination,
                    action: MultipleDestination.Action.destination
                ),
                state: /MultipleDestination.Destination.State.popoverBasic,
                action: MultipleDestination.Destination.Action.popoverBasic
            ) { store in
                HapticMenuApp(store: store)
            }
            .navigationDestination(
                store: store.scope(
                    state: \.$destination,
                    action: MultipleDestination.Action.destination
                ),
                state: /MultipleDestination.Destination.State.drillDownBasic,
                action: MultipleDestination.Destination.Action.drillDownBasic
            ) { store in
                HapticMenuApp(store: store)
            }
            
            .sheet(
                store: store.scope(
                    state: \.$destination,
                    action: MultipleDestination.Action.destination
                ),
                state: /MultipleDestination.Destination.State.sheetIntegrated,
                action: MultipleDestination.Destination.Action.sheetIntegrated
            ) { store in
                HapticButtonView(store: store)
            }
            .popover(
                store: store.scope(
                    state: \.$destination,
                    action: MultipleDestination.Action.destination
                ),
                state: /MultipleDestination.Destination.State.popoverIntegrated,
                action: MultipleDestination.Destination.Action.popoverIntegrated
            ) { store in
                HapticButtonView(store: store)
            }
            .navigationDestination(
                store: store.scope(
                    state: \.$destination,
                    action: MultipleDestination.Action.destination
                ),
                state: /MultipleDestination.Destination.State.drillDownIntegrated,
                action: MultipleDestination.Destination.Action.drillDownIntegrated
            ) { store in
                HapticButtonView(store: store)
            }
        }
    }
}
