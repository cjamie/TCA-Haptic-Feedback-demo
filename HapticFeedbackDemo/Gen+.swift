//
//  Gen+.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import Gen
import Foundation

let hapticEventType: Gen<HapticEvent.EventType> = Gen
    .element(of: HapticEvent.EventType.hapticCases)
    .map { $0! }

let hapticEventParameterWithRange = Gen
    .element(of: HapticEvent.EventParameter.ParameterID.hapticCasesWithRanges)
    .map { $0! }
    
let valueGen: Gen<Float> = .float(in: 0...1)
let uuidGen = Gen { _ in UUID() }

let hapticEventParam: Gen<HapticEvent.EventParameter> = hapticEventParameterWithRange
    .flatMap { parameterID, range in
        zip(
            uuidGen,
            .always(parameterID),
            .float(in: range),
            .always(range)
        )
    }
    .map(HapticEvent.EventParameter.init(id:parameterID:value:range:))

let arrayOfEventParams: Gen<[HapticEvent.EventParameter]> = hapticEventParam
    .array(of: .always(5))

let alwaysZero: Gen<TimeInterval> = .always(0)
let duration: Gen<TimeInterval> = .double(in: 0.5...10)

let vanillaHapticEventGen = zip(
    uuidGen,
    hapticEventType,
    arrayOfEventParams,
    alwaysZero,
    duration
).map(HapticEvent.init(id:eventType:parameters:relativeTime:duration:))

// TODO: - make a generator of audio... 
