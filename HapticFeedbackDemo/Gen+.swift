//
//  Gen+.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import Gen
import Foundation

let eventType: Gen<HapticEvent.EventType> = Gen
    .element(of: HapticEvent.EventType.allCases)
    .map { $0 ?? .audioContinuous }

let eventParameter = Gen
    .element(of: HapticEvent.EventParameter.ParameterID.allCasesWithRanges)
    .map { $0! }
    
let valueGen: Gen<Float> = .float(in: 0...1)
let uuidGen = Gen { _ in UUID() }

let eventParam: Gen<HapticEvent.EventParameter> = eventParameter
    .flatMap { parameterID, range in
        zip(
            uuidGen,
            .always(parameterID),
            .float(in: range),
            .always(range)
        )
    }
    .map(HapticEvent.EventParameter.init(id:parameterID:value:range:))

let arrayOfEventParams: Gen<[HapticEvent.EventParameter]> = eventParam
    .array(of: .always(5))
//    .set(ofAtMost: .always(5))
//    .map(Array.init)

let alwaysZero: Gen<TimeInterval> = .always(0)
let duration: Gen<TimeInterval> = .double(in: 0.5...10)

let hapticEventGen = zip(
    uuidGen,
    eventType,
    arrayOfEventParams,
    alwaysZero,
    duration
).map(HapticEvent.init(id:eventType:parameters:relativeTime:duration:))
