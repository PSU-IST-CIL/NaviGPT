//
//  SpeechManager.swift
//  NaviGPT
//
//  Created by Albert He ZHANG on 9/24/24.
//

import Foundation
import AVFoundation

class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ utterance: AVSpeechUtterance, interrupt: Bool = false) {
        if interrupt && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // Optional: Implement delegate methods if you need to manage speech events
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Handle completion if necessary
    }
}
