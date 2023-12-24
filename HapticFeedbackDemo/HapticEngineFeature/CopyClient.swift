//
//  CopyClient.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/19/23.
//

import UIKit

// TODO: - use sharekit instead
struct CopyClient {
    let copy: (String) -> Void
    
    static let live = Self {
        UIPasteboard.general.string = $0
    }
    
    static let mock = Self { _ in }
}
