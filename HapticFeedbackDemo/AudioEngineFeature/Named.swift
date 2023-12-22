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
//extension Named: Equatable where T == Loader<CHHapticPattern> {
//    static func == (lhs: Named<T>, rhs: Named<T>) -> Bool {
//        lhs.name == rhs.name
//    }
//}

extension Named: Identifiable {
    var id: String {
        name
    }
}

// Named<Loader<CHHapticPattern>>
extension Named where T == Loader<CHHapticPattern> {

    static let collisionPatternSmall = Self(
        name: "CollisionSmall",
        wrapped: .init { try tryMakePattern("CollisionSmall") }
    )
    static let collisionPatternLarge = Self(
        name: "CollisionLarge",
        wrapped: .init { try tryMakePattern("CollisionLarge") }
    )
    static let collisionPatternShield = Self(
        name: "CollisionShield",
        wrapped: .init { try tryMakePattern("CollisionShield") }
    )
    static let texturePattern = Self(
        name: "Texture",
        wrapped: .init { try tryMakePattern("Texture") }
    )
    static let spawnPattern = Self(
        name: "Spawn",
        wrapped: .init { try tryMakePattern("Spawn") }
    )
    static let growPattern = Self(
        name: "Grow",
        wrapped: .init { try tryMakePattern("Grow") }
    )
    static let shieldContinuousPattern = Self(
        name: "ShieldContinuous",
        wrapped: .init { try tryMakePattern("ShieldContinuous") }
    )
    static let implodePattern = Self(
        name: "Implode",
        wrapped: .init { try tryMakePattern("Implode") }
    )

    // not in use by the apple demo
    static let shieldTransientPattern = Self(
        name: "ShieldTransient",
        wrapped: .init { try tryMakePattern("ShieldTransient") }
    )
    
    static let allCases: [ Self ] = [
        collisionPatternSmall,
        collisionPatternLarge,
        collisionPatternShield,
        texturePattern,
        spawnPattern,
        growPattern,
        shieldContinuousPattern,
        implodePattern,
        shieldTransientPattern,
    ]

    //    static let collisionPatternSmall = Self { try tryMakePattern("CollisionSmall") }
    //    static let collisionPatternLarge = Self { try tryMakePattern("CollisionLarge") }
    //    static let collisionPatternShield = Self { try tryMakePattern("CollisionShield") }
    //    static let texturePattern = Self { try tryMakePattern("Texture") }
    //    static let spawnPattern = Self { try tryMakePattern("Spawn") }
    //    static let growPattern = Self { try tryMakePattern("Grow") }
    //    static let shieldContinuousPattern = Self { try tryMakePattern("ShieldContinuous") }
    //    static let implodePattern = Self { try tryMakePattern("Implode") }
    //    static let shieldTransientPattern = Self { try tryMakePattern("ShieldTransient") } // not in use by the apple demo

}
