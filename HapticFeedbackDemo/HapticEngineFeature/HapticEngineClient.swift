//
//  HapticEngineClient.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import Foundation

typealias HapticEngineFactory<T> = (
    _ resetHandler: @escaping () -> Void,
    _ stoppedHandler: @escaping (StoppedReason) -> Void
) throws -> HapticEngine<T>

struct HapticEngineClient<T> {
    let supportsHaptics: () -> Bool
    
    private let _makeHapticEngine: HapticEngineFactory<T>
    
    init(
        supportsHaptics: @escaping () -> Bool,
        _makeHapticEngine: @escaping HapticEngineFactory<T>
    ) {
        self.supportsHaptics = supportsHaptics
        self._makeHapticEngine = _makeHapticEngine
    }
    
    func makeHapticEngine(
        resetHandler: @escaping () -> Void,
        stoppedHandler: @escaping (StoppedReason) -> Void
    ) throws -> HapticEngine<T> {
        try _makeHapticEngine(resetHandler, stoppedHandler)
    }
}

extension HapticEngineClient where T == HapticPattern {
    static let mock = HapticEngineClient(
        supportsHaptics: { true },
        _makeHapticEngine: { resetHandler, stoppedHandler in
            var didCallStart = false
            return HapticEngine(
                objId: ObjectIdentifier(NSObject()),
                start: {
                    if didCallStart {
                        resetHandler()
                    } else {
                        didCallStart = true
                    }
                },
                stop: { stoppedHandler(.engineDestroyed) },
                makePlayer: { _ in .init(
                    start: { _ in },
                    _sendParameters: { _, _ in }
                )}
            )
        }
    )
}
//extension HapticEngineClient where T == CHHapticPattern {
//    static let mock = HapticEngineClient(
//        supportsHaptics: { true },
//        _makeHapticEngine: { resetHandler, stoppedHandler in
//            var didCallStart = false
//            return HapticEngine(
//                objId: ObjectIdentifier(NSObject()),
//                start: {
//                    if didCallStart {
//                        resetHandler()
//                    } else {
//                        didCallStart = true
//                    }
//                },
//                stop: { stoppedHandler(.engineDestroyed) },
//                makePlayer: { _ in .init(
//                    start: { _ in },
//                    _sendParameters: { _, _ in }
//                )}
//            )
//        }
//    )
//}

// CHHapticPattern
struct HapticPattern: Equatable, Encodable {
    var events: [HapticEvent]
    var parameters: [HapticDynamicParameter]
    
    init(events: [HapticEvent], parameters: [HapticDynamicParameter]) {
        self.events = events
        self.parameters = parameters
    }
    
    var dynamicMock: Self {
        hapticPatternGen.run()
    }
}

// CHHapticPattern.Key
struct CHHapticPatternKey: Hashable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// CHHapticEngine (misleading name, since is also able to support audio)
struct HapticEngine<T>: Hashable {
    let objId: ObjectIdentifier
    let start: () async throws -> Void
    let stop: () async throws -> Void
    let makePlayer: (T) throws -> HapticPatternPlayer
        
    static func == (lhs: HapticEngine, rhs: HapticEngine) -> Bool {
        lhs.objId == rhs.objId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(objId)
    }
}

/*
 this type of init is not capable of producing audio events.
 */
// CHHapticEvent
struct HapticEvent: Hashable, Encodable {

    // CHHapticEvent.EventType
    struct EventType: Hashable, Encodable {
        let rawValue: String
    }

    // CHHapticEventParameter
    struct EventParameter: Hashable, Encodable {

        // CHHapticEvent.ParameterID
        struct ParameterID: Hashable, Encodable {
            let rawValue: String
        }
        
        let id: UUID
        var parameterID: ParameterID
        var value: Float
        var range: ClosedRange<Float>
        
        mutating func change(to: Self) {
            parameterID = to.parameterID
            value = to.value
            range = to.range
        }
    }
    
    let id: UUID
    var eventType: EventType
    var parameters: [EventParameter]
    var relativeTime: TimeInterval
    var duration: TimeInterval

    mutating func change(to: Self) {
        eventType = to.eventType
        parameters = to.parameters
        relativeTime = to.relativeTime
        duration = to.duration
    }
    
    static let mock = vanillaHapticEventGen.run()

    static var dynamicMock: HapticEvent {
        vanillaHapticEventGen.run()
    }
    
    static let `default` = HapticEvent(
        id: uuidGen.run(),
        eventType: .audioCustom,
        parameters: [
            //                        .init(id: UUID(), parameterID: .hapticIntensity, value: 1.0, range: 0...1),
            //                        .init(id: UUID(), parameterID: .hapticSharpness, value: 1.0, range: 0...1),
            //                        .init(id: UUID(), parameterID: .attackTime, value: 1.0, range: 0...1),
            //                        .init(id: UUID(), parameterID: .audioBrightness, value: 1.0, range: 0...1),
            .init(id: uuidGen.run(), parameterID: .audioPan, value: 1.0, range: -1...1),
            //                        .init(id: UUID(), parameterID: .audioPitch, value: 1.0, range: -1...1),
            //                        .init(id: UUID(), parameterID: .audioVolume, value: 1.0, range: 0...1),
            //                        .init(id: UUID(), parameterID: .decayTime, value: 1.0, range: 0...1),
            //                        .init(id: UUID(), parameterID: .releaseTime, value: 1.0, range: 0...1),
            //                        .init(id: UUID(), parameterID: .sustained, value: 1.0, range: 0...1),
        ],
        relativeTime: 0,
        duration: 1
    )
}

// CHHapticDynamicParameter
struct HapticDynamicParameter: Hashable, Encodable {
    
    //CHHapticDynamicParameter.ID
    struct ID: Hashable, Encodable {
        let rawValue: String
    }
    
    let parameterId: ID
    let value: Float
    let relativeTime: TimeInterval
}

// CHHapticPatternPlayer
// you can hold this in memory, and play it whenever you want.
struct HapticPatternPlayer {
    typealias SendParameters = (
        _ parameters: [HapticDynamicParameter],
        _ time: TimeInterval
    ) throws -> Void
    
    let start: (TimeInterval) throws -> Void
    let _sendParameters: SendParameters

    init(
        start: @escaping (TimeInterval) throws -> Void,
        _sendParameters: @escaping SendParameters
    ) {
        self.start = start
        self._sendParameters = _sendParameters
    }
    
    func sendParameters(
        parameters: [HapticDynamicParameter],
        atTime time: TimeInterval
    ) throws {
        try _sendParameters(parameters, time)
    }
}
