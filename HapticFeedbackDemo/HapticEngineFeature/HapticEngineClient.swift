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
                makePlayer: { _ in .init { _ in } }
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

// CHHapticEngine
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

// CHHapticEvent
struct HapticEvent: Hashable, Encodable, Identifiable {

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
    
    static let mock = hapticEventGen.run()

    static var dynamicMock: HapticEvent {
        hapticEventGen.run()
    }
    
//    enum CodingKeys: CodingKey {
//        case eventType
//        case parameters
//        case relativeTime
//        case duration
//    }
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
}
