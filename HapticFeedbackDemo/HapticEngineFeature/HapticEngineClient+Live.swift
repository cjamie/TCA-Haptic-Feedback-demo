//
//  HapticEngineClient+Live.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import CoreHaptics

// TODO: - this is unusual, since the init is throwable.
struct HapticPattern: Equatable, Encodable {
    var events: [HapticEvent]
    var parameters: [HapticDynamicParameter]
    
    private let _cHHapticPattern: CHHapticPattern
    
    init(events: [HapticEvent], parameters: [HapticDynamicParameter]) throws {
        self.events = events
        self.parameters = parameters
        self._cHHapticPattern = try CHHapticPattern(
            events: events.map(\.toCHHapticEvent),
            parameters: parameters.map(\.toCHHapticDynamicParameter)
        )
    }

    enum CodingKeys: String, CodingKey {
        case events
        case parameters
    }

    var toCHHapticPattern: CHHapticPattern {
        _cHHapticPattern
    }
}

extension HapticEngineClient {
    static let live = HapticEngineClient(
        supportsHaptics: {
            CHHapticEngine.capabilitiesForHardware().supportsHaptics
        },
        makeHapticEngine: {
            let realEngine = try CHHapticEngine()
            
            return HapticEngine(
                objId: ObjectIdentifier(realEngine),
                start: realEngine.start,
                makePlayer: { pattern in
                    let player = try realEngine.makePlayer(with: pattern.toCHHapticPattern)
                    
                    return .init(start: { time in
                        try player.start(atTime: time)
                    })
                }
            )
        }
    )
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

extension HapticEvent {
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

extension HapticEvent.EventType {
    init(raw: CHHapticEvent.EventType) {
        self.rawValue = raw.rawValue
    }

    static let audioContinuous = Self(raw: .audioContinuous)
    static let audioCustom = Self(raw: .audioCustom)
    static let hapticContinuous = Self(raw: .hapticContinuous)
    static let hapticTransient = Self(raw: .hapticTransient)
}

extension HapticEvent.EventParameter.ID {
    init(raw: CHHapticEvent.ParameterID) {
        self.rawValue = raw.rawValue
    }

    static let hapticIntensity = Self(raw: .hapticIntensity)
    static let hapticSharpness = Self(raw: .hapticSharpness)
    static let attackTime = Self(raw: .attackTime)
    static let audioBrightness = Self(raw: .audioBrightness)
    static let audioPan = Self(raw: .audioPan)
    static let audioPitch = Self(raw: .audioPitch)
    static let audioVolume = Self(raw: .audioVolume)
    static let decayTime = Self(raw: .decayTime)
    static let releaseTime = Self(raw: .releaseTime)
    static let sustained = Self(raw: .sustained)
}

let HapticTimeImmediate = CoreHaptics.CHHapticTimeImmediate

extension HapticDynamicParameter.ID {
    var toCHHapticDynamicParameterID: CHHapticDynamicParameter.ID {
        .init(rawValue: rawValue)
    }
    
    init(raw: CHHapticDynamicParameter.ID) {
        self.rawValue = raw.rawValue
    }
    
    static let audioAttackTimeControl =  Self.init(raw: .audioAttackTimeControl)
    static let audioBrightnessControl =  Self.init(raw: .audioBrightnessControl)
    static let audioDecayTimeControl =  Self.init(raw: .audioDecayTimeControl)
    static let audioPanControl =  Self.init(raw: .audioPanControl)
    static let audioPitchControl =  Self.init(raw: .audioPitchControl)
    static let audioReleaseTimeControl =  Self.init(raw: .audioReleaseTimeControl)
    static let audioVolumeControl =  Self.init(raw: .audioVolumeControl)
    static let hapticAttackTimeControl =  Self.init(raw: .hapticAttackTimeControl)
    static let hapticDecayTimeControl =  Self.init(raw: .hapticDecayTimeControl)
    static let hapticIntensityControl =  Self.init(raw: .hapticIntensityControl)
    static let hapticReleaseTimeControl =  Self.init(raw: .hapticReleaseTimeControl)
    static let hapticSharpnessControl =  Self.init(raw: .hapticSharpnessControl)
}

extension HapticDynamicParameter {
    var toCHHapticDynamicParameter: CHHapticDynamicParameter {
        .init(
            parameterID: parameterId.toCHHapticDynamicParameterID,
            value: value,
            relativeTime: relativeTime
        )
    }
}
