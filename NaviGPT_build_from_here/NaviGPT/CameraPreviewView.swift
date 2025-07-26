//
//  CameraPreviewView.swift
//  NaviGPT
//
//  Created by Albert He ZHANG on 9/24/24.
//

import Foundation
import UIKit
import AVFoundation

class CameraPreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    func setupPreview(session: AVCaptureSession) {
        previewLayer = self.layer as? AVCaptureVideoPreviewLayer
        previewLayer?.session = session
        previewLayer?.videoGravity = .resizeAspectFill
    }
}
