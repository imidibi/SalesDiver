//
//  Speechmanager.swift
//  SalesDiver
//
//  Created by Ian Miller on 4/13/25.
//
import Foundation
import Speech
import AVFoundation
import Combine

class SpeechManager: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var isTranscribingAvailable: Bool = false

    override init() {
        super.init()
        requestAuthorization()
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized.")
                DispatchQueue.main.async {
                    self.isTranscribingAvailable = true
                }
            default:
                print("Speech recognition not authorized.")
                DispatchQueue.main.async {
                    self.isTranscribingAvailable = false
                }
            }
        }
    }

    func startTranscribing() throws {
        guard speechRecognizer?.isAvailable == true else {
            throw NSError(domain: "SpeechRecognizerUnavailable", code: 1, userInfo: nil)
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.stopTranscribing()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    func stopTranscribing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
