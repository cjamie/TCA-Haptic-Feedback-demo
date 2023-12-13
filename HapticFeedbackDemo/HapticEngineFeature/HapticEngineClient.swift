//
//  HapticEngineClient.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import Foundation
import CoreHaptics




struct HapticEngineClient {
    
    let supportsHaptics: () -> Bool
    let makeHapticEngine: () async throws -> HapticEngine
//    let makePlayer: (HapticPattern) ->
    
    static let live: HapticEngineClient = {
        let temp = HapticEngineClient(
            supportsHaptics: {
                CHHapticEngine.capabilitiesForHardware().supportsHaptics
            },
            makeHapticEngine: {
                let realEngine = try CHHapticEngine()

                return HapticEngine(
                    objId: ObjectIdentifier(realEngine),
                    start: realEngine.start,
                    makePlayer: { pattern in
                        let temp = try realEngine.makePlayer(with: pattern.toCHHapticPattern)
                        
                        return .init(start: { time in
                            try temp.start(atTime: time)
                        })
                    }
                )
            }
        )
        
        return temp
    }()
    
    
    static let mock: HapticEngineClient = {

        let temp = HapticEngineClient(
            supportsHaptics: {
                true
            },
            makeHapticEngine: {
                HapticEngine(
                    objId: ObjectIdentifier(NSObject()),
                    start: {
                        // no op
                    },
                    makePlayer: { _ in .init(start: { _ in }) }
                )
            }
        )
        
        return temp
    }()

}

extension CHHapticEvent {
    var kvoDescription: String? {
        guard let eventType = value(forKey: "eventType") as? CHHapticEvent.EventType,
              let parameters = value(forKey: "parameters") as? [CHHapticEventParameter],
              let relativeTime = value(forKey: "relativeTime") as? TimeInterval,
              let duration = value(forKey: "duration") as? TimeInterval else {
            return nil
        }
        
        return "Event Type: \(eventType), Parameters: \(parameters), Relative Time: \(relativeTime), Duration: \(duration)"
    }
}

struct HapticEngine: Equatable {
    
    let objId: ObjectIdentifier
    let start: () async throws -> Void
    
    let makePlayer: (HapticPattern) throws -> HapticPatternPlayer
    
    static func == (lhs: HapticEngine, rhs: HapticEngine) -> Bool {
        lhs.objId == rhs.objId
    }
}

struct HapticEvent: Equatable {
    struct EventType: Equatable {
        let rawValue: String
        
        init(raw: CHHapticEvent.EventType) {
            self.rawValue = raw.rawValue
        }
        
        static let audioContinuous = EventType(raw: .audioContinuous)
        static let audioCustom = EventType(raw: .audioCustom)
        static let hapticContinuous = EventType(raw: .hapticContinuous)
        static let hapticTransient = EventType(raw: .hapticTransient)
    }

    struct EventParameter: Equatable {
        struct ParameterID: Equatable {
            let rawValue: String
            
            static let hapticIntensity = ParameterID(raw: .hapticIntensity)
            static let hapticSharpness = ParameterID(raw: .hapticSharpness)
            static let attackTime = ParameterID(raw: .attackTime)
            static let audioBrightness = ParameterID(raw: .audioBrightness)
            static let audioPan = ParameterID(raw: .audioPan)
            static let audioPitch = ParameterID(raw: .audioPitch)
            static let audioVolume = ParameterID(raw: .audioVolume)
            static let decayTime = ParameterID(raw: .decayTime)
            static let releaseTime = ParameterID(raw: .releaseTime)
            static let sustained = ParameterID(raw: .sustained)
            
            init(raw: CHHapticEvent.ParameterID) {
                self.rawValue = raw.rawValue
            }
        }
        
        let parameterID: ParameterID
        let value: Float
    }

    let eventType: EventType
    let parameters: [EventParameter]
    let relativeTime: TimeInterval
    let duration: TimeInterval
    
    
    
    var toCHHapticEvent: CHHapticEvent {
        .init(
            eventType: CHHapticEvent.EventType(rawValue: eventType.rawValue),
            parameters: parameters.map { domain in
                CHHapticEventParameter(
                    parameterID: CHHapticEvent.ParameterID(rawValue: domain.parameterID.rawValue),
                    value: domain.value
                )
            },
            relativeTime: 0,
            duration: 1
        )
    }
}


// this needs to be wrapped in a try-able init.
struct HapticPattern: Equatable {
    let events: [HapticEvent]
    let parameters: [HapticDynamicParameter]
    
    private let _cHHapticPattern: CHHapticPattern
    
    init(events: [HapticEvent], parameters: [HapticDynamicParameter]) throws {
        self.events = events
        self.parameters = parameters
        self._cHHapticPattern = try CHHapticPattern(
            events: events.map(\.toCHHapticEvent),
            parameters: []
        )
    }
    
    var toCHHapticPattern: CHHapticPattern {
        _cHHapticPattern
    }
}

struct HapticDynamicParameter: Equatable { // CHHapticDynamicParameter
//    var toCHHapticDynamicParameter: CHHapticDynamicParameter {
//        .init(
//            parameterID: <#T##CHHapticDynamicParameter.ID#>,
//            value: <#T##Float#>,
//            relativeTime: <#T##TimeInterval#>
//        )
//    }
}

struct HapticPatternPlayer {
    let start: (TimeInterval) throws -> Void
}

//CHHapticPatternPlayer
//import CoreHaptics
let HapticTimeImmediate = CoreHaptics.CHHapticTimeImmediate
