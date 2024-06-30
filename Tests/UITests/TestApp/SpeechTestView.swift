//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Speech
import SpeziSpeechRecognizer
import SpeziSpeechSynthesizer
import SwiftUI


@MainActor
struct SpeechTestView: View {
    @Environment(SpeechRecognizer.self) private var speechRecognizer
    @Environment(SpeechSynthesizer.self) private var speechSynthesizer
    @State private var selectedVoiceIndex = 0
    @State private var message = ""
    
    
    var body: some View {
        VStack {
            Text("SpeziSpeech")
            
            ScrollView {
                Text(message)
                    .padding()
            }
                .frame(
                    width: 350,
                    height: 200
                )
                .border(.gray)
                .padding(.horizontal)
                .padding(.bottom)
            
            if speechRecognizer.isAvailable {
                microphoneButton
                    .padding()
            }
            
            if !message.isEmpty && !speechRecognizer.isRecording {
                playbackButton
                    .padding()
            }
            
            Picker("Voice", selection: $selectedVoiceIndex) {
                ForEach(speechSynthesizer.voices.indices, id: \.self) { index in
                    Text(speechSynthesizer.voices[index].name)
                        .tag(index)
                }
            }
                .pickerStyle(.inline)
                .accessibilityIdentifier("voicePicker")
                .padding()
        }
    }
    
    private var microphoneButton: some View {
        Button(
            action: {
                microphoneButtonPressed()
            },
            label: {
                Image(systemName: "mic.fill")
                    .accessibilityLabel(Text("Microphone Button"))
                    .font(.largeTitle)
                    .foregroundColor(
                        speechRecognizer.isRecording ? .red : .gray
                    )
                    .scaleEffect(speechRecognizer.isRecording ? 1.2 : 1.0)
                    .opacity(speechRecognizer.isRecording ? 0.7 : 1.0)
                    .animation(
                        speechRecognizer.isRecording ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                        value: speechRecognizer.isRecording
                    )
            }
        )
    }
    
    private var playbackButton: some View {
        Button(
            action: {
                playbackButtonPressed()
            },
            label: {
                Image(systemName: "play.fill")
                    .accessibilityLabel(Text("Playback Button"))
                    .font(.largeTitle)
                    .foregroundColor(
                        speechSynthesizer.isSpeaking ? .blue : .gray
                    )
                    .scaleEffect(speechSynthesizer.isSpeaking ? 1.2 : 1.0)
                    .opacity(speechSynthesizer.isSpeaking ? 0.7 : 1.0)
                    .animation(
                        speechSynthesizer.isSpeaking ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                        value: speechSynthesizer.isSpeaking
                    )
            }
        )
    }
    
    
    private func microphoneButtonPressed() {
        if speechRecognizer.isRecording {
            speechRecognizer.stop()
        } else {
            message = ""
            
            Task {
                do {
                    for try await result in speechRecognizer.start() {
                        message = result.bestTranscription.formattedString
                    }
                }
            }
        }
    }
    
    private func playbackButtonPressed() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pause()
        } else {
            let voice = speechSynthesizer.voices[selectedVoiceIndex]
            speechSynthesizer.speak(message, voice: voice)
        }
    }
}


#Preview {
    SpeechTestView()
}


extension SFSpeechRecognitionResult: @unchecked Sendable {}
