//
//  Gen+.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/13/23.
//

import Gen
import Foundation

let eventType: Gen<HapticEvent.EventType> = Gen.element(of: HapticEvent.EventType.allCases)
    .map { $0 ?? .audioContinuous }

let eventParameter: Gen<HapticEvent.EventParameter.ID> = Gen.element(of: HapticEvent.EventParameter.ID.allCases)
    .map { $0 ?? .attackTime }
    

let valueGen: Gen<Float> = .always(1)
let valueGen2: Gen<Float> = .float(in: 1...2)

let eventParam: Gen<HapticEvent.EventParameter> = zip(eventParameter, valueGen)
    .map(HapticEvent.EventParameter.init(parameterID:value:))

let arrayOfEventParams: Gen<[HapticEvent.EventParameter]> = eventParam
    .set(ofAtMost: .always(4))
    .map(Array.init)
//    .array(of: .always(4))

let alwaysZero: Gen<TimeInterval> = .always(0)

let duration: Gen<TimeInterval> = .double(in: 0.5...4)

let hapticEventGen = zip(
    eventType,
    arrayOfEventParams,
    alwaysZero,
    duration
).map(HapticEvent.init(eventType:parameters:relativeTime:duration:))


func zz() {
    
    let dd = eventParam.set(ofAtMost: .always(3)).map(Array.init)
    let vv = Gen.element(of: HapticEvent.EventType.allCases).set(ofAtMost: .always(2))
}
