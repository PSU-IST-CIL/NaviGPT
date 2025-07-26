//
//  LiDARCameraViewController.swift
//  NaviGPT
//
//  Created by Albert He ZHANG on 9/24/24.
//

import UIKit
import AVFoundation
import CoreHaptics

class LiDARCameraViewController: UIViewController, AVCaptureDepthDataOutputDelegate {
    var captureSession: AVCaptureSession?
    var isCameraActive: Bool = true {
        didSet {
            if isCameraActive {
                startSession()
            } else {
                stopSession()
            }
        }
    }

    var hapticEngine: CHHapticEngine?
    var photoOutput: AVCapturePhotoOutput?
    var delegate: AVCapturePhotoCaptureDelegate?
    var strongDelegate: LiDARCameraView.Coordinator?
    var llmManager: LLmManager?
    var userLocation: String?
    var mapsManager: MapsManager?
    var lastHapticTime: TimeInterval = 0
    var focusView: UIView?
    var captureButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSession()
        setupPreview()
        if isCameraActive {
            startSession()
        }
        setupCaptureButton()
        setupHaptics()
        setupFocusView()
    }

    func setupSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        guard let device = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else {
            print("LiDAR camera not available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            let videoOutput = AVCaptureVideoDataOutput()
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            let depthOutput = AVCaptureDepthDataOutput()
            if captureSession.canAddOutput(depthOutput) {
                captureSession.addOutput(depthOutput)
                depthOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthQueue"))
            }

            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            } else {
                print("Failed to add photo output to capture session")
            }

        } catch {
            print("Error setting up session: \(error)")
        }
    }

    func setupPreview() {
        guard let captureSession = captureSession else { return }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    func setupFocusView() {
        let size: CGFloat = 100
        let focusView = UIView(frame: CGRect(x: (view.bounds.width - size) / 2, y: (view.bounds.height - size) / 4, width: size, height: size))
        focusView.layer.borderColor = UIColor.yellow.cgColor
        focusView.layer.borderWidth = 2.0
        focusView.backgroundColor = UIColor.clear
        self.focusView = focusView
        view.addSubview(focusView)
    }

    func startSession() {
        captureSession?.startRunning()
    }

    func stopSession() {
        captureSession?.stopRunning()
    }

    func setupHaptics() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    func playHaptic() {
        guard let hapticEngine = hapticEngine else { return }
        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
            ], parameters: [])

            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }

    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        // 将深度数据转换为 32 位浮点格式
        let depthDataType = kCVPixelFormatType_DepthFloat32
        let convertedDepthData = depthData.converting(toDepthDataType: depthDataType)
        let depthDataMap = convertedDepthData.depthDataMap

        CVPixelBufferLockBaseAddress(depthDataMap, .readOnly)

        let width = CVPixelBufferGetWidth(depthDataMap)
        let height = CVPixelBufferGetHeight(depthDataMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthDataMap)
        guard let dataPtr = CVPixelBufferGetBaseAddress(depthDataMap) else {
            CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
            return
        }

        let floatRowBytes = bytesPerRow / MemoryLayout<Float32>.size
        let totalElements = floatRowBytes * height
        let floatBuffer = dataPtr.bindMemory(to: Float32.self, capacity: totalElements)

        var minDistance: Float = Float.greatestFiniteMagnitude

        let centerX = width / 4
        let centerY = height / 2
        let regionSize = 20  // 中心区域的大小

        for y in max(0, centerY - regionSize)...min(height - 1, centerY + regionSize) {
            for x in max(0, centerX - regionSize)...min(width - 1, centerX + regionSize) {
                let index = Int(y * floatRowBytes + x)
                let distance = floatBuffer[index]
                if distance < minDistance && distance > 0 {
                    minDistance = distance
                }
            }
        }

        CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)

        // 根据距离计算振动间隔时间
        let minInterval: TimeInterval = 0.2  // 最短振动间隔（0.2 秒）
        let maxInterval: TimeInterval = 3.0  // 最长振动间隔（3 秒）
        let minDistanceThreshold: Float = 0.3  // 最小距离阈值（米）
        let maxDistanceThreshold: Float = 10.0  // 最大距离阈值（米）

        var interval: TimeInterval

        if minDistance <= minDistanceThreshold {
            interval = minInterval
        } else if minDistance >= maxDistanceThreshold {
            interval = maxInterval
        } else {
            // 线性插值计算振动间隔时间
            let ratio = (Double(minDistance) - Double(minDistanceThreshold)) / (Double(maxDistanceThreshold) - Double(minDistanceThreshold))
            interval = minInterval + ratio * (maxInterval - minInterval)
        }

        let currentTime = Date().timeIntervalSince1970

        // 判断是否需要触发振动
        if currentTime - lastHapticTime >= interval {
            lastHapticTime = currentTime
            DispatchQueue.main.async {
                self.playHaptic()
            }
        }
    }

    func setupCaptureButton() {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: (view.bounds.width - 70) / 2, y: view.bounds.height - 100, width: 70, height: 70)
        button.layer.cornerRadius = 35
        button.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        button.setImage(UIImage(systemName: "camera"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(button)
        self.captureButton = button
    }

    @objc func capturePhoto() {
        guard let photoOutput = photoOutput else {
            print("Photo output is not available")
            return
        }

        let settings = AVCapturePhotoSettings()
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            photoOutputConnection.videoOrientation = .portrait
        }
        photoOutput.capturePhoto(with: settings, delegate: strongDelegate!)
    }}
