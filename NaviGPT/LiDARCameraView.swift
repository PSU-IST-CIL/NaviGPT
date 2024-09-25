import SwiftUI
import AVFoundation
import CoreHaptics
import UIKit


struct LiDARCameraView: UIViewControllerRepresentable {
    @Binding var isCameraActive: Bool
    @Binding var capturedImage: UIImage?
    @Binding var shouldCapturePhoto: Bool  // Add this line
    let llmManager: LLmManager
    @Binding var userLocation: String?
    let mapsManager: MapsManager
    let speechSynthesizer = AVSpeechSynthesizer()


    func makeUIViewController(context: Context) -> LiDARCameraViewController {
        let controller = LiDARCameraViewController()
        controller.isCameraActive = isCameraActive
        controller.delegate = context.coordinator
        controller.strongDelegate = context.coordinator
        controller.llmManager = llmManager
        controller.userLocation = userLocation
        controller.mapsManager = mapsManager
        return controller
    }

    func updateUIViewController(_ uiViewController: LiDARCameraViewController, context: Context) {
        uiViewController.isCameraActive = isCameraActive

        if shouldCapturePhoto {
            uiViewController.capturePhoto()
            DispatchQueue.main.async {
                self.shouldCapturePhoto = false  // Reset the flag
            }
        }
    }


    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: LiDARCameraView

        init(_ parent: LiDARCameraView) {
            self.parent = parent
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
                    print("Delegate method called")
                    if let error = error {
                        print("Error capturing photo: \(error)")
                        return
                    }

                    if let imageData = photo.fileDataRepresentation(),
                       let image = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            self.parent.capturedImage = image
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

                            // Call the processImageAndLocation method
                            if let location = self.parent.userLocation {
                                self.parent.processImageAndLocation(image: image, location: location)
                            } else {
                                print("User location is nil")
                            }
                        }
                    }
                }
    }

    func processImageAndLocation(image: UIImage, location: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let base64Image = imageData.base64EncodedString()

        let stepInstruction = mapsManager.getCurrentStepInstruction() ?? "Unable to get navigation instructions"

        let utterance = AVSpeechUtterance(string: "Image has been captured.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en")
        DispatchQueue.main.async {
            SpeechManager.shared.speak(utterance)
        }

        if stepInstruction == "Unable to get navigation instructions" {
            DispatchQueue.global().async {
                self.llmManager.imageGuide(base64Image: base64Image, location: location) { description in
                    guard let description = description else { return }
                    let utterance = AVSpeechUtterance(string: description)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en")
                    DispatchQueue.main.async {
                        SpeechManager.shared.speak(utterance)
                    }
                }
            }
        } else {
            DispatchQueue.global().async {
                self.llmManager.mapGuide(
                    base64Image: base64Image,
                    location: location,
                    destination: self.mapsManager.oldDestination,
                    stepInstruction: stepInstruction,
                    secondStepInstruction: ""
                ) { description in
                    guard let description = description else { return }
                    let utterance = AVSpeechUtterance(string: description)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en")
                    DispatchQueue.main.async {
                        SpeechManager.shared.speak(utterance)
                    }
                }
            }
        }
    }


    private func speakDescription(_ description: String?) {
        guard let description = description else { return }
        let utterance = AVSpeechUtterance(string: description)
        DispatchQueue.main.async {
            AVSpeechSynthesizer().speak(utterance)
        }
    }
}
