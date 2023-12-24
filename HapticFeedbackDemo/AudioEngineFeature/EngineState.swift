//
//  EngineState.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/24/23.
//

import Foundation

enum EngineState<P>: Equatable {
    case initialized(HapticEngine<P>, State)
    case uninitialized

    enum State: Equatable {
        case created
        case started
        case reset
        case stopped(StoppedReason)
    }
}
