//
//  HapticsClient.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

struct HapticsClient {
    let supportsHaptics: () -> Bool
    let generators: [BasicHaptic: MyFeedbackGenerator]
    
    static let mock = HapticsClient(
        supportsHaptics: { false },
        generators: BasicHaptic.allCases.reduce(into: [:]) { acc, next in
            acc[next] = .mock
        }
    )
}
