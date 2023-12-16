//
//  HapticsClient.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//
import CoreHaptics
// Public interface for haptics, hides the dependency on CoreHaptics
struct HapticsClient {
    let supportsHaptics: () -> Bool
    let generators: [HapticType: MyFeedbackGenerator]
    
    static let mock = HapticsClient(
        supportsHaptics: { false },
        generators: HapticType.allCases.reduce(into: [:]) { acc, next in
            acc[next] = .mock
        }
    )
}
