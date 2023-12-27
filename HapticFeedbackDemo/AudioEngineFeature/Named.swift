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
    static let advancedCases = makeLoaders(advancedPatternNames)
    static let basicCases = makeLoaders(basicPatternNames)
    
    // MARK: - Helpers

    private static let advancedPatternNames = [
        "texturePattern"
    ]
    
    private static let basicPatternNames = [
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

private let makeLoaders = map { name in
    Named(name: name, wrapped: Loader { try tryMakePattern(name) })
}
