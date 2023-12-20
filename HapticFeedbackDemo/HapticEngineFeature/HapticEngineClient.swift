//
//  HapticEngineClient.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import Foundation

struct HapticEngineClient {

    typealias HapticEngineFactory = (
        _ resetHandler: @escaping () -> Void,
        _ stoppedHandler: @escaping (String) -> Void
    ) throws -> HapticEngine

    let supportsHaptics: () -> Bool

    
    private let _makeHapticEngine: HapticEngineFactory
    
    init(
        supportsHaptics: @escaping () -> Bool,
        _makeHapticEngine: @escaping HapticEngineFactory
    ) {
        self.supportsHaptics = supportsHaptics
        self._makeHapticEngine = _makeHapticEngine
    }
    
    func makeHapticEngine(
        resetHandler: @escaping () -> Void,
        stoppedHandler: @escaping (String) -> Void
    ) throws -> HapticEngine {
        try _makeHapticEngine(resetHandler, stoppedHandler)
    }
    
    static let mock = HapticEngineClient(
        supportsHaptics: { true },
        _makeHapticEngine: { _, _ in
            HapticEngine(
                objId: ObjectIdentifier(NSObject()),
                start: {},
                makePlayer: { _ in .init(
                    start: { _ in },
                    sendParameters: { _, _ in }
                )}
            )
        }
    )
}

// CHHapticPattern
struct HapticPattern: Equatable, Encodable {
    var events: [HapticEvent]
    var parameters: [HapticDynamicParameter]
    
    init(events: [HapticEvent], parameters: [HapticDynamicParameter]) throws {
        self.events = events
        self.parameters = parameters
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
struct HapticEngine: Hashable {
    let objId: ObjectIdentifier
    let start: () async throws -> Void
    let makePlayer: (HapticPattern) throws -> HapticPatternPlayer
        
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
        let parameterID: ParameterID
        var value: Float
        let range: ClosedRange<Float>
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
struct HapticPatternPlayer {
    let start: (TimeInterval) throws -> Void
    
    let sendParameters: (
        _ parameters: [HapticDynamicParameter],
        _ time: TimeInterval
    ) throws -> Void
}
