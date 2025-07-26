import SwiftUI
import AVFoundation
import UIKit

struct CameraManager: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let cameraVC = CameraViewController()
        cameraVC.delegate = context.coordinator
        return cameraVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraManager

        init(_ parent: CameraManager) {
            self.parent = parent
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }

            if let imageData = photo.fileDataRepresentation(),
               let image = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.parent.image = image
                }
            }
        }
    }
}

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var delegate: AVCapturePhotoCaptureDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSession()
        setupPreview()
        startSession()
    }

    func setupSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        guard let device = AVCaptureDevice.default(for: .video) else {
            print("No video device available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

        } catch {
            print("Error setting up camera input: \(error)")
        }
    }

    func setupPreview() {
        guard let captureSession = captureSession else { return }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
    }

    func startSession() {
        captureSession?.startRunning()
    }

    func stopSession() {
        captureSession?.stopRunning()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Capture photo when the user touches the screen
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: delegate!)
    }

    deinit {
        stopSession()
    }
}
