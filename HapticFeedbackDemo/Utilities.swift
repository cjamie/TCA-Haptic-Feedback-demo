//
//  Utilities.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/12/23.
//
import SwiftUI

extension Binding {
    func unwrap<Wrapped>() -> Binding<Wrapped>? where Optional<Wrapped> == Value {
        guard let value = wrappedValue else { return nil }
        return Binding<Wrapped>(
            get: { value },
            set: { wrappedValue = $0 }
        )
    }
}

func zipOptional<T, U>(_ first: T?, _ second: U?) -> (T, U)? {
    guard let firstValue = first, let secondValue = second else {
        return nil
    }
    return (firstValue, secondValue)
}
