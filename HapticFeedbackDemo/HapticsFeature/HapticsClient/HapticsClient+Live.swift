//
//  HapticsClient+Live.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import CoreHaptics
import UIKit

typealias FeedbackStyle = UIImpactFeedbackGenerator.FeedbackStyle
typealias FeedbackType = UINotificationFeedbackGenerator.FeedbackType

extension HapticsClient {
    static let live = HapticsClient(
        supportsHaptics: {
            CHHapticEngine.capabilitiesForHardware().supportsHaptics
        },
        generators: {
            let notificationGen = UINotificationFeedbackGenerator()
            let selectionGen = UISelectionFeedbackGenerator()
            
            return HapticType.allCases.reduce(into: [:]) { acc, next in
                switch next.category {
                case .feedback(let style, _):
                    let gen = UIImpactFeedbackGenerator(style: style)
                    
                    acc[next] = .init(prepare: gen.prepare) {
                        $0.map(gen.impactOccurred(intensity:)) ?? gen.impactOccurred()
                    }
                    
                case .notificationFeedback(let type):
                    acc[next] = .init(
                        prepare: notificationGen.prepare,
                        run: { _ in notificationGen.notificationOccurred(type) }
                    )
                    
                case .selectionFeedback:
                    acc[next] = .init(
                        prepare: selectionGen.prepare,
                        run: { _ in selectionGen.selectionChanged() }
                    )
                }
            }
        }()
    )
}
