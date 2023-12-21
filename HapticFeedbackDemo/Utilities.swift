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

extension Optional {
    enum UnwrapError: Error {
        case nilValue
    }

    func unwrapOrThrow(_ error: Error) throws -> Wrapped {
        guard let value = self else {
            throw error
        }
        return value
    }

    func unwrapOrThrow() throws -> Wrapped {
        return try unwrapOrThrow(UnwrapError.nilValue)
    }
}


func map<A, B>(
    _ f: @escaping (A) -> B
) ->([A]) -> [B] {    
    { $0.map(f) }
}

extension ScrollViewProxy: @unchecked Sendable {}
