//
//  BasicHaptic.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import Foundation

struct BasicHaptic: Hashable {
    let rawValue: String
    let category: Category
        
    enum Category: Hashable {
        // TODO: - intensity should be embedded inside of feedback. right now, this value does nothing.
        case feedback(FeedbackStyle, intensity: CGFloat? = nil)
        case notificationFeedback(FeedbackType)
        case selectionFeedback
    }
    
    var asNamed: Named<Category> {
        .init(name: rawValue, wrapped: category)
    }
        
    static let light = BasicHaptic(
        rawValue: "Light",
        category: .feedback(.light)
    )
    
    static let medium = BasicHaptic(
        rawValue: "Medium",
        category: .feedback(.medium)
    )
    
    static let heavy = BasicHaptic(
        rawValue: "Heavy",
        category: .feedback(.heavy)
    )
    
    static let soft = BasicHaptic(
        rawValue: "Soft",
        category: .feedback(.soft)
    )
    
    static let rigid = BasicHaptic(
        rawValue: "Rigid",
        category: .feedback(.rigid)
    )
    
    static let success = BasicHaptic(
        rawValue: "Success",
        category: .notificationFeedback(.success)
    )
    
    static let error = BasicHaptic(
        rawValue: "Error",
        category: .notificationFeedback(.error)
    )
    
    static let warning = BasicHaptic(
        rawValue: "Warning",
        category: .notificationFeedback(.warning)
    )
    
    static let selectionChanged = BasicHaptic(
        rawValue: "Selection Feedback",
        category: .selectionFeedback
    )
    
    static let allCases = [
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
