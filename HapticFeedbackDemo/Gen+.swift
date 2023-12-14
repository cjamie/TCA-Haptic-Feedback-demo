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

let eventParameter: Gen<HapticEvent.EventParameter.ParameterID> = Gen
    .element(of: HapticEvent.EventParameter.ParameterID.allCases)
    .map { $0 ?? .attackTime }
    
let valueGen: Gen<Float> = .float(in: 0...1)
let valueGen2: Gen<Float> = .float(in: 1...2)
let uuidGen = Gen { _ in UUID() }

let eventParam: Gen<HapticEvent.EventParameter> = zip(uuidGen, eventParameter, valueGen)
    .map(HapticEvent.EventParameter.init(id:parameterID:value:))

let arrayOfEventParams: Gen<[HapticEvent.EventParameter]> = eventParam
    .set(ofAtMost: .always(5))
    .map(Array.init)

let alwaysZero: Gen<TimeInterval> = .always(0)
let duration: Gen<TimeInterval> = .double(in: 0.5...4)

let hapticEventGen = zip(
    uuidGen,
    eventType,
    arrayOfEventParams,
    alwaysZero,
    duration
).map(HapticEvent.init(id:eventType:parameters:relativeTime:duration:))
