import AVFoundation
import Speech
import SwiftUI
import Foundation
import AudioToolbox

class SpeechRecognizer: ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Timer?
    var mapsManager: MapsManager?

    func startTranscribing() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.startRecording()
                default:
                    print("Speech recognition authorization denied")
                    let utterance = AVSpeechUtterance(string: "Please enable voice recognition permission in the settings.")
                    let speechVoice = AVSpeechSynthesizer()
                    speechVoice.speak(utterance)
                }
            }
        }
    }

    private func startRecording() {
        // 请求麦克风权限
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    self.setupRecording()
                }
            } else {
                DispatchQueue.main.async {
                    print("Microphone permission denied")
                    let utterance = AVSpeechUtterance(string: "Please enable microphone permission in the settings.")
                    let speechVoice = AVSpeechSynthesizer()
                    speechVoice.speak(utterance)
                }
            }
        }
    }

    private func setupRecording() {
        if audioEngine.isRunning {
            stopRecording()
            return
        }

        DispatchQueue.main.async {
            self.isRecording = true
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
        
        AudioServicesPlaySystemSound(1113)

        let inputNode = audioEngine.inputNode
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = request else { return }
        
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                self.resetTimer()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine couldn't start: \(error.localizedDescription)")
        }
        
        self.resetTimer()
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.reset()
        audioEngine.inputNode.removeTap(onBus: 0)
        request = nil
        recognitionTask = nil
        timer?.invalidate()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        AudioServicesPlaySystemSound(1114)
        mapsManager?.getDirections(to: transcribedText)
    }

    private func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.stopRecording()
        }
    }
}
