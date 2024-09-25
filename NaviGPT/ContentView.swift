import SwiftUI
import UIKit
import AVFoundation
import CoreLocation
import MapKit
import Photos

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center.latitude == rhs.center.latitude &&
        lhs.center.longitude == rhs.center.longitude &&
        lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
        lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}

struct ContentView: View {
    @State private var isCameraActive = true
    @State private var userLocation: String?
    @State private var searchQuery = ""  // User input for destination address
    @StateObject private var mapsManager = MapsManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var capturedImage: UIImage?
    @State private var shouldCapturePhoto = false

    let speechVoice = AVSpeechSynthesizer()
    let llmManager = LLmManager()

    var body: some View {
        VStack {
            // Add TextField for address input
            HStack {
                TextField("Enter destination address", text: $searchQuery, onCommit: {
                    // Trigger navigation when the user presses return
                    mapsManager.getDirections(to: searchQuery)
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                Button(action: {
                    mapsManager.getDirections(to: searchQuery)
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding()
                }
            }

            MapsView(userLocation: $userLocation, searchQuery: $searchQuery, mapsManager: mapsManager)
                .frame(height: UIScreen.main.bounds.height / 5)

            LiDARCameraView(
                isCameraActive: $isCameraActive,
                capturedImage: $capturedImage,
                shouldCapturePhoto: $shouldCapturePhoto,
                llmManager: llmManager,
                userLocation: $userLocation,
                mapsManager: mapsManager
            )
            .frame(height: UIScreen.main.bounds.height / 2)

            HStack {
                Button(action: {
                    shouldCapturePhoto = true
                }) {
                    Image(systemName: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .font(.largeTitle)
                }

                Button(action: {
                    speechRecognizer.startTranscribing()
                }) {
                    Image(systemName: "mic")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(speechRecognizer.isRecording ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .font(.largeTitle)
                }
            }
            .frame(height: UIScreen.main.bounds.height / 10)
        }
        .onAppear {
            mapsManager.requestLocation()
            DispatchQueue.main.async {
                speechRecognizer.mapsManager = mapsManager
            }
        }
    }
}
