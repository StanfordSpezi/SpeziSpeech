//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Observation
import os
import Speech
import Spezi


/// Initiate and manage speech recognition.
///
/// The Spezi `SpeechRecognizer` encapsulates the functionality of Apple's `Speech` framework, more specifically, the `SFSpeechRecognizer`.
/// It provides methods to start and stop voice recognition and publishes the state of recognition and its availability.
///
/// > Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.
///
/// The module needs to be registered in a Spezi-based application using the [`configuration`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate/configuration)
/// in a [`SpeziAppDelegate`](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/speziappdelegate):
/// ```swift
/// class ExampleAppDelegate: SpeziAppDelegate {
///     override var configuration: Configuration {
///         Configuration {
///             SpeechRecognizer()
///             // ...
///         }
///     }
/// }
/// ```
/// > Tip: You can learn more about a [`Module` in the Spezi documentation](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/module).
///
/// ## Usage
///
/// ```swift
/// struct SpeechRecognizerView: View {
///     // Get the `SpeechRecognizer` from the SwiftUI `Environment`.
///     @Environment(SpeechRecognizer.self) private var speechRecognizer
///     // The transcribed message from the user's voice input.
///     @State private var message = ""
///
///     var body: some View {
///         VStack {
///             Button("Record") {
///                 microphoneButtonPressed()
///             }
///                 .padding(.bottom)
///
///             Text(message)
///         }
///
///     }
///
///     private func microphoneButtonPressed() {
///         if speechRecognizer.isRecording {
///            // If speech is currently recognized, stop the transcribing.
///            speechRecognizer.stop()
///         } else {
///            // If the recognizer is idle, start a new recording.
///            Task {
///               do {
///                  // The `speechRecognizer.start()` function returns an `AsyncThrowingStream` that yields the transcribed text.
///                  for try await result in speechRecognizer.start() {
///                      // Access the string-based result of the transcribed result
///                      message = result.bestTranscription.formattedString
///                  }
///             }
///         }
///     }
/// }
/// ```
@Observable
public class SpeechRecognizer: NSObject, Module, DefaultInitializable, EnvironmentAccessible, SFSpeechRecognizerDelegate {
    private static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziSpeech")
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine: AVAudioEngine?
    
    /// Indicates whether the speech recognition is currently in progress.
    public private(set) var isRecording = false
    /// Indicates the availability of the speech recognition service.
    public private(set) var isAvailable: Bool
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    
    /// Initializes a new instance of `SpeechRecognizer`.
    override public required convenience init() {
        self.init(locale: .current)
    }
    
    /// Initializes a new instance of `SpeechRecognizer`.
    ///
    /// - Parameter locale: The locale for the speech recognition. Defaults to the current locale.
    public init(locale: Locale = .current) {
        if let speechRecognizer = SFSpeechRecognizer(locale: locale) {
            self.speechRecognizer = speechRecognizer
            self.isAvailable = speechRecognizer.isAvailable
        } else {
            self.speechRecognizer = nil
            self.isAvailable = false
        }
        
        self.audioEngine = AVAudioEngine()
        
        super.init()
        
        speechRecognizer?.delegate = self
    }
    
    
    /// Starts the speech recognition process.
    ///
    /// - Returns: An asynchronous stream that yields the speech recognition results.
    public func start() -> AsyncThrowingStream<SFSpeechRecognitionResult, Error> { // swiftlint:disable:this function_body_length
        AsyncThrowingStream { continuation in // swiftlint:disable:this closure_body_length
            guard !isRecording else {
                SpeechRecognizer.logger.warning(
                    "You already having a recording session in progress, please cancel the first one using `stop` before starting a new session."
                )
                stop()
                continuation.finish()
                return
            }
            
            guard isAvailable, let audioEngine, let speechRecognizer else {
                SpeechRecognizer.logger.error("The SpeechRecognizer is not available.")
                stop()
                continuation.finish()
                return
            }
            
            #if !os(macOS)
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                SpeechRecognizer.logger.error("Error setting up the audio session: \(error.localizedDescription)")
                stop()
                continuation.finish(throwing: error)
            }
            #endif
            
            let inputNode = audioEngine.inputNode
            
            let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest.shouldReportPartialResults = true
            self.recognitionRequest = recognitionRequest
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let error {
                    continuation.finish(throwing: error)
                }
                
                guard self.isRecording, let result else {
                    self.stop()
                    return
                }
                
                continuation.yield(result)
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            do {
                isRecording = true
                try audioEngine.start()
            } catch {
                SpeechRecognizer.logger.error("Error setting up the audio session: \(error.localizedDescription)")
                stop()
                continuation.finish(throwing: error)
            }
            
            continuation.onTermination = { @Sendable _ in
                self.stop()
            }
        }
    }
    
    /// Stops the current speech recognition session.
    public func stop() {
        guard isAvailable && isRecording else {
            return
        }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
    
    @_documentation(visibility: internal)
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        guard self.speechRecognizer == speechRecognizer else {
            return
        }
        
        self.isAvailable = available
    }
}
