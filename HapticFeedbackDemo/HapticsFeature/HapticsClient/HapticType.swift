//
//  HapticType.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import Foundation

struct HapticType: Hashable, CaseIterable {
    let rawValue: String
    let category: Category
        
    enum Category: Hashable {
        // TODO: - intensity should be embedded inside of feedback. right now, this value does nothing.
        case feedback(FeedbackStyle, intensity: CGFloat? = nil)
        case notificationFeedback(FeedbackType)
        case selectionFeedback
    }
        
    static let light = HapticType(
        rawValue: "Light",
        category: .feedback(.light)
    )
    
    static let medium = HapticType(
        rawValue: "Medium",
        category: .feedback(.medium)
    )
    
    static let heavy = HapticType(
        rawValue: "Heavy",
        category: .feedback(.heavy)
    )
    
    static let soft = HapticType(
        rawValue: "Soft",
        category: .feedback(.soft)
    )
    
    static let rigid = HapticType(
        rawValue: "Rigid",
        category: .feedback(.rigid)
    )
    
    static let success = HapticType(
        rawValue: "Success",
        category: .notificationFeedback(.success)
    )
    
    static let error = HapticType(
        rawValue: "Error",
        category: .notificationFeedback(.error)
    )
    
    static let warning = HapticType(
        rawValue: "Warning",
        category: .notificationFeedback(.warning)
    )
    
    static let selectionChanged = HapticType(
        rawValue: "Selection Feedback",
        category: .selectionFeedback
    )
    
    static var allCases: [HapticType] {
        [
            light,
            medium,
            heavy,
            soft,
            rigid,
            success,
            warning,
            error,
            selectionChanged
        ]
    }
}
