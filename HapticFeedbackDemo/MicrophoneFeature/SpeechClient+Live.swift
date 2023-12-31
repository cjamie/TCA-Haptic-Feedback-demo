//
//  SpeechClient+Live.swift
//  HapticFeedbackDemo
//
//  Created by Jamie Chu on 12/30/23.
//

import Speech
import Combine

extension SpeechClient {
    static let live: SpeechClient = {
        let audioSession = AVAudioSession.sharedInstance()
        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!

        var _request: SFSpeechAudioBufferRecognitionRequest?
        
        return SpeechClient(
            requestAuthorization: {
                await withUnsafeContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { authStatus in
                        continuation.resume(with: .success(AuthorizationStatus.init(authStatus)))
                    }
                }
            },
            start: {
                AsyncThrowingStream { continuation in
                    do {
                      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    } catch {
                      continuation.finish(throwing: error)
                      return
                    }
                    
                    let request = SFSpeechAudioBufferRecognitionRequest()

                    _request = request

                    let recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                      switch (result, error) {
                      case let (.some(result), _):
                        continuation.yield(result.bestTranscription.formattedString)
                      case (_, .some):
                        continuation.finish(throwing: error)
                      case (.none, .none):
                        fatalError("It should not be possible to have both a nil result and nil error.")
                      }
                    }
                    
                    continuation.onTermination = { _ in
                      audioEngine.stop()
                      inputNode.removeTap(onBus: 0)
                      recognitionTask.finish()
                    }
                    
                    inputNode.installTap(
                      onBus: 0,
                      bufferSize: 1024,
                      format: inputNode.outputFormat(forBus: 0)
                    ) { buffer, _ in
                      request.append(buffer)
                    }
                    
                    audioEngine.prepare()

                    do {
                      try audioEngine.start()
                    } catch {
                      continuation.finish(throwing: error)
                    }
                }
            },
            stop: {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                _request?.endAudio()
                _request = nil
            }
        )
    }()
}

extension SpeechClient.AuthorizationStatus {
    init(_ status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        case .authorized:
            self = .authorized
        @unknown default:
            self = .notDetermined
        }
    }
}
