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
    
    static let mock =  HapticEngineClient(
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

struct HapticEngine: Equatable {
    let objId: ObjectIdentifier
    let start: () async throws -> Void
    let makePlayer: (HapticPattern) throws -> HapticPatternPlayer
    
    static func == (lhs: HapticEngine, rhs: HapticEngine) -> Bool {
        lhs.objId == rhs.objId
    }
}

struct HapticEvent: Equatable, Encodable {
    struct EventType: Equatable, Encodable {
        let rawValue: String
    }

    struct EventParameter: Equatable, Encodable {
        struct ID: Equatable, Encodable {
            let rawValue: String
        }
        
        let parameterID: ID
        let value: Float
    }

    let eventType: EventType
    let parameters: [EventParameter]
    let relativeTime: TimeInterval
    let duration: TimeInterval
}

struct HapticDynamicParameter: Equatable, Encodable {
    struct ID: Equatable, Encodable {
        let rawValue: String
    }
    
    let parameterId: ID
    let value: Float
    let relativeTime: TimeInterval
}

struct HapticPatternPlayer {
    let start: (TimeInterval) throws -> Void
}
