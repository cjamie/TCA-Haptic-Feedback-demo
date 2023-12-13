//
//  MyFeedbackGenerator.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//

import UIKit

struct MyFeedbackGenerator {
    let prepare: () -> Void
    let run: (_ intensity: CGFloat?) -> Void

    init(
        prepare: @escaping () -> Void,
        run: @escaping (CGFloat?) -> Void
    ) {
        self.prepare = prepare
        self.run = run
    }
}
