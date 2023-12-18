//
//  HapticEngineClient+Live.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import CoreHaptics



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
                    let player = try realEngine.makePlayer(with: pattern.toCHHapticPattern())
                    
                    return .init(start: { time in
                        try player.start(atTime: time)
                    })
                }
            )
        }
    )
}

extension HapticPattern {
    func toCHHapticPattern() throws -> CHHapticPattern {
        try CHHapticPattern(
            events: events.map(\.toCHHapticEvent),
            parameters: parameters.map(\.toCHHapticDynamicParameter)
        )
    }
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
            parameters: parameters.map(\.toCHHapticEventParameter),
            relativeTime: 0,
            duration: 1
        )
    }
}

extension HapticEvent.EventParameter {
    var toCHHapticEventParameter: CHHapticEventParameter {
        CHHapticEventParameter(
            parameterID: CHHapticEvent.ParameterID(rawValue: parameterID.rawValue),
            value: value
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
    
    static var allCases: [Self] {
        audioCases + hapticCases
    }
    
    static var hapticCases: [Self] {
        [
            hapticContinuous,
            hapticTransient,
        ]
    }
    
    static var audioCases: [Self] {
        [
            hapticContinuous,
            hapticTransient,
        ]
    }
}

extension HapticEvent.EventParameter.ParameterID {
    init(raw: CHHapticEvent.ParameterID) {
        self.rawValue = raw.rawValue
    }

    // MARK: - Haptic Event Parameter IDs

    static let hapticIntensity = Self(raw: .hapticIntensity)
    static let hapticSharpness = Self(raw: .hapticSharpness)
    static let attackTime = Self(raw: .attackTime)
    static let decayTime = Self(raw: .decayTime)
    static let releaseTime = Self(raw: .releaseTime)
    static let sustained = Self(raw: .sustained)
    
    // MARK: - Audio Event Parameter IDs

    static let audioBrightness = Self(raw: .audioBrightness)
    static let audioPan = Self(raw: .audioPan)
    static let audioPitch = Self(raw: .audioPitch)
    static let audioVolume = Self(raw: .audioVolume)

    static let allCasesWithRanges: [(Self, ClosedRange<Float>)] = hapticCasesWithRanges + audioCasesWithRanges
    
    static let hapticCasesWithRanges: [(Self, ClosedRange<Float>)] = [
        (hapticIntensity, 0...1),
        (hapticSharpness, 0...1),
        (attackTime, -1...1),
        (decayTime, -1...1),
        (releaseTime, 0...1),
        //        (sustained, 0...1), Weird... apple docs said this should be a bool
    ]
    
    static let audioCasesWithRanges: [(Self, ClosedRange<Float>)] = [
        (audioBrightness, 0...1),
        (audioPan, -1...1),
        (audioPitch, -1...1),
        (audioVolume, 0...1),
    ]

    
    
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


extension CHHapticPatternKey {
    /*     
     {
     "Event": "Time": 0.0,
         "EventType": "HapticTransient",
         "EventParameters":
         [
             { "ParameterID": "HapticIntensity", "ParameterValue": 1.0 },
             { "ParameterID": "HapticSharpness", "ParameterValue": 0.0 }
         ]
     }
     
     */
    static let event = Self(rawValue: CHHapticPattern.Key.event.rawValue)
    
    /*
     "EventDuration": 0.60,
     */
    static let eventDuration = Self(rawValue: CHHapticPattern.Key.eventDuration.rawValue)
    
    /*
     "EventParameters":
     [
         { "ParameterID": "HapticIntensity", "ParameterValue": 1.0 },
         { "ParameterID": "HapticSharpness", "ParameterValue": 0.0 }
     ]
     */
    static let eventParameters = Self(rawValue: CHHapticPattern.Key.eventParameters.rawValue)
    
    
    /*
     "EventType": "HapticTransient",
     */
    static let eventType = Self(rawValue: CHHapticPattern.Key.eventType.rawValue)
    
    /*
     This is iOS 15+
     should be a boolean
     */
    static let eventWaveformLoopEnabled = Self(rawValue: CHHapticPattern.Key.eventWaveformLoopEnabled.rawValue)
    
    // This is iOS 15+, and not being used anywhere..
    static let eventWaveformUseVolumeEnvelope = Self(rawValue: CHHapticPattern.Key.eventWaveformUseVolumeEnvelope.rawValue)

    static let parameter = Self(rawValue: CHHapticPattern.Key.parameter.rawValue)
    
    /*
     "ParameterCurve":
     {
         "ParameterID": "HapticIntensityControl",
         "Time": 0.0,
         "ParameterCurveControlPoints":
         [
             { "Time": 0.0, "ParameterValue": 0.0 },
             { "Time": 0.15, "ParameterValue": 1.0 },
             { "Time": 0.25, "ParameterValue": 1.0 },
             { "Time": 0.3, "ParameterValue": 0.3 },
             { "Time": 0.6, "ParameterValue": 0.0 }
         ]
     }
     */
    static let parameterCurve = Self(rawValue: CHHapticPattern.Key.parameterCurve.rawValue)
    
    /*
     "ParameterCurveControlPoints":
     [
         { "Time": 0.0, "ParameterValue": 0.0 },
         { "Time": 0.15, "ParameterValue": 1.0 },
         { "Time": 0.25, "ParameterValue": 1.0 },
         { "Time": 0.3, "ParameterValue": 0.3 },
         { "Time": 0.6, "ParameterValue": 0.0 }
     ]
     */
    static let parameterCurveControlPoints = Self(rawValue: CHHapticPattern.Key.parameterCurveControlPoints.rawValue)
    
    /*
     "ParameterID": "HapticIntensityControl",
     */
    static let parameterID = Self(rawValue: CHHapticPattern.Key.parameterID.rawValue)
    
    /*
     "ParameterValue": 0.0
     */
    static let parameterValue = Self(rawValue: CHHapticPattern.Key.parameterValue.rawValue)
    
    /*
     "Pattern":
     [
         {
             "Event":
             {
                 "Time": 0.0,
                 "EventType": "HapticTransient",
                 "EventParameters":
                 [
                     { "ParameterID": "HapticIntensity", "ParameterValue": 1.0 },
                     { "ParameterID": "HapticSharpness", "ParameterValue": 0.0 }
                 ]
             }
         },
         {
             "Event":
             {
                 "Time":0.0,
                 "EventType":"AudioCustom",
                 "EventWaveformPath":"CollisionLarge.wav",
                 "EventParameters":
                 [
                     {"ParameterID":"AudioVolume","ParameterValue":1.0}
                 ]
             }
         }
     ]
     */
    static let pattern = Self(rawValue: CHHapticPattern.Key.pattern.rawValue)
    
    /*
     "Time":0.0,
     */
    static let time = Self(rawValue: CHHapticPattern.Key.time.rawValue)

    /*
     "Version": 1.0,
     */
    static let version = Self(rawValue: CHHapticPattern.Key.version.rawValue)
    
    static var allCases: [Self] {
        [
            event,
            eventDuration,
            eventParameters,
            eventType,
            eventWaveformLoopEnabled,
            eventWaveformUseVolumeEnvelope,
            parameter,
            parameterCurve,
            parameterCurveControlPoints,
            parameterID,
            parameterValue,
            pattern,
            time,
            version,
        ]
    }
}

/*
 
 let pattern = try CHHapticPattern(
 events: [
 CHHapticEvent(
 eventType: .hapticContinuous,
 parameters: [
 CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
 CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
 ],
 relativeTime: 0,
 duration: 1
 )
 ],
 parameters: []
 )
 
 
 */

func zz() {
    let sustainTime = CHHapticEventParameter(parameterID: .sustained, value: 1) // If you want to sustain the haptic for its entire duration.
//    CHHapticPattern.init(dictionary: <#T##[CHHapticPattern.Key : Any]#>)
//    CHHapticPattern.init(
//        dictionary: [
//            .version: 1.0,
//            .eventWaveformUseVolumeEnvelope:
//        ]
//    )
    
//    CHHapticPattern.init(dictionary: <#T##[CHHapticPattern.Key : Any]#>)
    //    CHHapticPattern.init(
    //        events: <#T##[CHHapticEvent]#>,
    //        parameters: <#T##[CHHapticDynamicParameter]#>
    //    )
}
