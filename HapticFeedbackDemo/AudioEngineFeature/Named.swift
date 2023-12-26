//
//  Named.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/21/23.
//

import CoreHaptics

struct Named<T> {
    let name: String
    let wrapped: T
}

extension Named: Equatable where T: Equatable {}

extension Named: Identifiable {
    var id: String {
        name
    }
}

// Named<Loader<CHHapticPattern>>
extension Named where T == Loader<CHHapticPattern> {
    static let advancedCases = makeNamedLoader(advancedPatternNames)
    static let basicCases = makeNamedLoader(basicPatternNames)
    
    // MARK: - Helpers

    private static let advancedPatternNames: [ String ] = [
        "texturePattern"
    ]
    
    private static let basicPatternNames: [ String ] = [
        "collisionPatternSmall",
        "collisionPatternLarge",
        "collisionPatternShield",
        "spawnPattern",
        "growPattern",
        "shieldContinuousPattern",
        "implodePattern",
        "shieldTransientPattern",
    ]
}

private let makeNamedLoader = map { patternName in
    Named(
        name: patternName,
        wrapped: Loader<CHHapticPattern> {
            try tryMakePattern(patternName)
        }
    )
}
