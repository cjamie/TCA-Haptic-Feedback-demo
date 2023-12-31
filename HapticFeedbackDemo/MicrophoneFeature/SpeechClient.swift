//
//  SpeechClient.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/30/23.
//

struct SpeechClient {
    enum AuthorizationStatus {
        case notDetermined
        case denied
        case restricted
        case authorized
    }

    let requestAuthorization: () async -> AuthorizationStatus
    let start: () -> AsyncThrowingStream<String, Error>
    let stop: () async -> Void

    static let mock: SpeechClient = {
        var asyncTask: Task<Void, Error>?
        
        return SpeechClient(
            requestAuthorization: { .authorized },
            start: {
                AsyncThrowingStream { continuation in
                    asyncTask = Task { @MainActor in
                        var finalText = """
                      Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor \
                      incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud \
                      exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute \
                      irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla \
                      pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui \
                      officia deserunt mollit anim id est laborum.
                      """
                        var text = ""
                        while true {
                            let word = finalText.prefix { $0 != " " }
                            try await Task.sleep(for: .milliseconds(word.count * 50 + .random(in: 0...200)))
                            finalText.removeFirst(word.count)
                            if finalText.first == " " {
                                finalText.removeFirst()
                            }
                            text += word + " "
                            continuation.yield(text)
                        }
                    }
                }
            },
            stop: {
                asyncTask?.cancel()
                asyncTask = nil
            }
        )
    }()
}
