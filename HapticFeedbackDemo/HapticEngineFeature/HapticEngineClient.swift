//
//  HapticEngineClient.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import Foundation

struct HapticEngineClient {
    let supportsHaptics: () -> Bool
    let makeHapticEngine: () throws -> HapticEngine
    
    static let mock = HapticEngineClient(
        supportsHaptics: { true },
        makeHapticEngine: {
            HapticEngine(
                objId: ObjectIdentifier(NSObject()),
                start: {},
                makePlayer: { _ in .init(start: { _ in }) }
            )
        }
    )
}

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

struct HapticEvent: Hashable, Encodable, Identifiable {
    struct EventType: Hashable, Encodable {
        let rawValue: String
    }

    struct EventParameter: Hashable, Encodable {
        struct ID: Hashable, Encodable {
            let rawValue: String
        }
        
        let parameterID: ID
        let value: Float
    }
    let id = UUID()

    var eventType: EventType
    var parameters: [EventParameter]
    var relativeTime: TimeInterval
    var duration: TimeInterval
    
    static let mock = hapticEventGen.run()

    static var dynamicMock: HapticEvent {
        hapticEventGen.run()
    }
}

struct HapticDynamicParameter: Hashable, Encodable {
    struct ID: Hashable, Encodable {
        let rawValue: String
    }
    
    let parameterId: ID
    let value: Float
    let relativeTime: TimeInterval
}

struct HapticPatternPlayer {
    let start: (TimeInterval) throws -> Void
}
