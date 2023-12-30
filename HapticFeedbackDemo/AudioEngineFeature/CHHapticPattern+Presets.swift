//
//  CHHapticPattern+Presets.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/21/23.
//


import CoreHaptics

// for cases where its not driven by just event, and params (like when we have file).. we just need something that can convert over to HapticPattern
struct Loader<T> {
    let load: () throws -> T
    
    func callAsFunction() throws -> T {
        try load()
    }
}

func tryMakePattern(_ filename: String) throws -> CHHapticPattern {
    let url = try Bundle.main.url(forResource: filename, withExtension: "ahap").unwrapOrThrow()
    let data = try Data(contentsOf: url, options: [])
    let dictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? [CHHapticPattern.Key: Any])
        .unwrapOrThrow()
    return try CHHapticPattern(dictionary: dictionary)
}

func makePattern(_ filename: String) -> CHHapticPattern? {
    try? Bundle.main
        .url(forResource: filename, withExtension: "ahap")
        .flatMap {
            try JSONSerialization.jsonObject(
                with: Data(contentsOf: $0, options: []),
                options: []
            ) as? [CHHapticPattern.Key: Any]
        }
        .map(CHHapticPattern.init(dictionary:))
}
